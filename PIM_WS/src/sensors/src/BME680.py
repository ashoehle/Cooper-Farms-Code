#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2021 ladyada for Adafruit Industries
# SPDX-License-Identifier: MIT

import board
import adafruit_bme680
import rclpy
from rclpy.node import Node
from std_msgs.msg import Float64


class BME680Publisher(Node):
    def __init__(self):
        super().__init__('bme680')
        self.sensor = adafruit_bme680.Adafruit_BME680_I2C(board.I2C(), debug=False)
        self.sensor.sea_level_pressure = 1013.25
        # Calibrate this offset against a separate temperature sensor.
        self.temperature_offset = -5
        self.publishers_by_reading = {
            reading: self.create_publisher(Float64, f'bme680/{reading}', 10)
            for reading in ('temperature', 'gas_resistance', 'humidity')
        }
        self.timer = self.create_timer(2.0, self.publish_readings)

    def publish_readings(self):
        readings = {
            'temperature': self.sensor.temperature + self.temperature_offset,  # Celsius
            'gas_resistance': self.sensor.gas,  # ohms
            'humidity': self.sensor.relative_humidity,  # percent
        }
        for reading, value in readings.items():
            self.publishers_by_reading[reading].publish(Float64(data=float(value)))


def main(args=None):
    rclpy.init(args=args)
    node = None
    try:
        node = BME680Publisher()
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        if node is not None:
            node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
