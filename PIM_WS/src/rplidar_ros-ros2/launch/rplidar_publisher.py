#!/usr/bin/env python3
"""Start only the RPLIDAR A1 LaserScan publisher."""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
    arguments = [
        ('serial_port', '/dev/ttyUSB0', str, 'A1 USB serial device'),
        ('serial_baudrate', '115200', int, 'A1 serial baud rate'),
        ('frame_id', 'laser', str, 'LaserScan frame'),
        ('inverted', 'false', bool, 'Invert scan data'),
        ('angle_compensate', 'true', bool, 'Compensate scan angles'),
        ('scan_mode', '', str, 'Scan mode; empty uses the device typical mode'),
    ]
    return LaunchDescription([
        *[DeclareLaunchArgument(name, default_value=default, description=description)
          for name, default, _, description in arguments],
        Node(
            package='rplidar_ros',
            executable='rplidar_node',
            name='rplidar_node',
            parameters=[{
                name: ParameterValue(LaunchConfiguration(name), value_type=value_type)
                for name, _, value_type, _ in arguments
            }],
            output='screen',
        ),
    ])
