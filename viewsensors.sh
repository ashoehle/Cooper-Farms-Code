#!/usr/bin/env bash
# Open one plot per environmental sensor topic. Start sensors.sh or main.sh first.
# Optional: PLOT_Y_PADDING=0.20 ./viewsensors.sh  # default 10% margin
set -eo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
viewer_workspace="${PIM_WS:-$script_dir/PIM_WS}"
for setup_file in /opt/ros/jazzy/setup.bash "$viewer_workspace/install/setup.bash"; do
  if [[ ! -f "$setup_file" ]]; then
    printf 'Missing setup file: %s\nBuild the ROS 2 workspace first.\n' "$setup_file" >&2
    exit 1
  fi
done
source /opt/ros/jazzy/setup.bash
source "$viewer_workspace/install/setup.bash"

children=()
plot_tmp_dir=""
cleanup() {
  trap - EXIT INT TERM
  if (( ${#children[@]} )); then
    kill -TERM "${children[@]}" 2>/dev/null || true
    wait "${children[@]}" 2>/dev/null || true
  fi
  if [[ -n "$plot_tmp_dir" ]]; then
    rm -rf -- "$plot_tmp_dir"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Generate a fresh RQt perspective. These Float64 topics match the publishers
# in PIM_WS/src/sensors/src/{BME680,SCD41,SEN0469}.py.
plot_tmp_dir=$(mktemp -d)
QT_QPA_PLATFORM=offscreen python3 - "$plot_tmp_dir/sensor_plots.perspective" <<'PY'
import json
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

try:
    from python_qt_binding.QtCore import Qt
    from python_qt_binding.QtWidgets import QApplication, QDockWidget, QMainWindow, QWidget
    from qt_gui.plugin_instance_id import PluginInstanceId
    from rqt_py_common.ini_helper import pack
    from rqt_plot.data_plot import DataPlot
    from ament_index_python.packages import get_package_share_directory
except ImportError as error:
    sys.exit(f'Missing plotting dependency: {error}\n'
             'Install: sudo apt install ros-jazzy-rqt-plot')

backends = [i for i, backend in enumerate(DataPlot.plot_types) if backend['enabled']]
if not backends:
    sys.exit('No plotting backend. Install python3-pyqtgraph or python3-matplotlib.')

topics = [
    '/bme680/temperature',
    '/bme680/humidity',
    '/bme680/gas_resistance',
    '/scd41/temperature',
    '/scd41/humidity',
    '/scd41/co2',
    '/sen0469/temperature',
    '/sen0469/concentration',
]

plot_labels = [
    ('BME680 Temperature', 'Temperature (°F)'),
    ('BME680 Humidity', 'Relative humidity (%)'),
    ('BME680 Gas Resistance', 'Gas resistance (Ω)'),
    ('SCD41 Temperature', 'Temperature (°F)'),
    ('SCD41 Humidity', 'Relative humidity (%)'),
    ('SCD41 CO₂', 'CO₂ (ppm)'),
    ('SEN0469 Temperature', 'Temperature (°F)'),
    ('SEN0469 NH3 Concentration', 'NH3 concentration (ppm)'),
]

def value(item):
    return {'type': 'repr', 'repr': repr(item)}

def group(keys=None, groups=None):
    return {'keys': {key: value(item) for key, item in (keys or {}).items()},
            'groups': groups or {}}

# Let Qt produce a compatible saved layout: four columns of two plots.
app = QApplication([])
window = QMainWindow()
window.setDockNestingEnabled(True)
window.resize(1400, 1000)
# loadUi sets the plot's final object name from the installed .ui file.
# RQt can only restore positions when these names match its actual docks.
plot_ui = Path(get_package_share_directory('rqt_plot')) / 'resource' / 'plot.ui'
plot_widget_name = ET.parse(plot_ui).getroot().find('widget').attrib['name']
instances = {}
docks = []
plugin_id = 'rqt_plot/Plot'
for number, topic in enumerate(topics, start=1):
    instance = PluginInstanceId(plugin_id, number)
    instances['plugin__' + instance.tidy_str()] = group(groups={
        'plugin': group({'topics': pack([topic + '/data']), 'autoscroll': True,
                         'plot_type': backends[0], 'x_limits': pack([0.0, 60.0]),
                         'sensor_title': plot_labels[number - 1][0],
                         'sensor_y_label': plot_labels[number - 1][1]})
    })
    dock = QDockWidget(topic, window)
    dock.setObjectName(instance.tidy_str() + '__' + plot_widget_name)
    dock.setWidget(QWidget())
    window.addDockWidget(Qt.LeftDockWidgetArea, dock)
    index = number - 1
    if 0 < index < 4:
        window.splitDockWidget(docks[index - 1], dock, Qt.Horizontal)
    elif index >= 4:
        window.splitDockWidget(docks[index - 4], dock, Qt.Vertical)
    docks.append(dock)
window.show()
app.processEvents()
window.resizeDocks(docks[:4], [1] * 4, Qt.Horizontal)
for column in (docks[index::4] for index in range(4)):
    window.resizeDocks(column, [1] * len(column), Qt.Vertical)
app.processEvents()
mainwindow = group()
mainwindow['keys']['state'] = {
    'type': 'repr(QByteArray.hex)',
    'repr(QByteArray.hex)': repr(bytes(window.saveState().toHex())),
}
perspective = group(groups={
    'mainwindow': mainwindow,
    'pluginmanager': group({'running-plugins': {plugin_id: list(range(1, len(topics) + 1))}},
                           instances),
})
with open(sys.argv[1], 'w', encoding='utf-8') as stream:
    json.dump(perspective, stream, indent=2)
window.close()
print(f'Opening {len(topics)} sensor plots with a scrolling 60-second view.', flush=True)
PY

# Apply padding only inside this plot viewer; leave the installed RQt unchanged.
cat > "$plot_tmp_dir/padded_rqt.py" <<'PY'
import math
import os
import sys

import numpy as np
from rqt_plot.data_plot import DataPlot
from rqt_gui.main import Main

try:
    padding = float(os.environ.get('PLOT_Y_PADDING', '0.10'))
    if not math.isfinite(padding) or padding < 0:
        raise ValueError()
except ValueError:
    sys.exit('PLOT_Y_PADDING must be a finite nonnegative number, such as 0.10.')

original_autoscale = DataPlot._merged_autoscale

def padded_autoscale(self):
    scroll_limits = None
    if self._autoscroll:
        # RQt resets an empty plot to [0, 1], then reuses that one-second
        # width when data arrives. Enforce the intended window on every redraw.
        self._autoscale_x = False
        latest_times = []
        for curve in self._curves.values():
            finite_times = curve['x'][np.isfinite(curve['x'])]
            if finite_times.size:
                latest_times.append(float(finite_times.max()))
        right = max(latest_times, default=60.0)
        scroll_limits = [right - 60.0, right]
        self.set_xlim(scroll_limits)
    original_autoscale(self)
    if scroll_limits is not None:
        self.set_xlim(scroll_limits)
    if not self._autoscale_y:
        return
    # Recompute from actual visible samples, including the newest endpoint.
    # Using padded axis limits as input would grow the margin every redraw.
    xmin, xmax = self.get_xlim()
    samples = []
    for curve in self._curves.values():
        values = curve['y']
        if self._autoscale_y & DataPlot.SCALE_VISIBLE:
            values = values[(curve['x'] >= xmin) & (curve['x'] <= xmax)]
        finite = values[np.isfinite(values)]
        if finite.size:
            samples.append(finite)
    if not samples:
        return
    low = min(float(values.min()) for values in samples)
    high = max(float(values.max()) for values in samples)
    # A minimum span keeps flat or nearly constant sensor readings readable.
    span = max(high - low, 0.1 * max(abs(low), abs(high)), 1.0)
    margin = padding * span
    if high == low and margin == 0:
        margin = 0.5
    self.set_ylim([low - margin, high + margin])

DataPlot._merged_autoscale = padded_autoscale

# Store labels on DataPlot so switching plotting backends preserves them.
def apply_sensor_labels(self):
    labels = getattr(self, '_sensor_labels', None)
    if labels is None:
        return
    title, y_label = labels
    backend = self._data_plot_widget
    x_label = 'Time (s)'
    if hasattr(backend, '_plot_widget'):  # PyQtGraph
        plot = backend._plot_widget.getPlotItem()
        plot.setTitle(title, color='#222222')
        plot.setLabel('bottom', x_label)
        plot.setLabel('left', y_label)
    elif hasattr(backend, '_canvas'):  # Matplotlib
        canvas = backend._canvas
        canvas.axes.set_title(title)
        canvas.axes.set_xlabel(x_label)
        canvas.axes.set_ylabel(y_label)
        canvas.figure.tight_layout()
        canvas.draw_idle()
    elif hasattr(backend, 'setAxisTitle'):  # Qwt
        backend.setTitle(title)
        backend.setAxisTitle(backend.xBottom, x_label)
        backend.setAxisTitle(backend.yLeft, y_label)
        backend.replot()

original_switch_backend = DataPlot._switch_data_plot_widget

def switch_with_labels(self, plot_index, markers_on=False):
    original_switch_backend(self, plot_index, markers_on)
    apply_sensor_labels(self)

DataPlot._switch_data_plot_widget = switch_with_labels

# RQt does not save the marker checkbox in its perspective. Enable it after
# each panel restores its settings, including curves already subscribed.
original_restore_settings = DataPlot.restore_settings

def restore_with_markers(self, plugin_settings, instance_settings):
    self._sensor_labels = (
        instance_settings.value('sensor_title', 'Sensor Readings'),
        instance_settings.value('sensor_y_label', 'Value'),
    )
    original_restore_settings(self, plugin_settings, instance_settings)
    self._switch_plot_markers(True)

DataPlot.restore_settings = restore_with_markers
if __name__ == '__main__':
    sys.exit(Main().main(['rqt', '--perspective-file', sys.argv[1]]))
PY

python3 "$plot_tmp_dir/padded_rqt.py" "$plot_tmp_dir/sensor_plots.perspective" &
children+=("$!")
wait "${children[0]}"
