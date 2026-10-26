#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2020 by Bryan Siepert, written for Adafruit Industries
# SPDX-License-Identifier: Unlicense

import board
import adafruit_scd4x
import rclpy
from rclpy.node import Node
from std_msgs.msg import Float64


class SCD41Publisher(Node):
    def __init__(self):
        super().__init__('scd41')
        self.sensor = adafruit_scd4x.SCD4X(board.I2C())
        self.publishers_by_reading = {
            reading: self.create_publisher(Float64, f'scd41/{reading}', 10)
            for reading in ('co2', 'temperature', 'humidity')
        }
        self.sensor.start_periodic_measurement()
        self.timer = self.create_timer(2.0, self.publish_readings)

    def publish_readings(self):
        # Publish only fresh measurements; the sensor updates slower than this timer.
        if not self.sensor.data_ready:
            return
        readings = {
            'co2': self.sensor.CO2,  # ppm
            'temperature': self.sensor.temperature,  # Celsius
            'humidity': self.sensor.relative_humidity,  # percent
        }
        for reading, value in readings.items():
            self.publishers_by_reading[reading].publish(Float64(data=float(value)))


def main(args=None):
    rclpy.init(args=args)
    node = None
    try:
        node = SCD41Publisher()
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        if node is not None:
            try:
                node.sensor.stop_periodic_measurement()
            finally:
                node.destroy_node()
                if rclpy.ok():
                    rclpy.shutdown()
        elif rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
