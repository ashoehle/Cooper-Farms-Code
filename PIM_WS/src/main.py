"""Run with python3 PIM_WS/src/main.py on the sensor-connected computer.

Requires matplotlib and the hardware libraries used by the three sensor files.
Close the plot window or press Ctrl+C to stop.
"""

import importlib.util
import logging
from collections import deque
from pathlib import Path
from queue import Empty, Full, Queue
from threading import Event, Thread
from time import monotonic

SAMPLE_INTERVAL = 0.0  # Seconds between collection cycles.
HISTORY_LENGTH = 1200  # Maximum samples retained for each reading.
SRC = Path(__file__).resolve().parent

# Module path, getter, and measurement names/units (matching the saved getters).
SENSORS = [
    ("BME680.py", "get_bme680_data", {
        "BME Temp": "°C", "BME Gas": "ohm", "BME Humidity": "%",
        "BME Pressure": "hPa", "BME Altitude": "m",
    }),
    ("SCD-4X.py", "get_scd4x_data", {
        "SCD4X CO2": "ppm", "SCD4X Temperature": "°C",
        "SCD4X Humidity": "%",
    }),
    ("SEN0469/examples/read_gas_concentration/read_gas_concentration.py",
     "get_SEN0469_data", {"SEN0469 Gas": "sensor units", "SEN0469 Temp": "°C"}),
]


# Group by physical measurement; gas resistance and gas concentrations differ.
PLOT_GROUPS = [
    ("Temperature", "°C", [("BME Temp", "BME680"),
                            ("SEN0469 Temp", "SEN0469")]),
    ("Humidity", "%", [("BME Humidity", "BME680")]),
    ("Pressure", "hPa", [("BME Pressure", "BME680")]),
    ("Altitude", "m", [("BME Altitude", "BME680")]),
    ("Gas resistance", "ohm", [("BME Gas", "BME680")]),
    ("CO2", "ppm", [("SCD4X CO2", "SCD4X")]),
    ("SEN0469 gas concentration", "sensor units", [("SEN0469 Gas", "SEN0469")]),
]
SENSOR_COLORS = {"BME680": "tab:blue", "SCD4X": "tab:orange", "SEN0469": "tab:green"}


def load_sensor(index, filename):
    # Loading by path supports SCD-4X's hyphen and works from any directory.
    spec = importlib.util.spec_from_file_location(f"sensor_{index}", SRC / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def collect_data(samples, stop):
    """Keep all hardware access on one thread, separate from the GUI."""
    modules = {}
    failures = set()
    started = monotonic()
    try:
        while not stop.is_set():
            cycle = monotonic()
            for index, (filename, getter, _) in enumerate(SENSORS):
                if stop.is_set():
                    break
                try:
                    if index not in modules:
                        modules[index] = load_sensor(index, filename)
                    module = modules[index]
                    data = getattr(module, getter)()
                    units = getattr(getattr(module, "gas", None), "gasunits", None)
                    if data:
                        sample = (monotonic() - started, data, units)
                        try:
                            samples.put_nowait(sample)
                        except Full:
                            samples.get_nowait()
                            samples.put_nowait(sample)
                    if index in failures:
                        logging.info("%s recovered", filename)
                        failures.remove(index)
                except Exception as exc:
                    if index not in failures:
                        logging.warning("%s: %s (will retry)", filename, exc)
                        failures.add(index)
            stop.wait(max(0, SAMPLE_INTERVAL - (monotonic() - cycle)))
    finally:
        for module in modules.values():
            sensor = getattr(module, "scd4x", None)
            if sensor is not None:
                try:
                    sensor.stop_periodic_measurement()
                except Exception:
                    logging.exception("Could not stop SCD4X measurement")


def main():
    import matplotlib.pyplot as plt
    from matplotlib.animation import FuncAnimation

    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    samples = Queue(maxsize=100)
    stop = Event()
    fig, axes = plt.subplots(3, 3, figsize=(14, 10), constrained_layout=True)
    fig.suptitle("Live sensor readings — waiting for data")
    plots = {}
    for ax, (title, unit, readings) in zip(axes.flat, PLOT_GROUPS):
        ax.set(title=title, xlabel="Elapsed time (s)", ylabel=unit)
        ax.grid(True, alpha=0.3)
        for name, sensor in readings:
            line, = ax.plot([], [], linewidth=1.5, marker=".", markersize=3,
                            label=sensor, color=SENSOR_COLORS[sensor])
            plots[name] = (ax, line, deque(maxlen=HISTORY_LENGTH), deque(maxlen=HISTORY_LENGTH))
        ax.legend(loc="upper left")
    for ax in list(axes.flat)[len(PLOT_GROUPS):]:
        ax.set_visible(False)

    def update(_frame):
        changed = set()
        while True:
            try:
                timestamp, data, gas_units = samples.get_nowait()
            except Empty:
                break
            for name, value in data.items():
                if name not in plots:
                    continue
                ax, line, times, values = plots[name]
                times.append(timestamp)
                values.append(float(value))
                if name == "SEN0469 Gas" and gas_units:
                    ax.set_ylabel(gas_units)
                changed.add(name)
        changed_axes = set()
        for name in changed:
            ax, line, times, values = plots[name]
            line.set_data(times, values)
            changed_axes.add(ax)
        for ax in changed_axes:
            ax.relim()
            ax.autoscale_view()
        if changed:
            fig.suptitle("Live sensor readings")
        return [plot[1] for plot in plots.values()]

    worker = Thread(target=collect_data, args=(samples, stop), daemon=True)
    fig.canvas.mpl_connect("close_event", lambda _event: stop.set())
    # Retain the animation for the entire lifetime of the window.
    animation = FuncAnimation(fig, update, interval=200, cache_frame_data=False)
    worker.start()
    try:
        plt.show()
    except KeyboardInterrupt:
        plt.close(fig)
    finally:
        stop.set()
        worker.join(timeout=3)


if __name__ == "__main__":
    main()
