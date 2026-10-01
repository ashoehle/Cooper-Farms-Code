# SPDX-FileCopyrightText: 2020 by Bryan Siepert, written for Adafruit Industries
# SPDX-License-Identifier: Unlicense
import time
import board
import adafruit_scd4x

i2c = board.I2C()  # uses board.SCL and board.SDA
# i2c = board.STEMMA_I2C()  # For using the built-in STEMMA QT connector on a microcontroller
scd4x = adafruit_scd4x.SCD4X(i2c)
print("Serial number:", [hex(i) for i in scd4x.serial_number])

scd4x.start_periodic_measurement()
print("Waiting for first measurement....")

def get_scd4x_data():
    """Return a fresh reading, or an empty dict while a measurement is pending."""
    if not scd4x.data_ready:
        return {}
    return {
        "SCD4X CO2": scd4x.CO2,
        "SCD4X Temperature": scd4x.temperature,
        "SCD4X Humidity": scd4x.relative_humidity
    }

if __name__ == "__main__":
    while True:
        if scd4x.data_ready:
            print(f"CO2: {scd4x.CO2:d} ppm")
            print(f"Temperature: {scd4x.temperature:0.1f} *C")
            print(f"Humidity: {scd4x.relative_humidity:0.1f} %")
            print()
        time.sleep(1)
