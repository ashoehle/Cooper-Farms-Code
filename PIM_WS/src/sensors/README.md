# Sensor publishers

Each program runs one ROS 2 Python node and publishes each numeric reading on
its own `std_msgs/msg/Float64` topic. Topic names are relative so ROS namespaces
and topic remapping work normally. Default topics and units:

| Node | Topic | Units |
| --- | --- | --- |
| bme680 | /bme680/temperature | Celsius (includes the existing -5 degree offset) |
| bme680 | /bme680/gas_resistance | ohms |
| bme680 | /bme680/humidity | percent |
| bme680 | /bme680/pressure | hPa |
| bme680 | /bme680/altitude | meters (sea-level pressure: 1013.25 hPa) |
| scd41 | /scd41/co2 | ppm |
| scd41 | /scd41/temperature | Celsius |
| scd41 | /scd41/humidity | percent |
| sen0469 | /sen0469/concentration | driver-reported units (see /sen0469/gas_units) |
| sen0469 | /sen0469/temperature | Celsius |

SEN0469 also publishes `/sen0469/gas_type` and `/sen0469/gas_units` as
`std_msgs/msg/String` on each measurement. These identify the connected gas probe
and concentration units; the driver reports `ppm` for most gases and `%%` for
oxygen. The BME680 gas reading is resistance, not a gas concentration.

Timers run every second. SCD41 publishes only when a new measurement is ready.
SEN0469 retains I2C bus 1, address `0x74`, passive acquisition, and temperature
compensation. Its `ctype` setting in the source can select UART at 9600 baud.

## Build and run

On the sensor computer, source your ROS 2 installation and ensure the existing
hardware libraries are installed: Adafruit Blinka, `adafruit-circuitpython-bme680`,
`adafruit-circuitpython-scd4x`, and the DFRobot driver's dependencies (`pyserial`,
`smbus`, `spidev`, `RPi.GPIO`). Enable I2C and grant the user access to the devices.
The DFRobot driver is installed alongside the nodes automatically.

From the repository root:

```bash
source /opt/ros/jazzy/setup.bash  # use your installed ROS 2 distribution
cd PIM_WS
colcon build --packages-select sensors
source install/setup.bash
```

Run each node in a separate terminal with ROS 2 and the workspace sourced:

```bash
ros2 run sensors BME680.py
ros2 run sensors SCD41.py
ros2 run sensors SEN0469.py
```

Inspect a single reading:

```bash
ros2 topic echo /scd41/co2
```
