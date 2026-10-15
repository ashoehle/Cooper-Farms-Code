# RPLIDAR A1 ROS 2 package

This package publishes RPLIDAR A1 scans on `/scan` using the USB serial
connection (115200 baud). The default scan frame is `laser`. The bundled
Slamtec SDK is retained as the driver dependency; package launches and node
transport support are limited to the A1 serial connection.

## Build

From the repository root, with your ROS 2 environment sourced:

```bash
cd PIM_WS
colcon build --packages-select rplidar_ros --symlink-install
source install/setup.bash
```

## Run the publisher

```bash
ros2 launch rplidar_ros rplidar_publisher.py serial_port:=/dev/ttyUSB0
```

This starts only `rplidar_node`. Optional launch arguments are
`serial_baudrate` (115200), `frame_id` (laser), `inverted` (false),
`angle_compensate` (true), and `scan_mode` (empty, using the device's typical
mode). Ensure your user has permission to access the serial device.

## Open RViz separately

In another terminal, source the same ROS 2 environment and workspace:

```bash
cd PIM_WS
source install/setup.bash
ros2 launch rplidar_ros rplidar_rviz.py
```

This starts only RViz and subscribes to the existing `/scan` publisher.
Closing RViz leaves the publisher running. An optional `rviz_config` argument
selects another configuration. If you change `frame_id`, update RViz's fixed
frame to match. On a separate visualization computer, source a workspace with
this package and use the same ROS domain and network configuration.

The node also provides `start_motor` and `stop_motor` services
(`std_srvs/srv/Empty`). Stop the publisher with Ctrl+C.
