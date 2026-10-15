#!/usr/bin/env python3
"""Open RViz for an independently running RPLIDAR A1 publisher."""

from ament_index_python.packages import get_package_share_path
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    config = str(get_package_share_path('rplidar_ros') / 'rviz' / 'rplidar_ros.rviz')
    return LaunchDescription([
        DeclareLaunchArgument('rviz_config', default_value=config),
        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', LaunchConfiguration('rviz_config')],
            output='screen',
        ),
    ])
