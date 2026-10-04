#!/bin/bash

echo "Starting sensor system..."

cd ~/Cooper-Farms_code/PIM_WS

source ~/ros2_venv/bin/activate
source install/setup.bash

echo "Starting SCD41..."
ros2 run sensors SCD41.py

echo "Starting BME680..."
ros2 run sensors BME680.py

echo "Starting SEN0469..."
ros2 run sensors SEN0469.py
