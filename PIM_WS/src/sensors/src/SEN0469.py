#!/usr/bin/env python3
# -*- coding: utf-8 -*
'''
  @file  read_gas_concentration.py
  @brief Obtain gas concentration corresponding to the current environment, output as concentration value
  @n Experimental mode: connect sensor communication pin to the main controller and burn
  @n Experimental phenomenon: view the gas concentration corresponding to the current environment through serial port printing
  @n Communication mode select, DIP switch SEL: 0: I2C, 1: UART
  @n Group serial number         Address in the set
  A0 A1 DIP level    00    01    10    11
  @n 1            0x60  0x61  0x62  0x63
  @n 2            0x64  0x65  0x66  0x67
  @n 3            0x68  0x69  0x6A  0x6B
  @n 4            0x6C  0x6D  0x6E  0x6F
  @n 5            0x70  0x71  0x72  0x73
  @n 6 (Default address group) 0x74  0x75  0x76  0x77 (Default address)
  @n 7            0x78  0x79  0x7A  0x7B
  @n 8            0x7C  0x7D  0x7E  0x7F
  @n I2C address select, default to 0x77, A1 and A0 are grouped into 4 I2C addresses.
  @n             | A0 | A1 |
  @n             | 0  | 0  |    0x74
  @n             | 0  | 1  |    0x75
  @n             | 1  | 0  |    0x76
  @n             | 1  | 1  |    0x77   default i2c address   
  @copyright   Copyright (c) 2010 DFRobot Co.Ltd (http://www.dfrobot.com)
  @license     The MIT License (MIT)
  @author      PengKaixing(kaixing.peng@dfrobot.com)
  @version     V2.0
  @date        2021-03-28
  @url         https://github.com/DFRobot/DFRobot_MultiGasSensor
'''
import time

import rclpy
from rclpy.node import Node
from std_msgs.msg import Float64, String

from DFRobot_MultiGasSensor import (
    DFRobot_MultiGasSensor_I2C,
    DFRobot_MultiGasSensor_UART,
)

# ctype=0: I2C; ctype=1: UART. Preserve the original connection settings.
ctype = 0
I2C_1 = 0x01
I2C_ADDRESS = 0x74


class SEN0469Publisher(Node):
    def __init__(self):
        super().__init__('sen0469')
        if ctype == 0:
            self.sensor = DFRobot_MultiGasSensor_I2C(I2C_1, I2C_ADDRESS)
        else:
            self.sensor = DFRobot_MultiGasSensor_UART(9600)

        while rclpy.ok() and not self.sensor.change_acquire_mode(self.sensor.PASSIVITY):
            self.get_logger().info('Waiting for acquire mode change...')
            time.sleep(1)
        if not rclpy.ok():
            return
        self.sensor.set_temp_compensation(self.sensor.ON)
        time.sleep(1)
        self.concentration_publisher = self.create_publisher(Float64, 'sen0469/concentration', 10)
        self.temperature_publisher = self.create_publisher(Float64, 'sen0469/temperature', 10)
        self.timer = self.create_timer(2.0, self.publish_readings)

    def publish_readings(self):
        # The driver sets gas type, units, and temperature during this read.
        concentration = self.sensor.read_gas_concentration()
        self.concentration_publisher.publish(Float64(data=float(concentration)))
        self.temperature_publisher.publish(Float64(data=float(self.sensor.temp)))
        self.gas_type_publisher.publish(String(data=self.sensor.gastype))
        self.gas_units_publisher.publish(String(data=self.sensor.gasunits))


def main(args=None):
    rclpy.init(args=args)
    node = None
    try:
        node = SEN0469Publisher()
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
