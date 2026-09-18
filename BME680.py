# SPDX-FileCopyrightText: 2021 ladyada for Adafruit Industries
# SPDX-License-Identifier: MIT

import time

import board

import adafruit_bme680

# Create sensor object, communicating over the board's default I2C bus
i2c = board.I2C()  # uses board.SCL and board.SDA
# i2c = board.STEMMA_I2C()  # For using the built-in STEMMA QT connector on a microcontroller
bme680 = adafruit_bme680.Adafruit_BME680_I2C(i2c, debug=False)

# change this to match the location's pressure (hPa) at sea level
bme680.sea_level_pressure = 1013.25

# You will usually have to add an offset to account for the temperature of
# the sensor. This is usually around 5 degrees but varies by use. Use a
# separate temperature sensor to calibrate this one.
temperature_offset = -5

while True:
    print(f"\nTemperature: {bme680.temperature + temperature_offset:0.1f} C")
    print(f"Gas: {bme680.gas:d} ohm")
    print(f"Humidity: {bme680.relative_humidity:0.1f} %")
    print(f"Pressure: {bme680.pressure:0.3f} hPa")
    print(f"Altitude = {bme680.altitude:0.2f} meters")

    time.sleep(1)