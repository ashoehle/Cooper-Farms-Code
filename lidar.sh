#!/usr/bin/env bash
# Start the RPLIDAR publisher. Example: ./lidar.sh serial_port:=/dev/ttyUSB1
set -eo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
lidar_workspace="${LIDAR_WS:-$script_dir/PIM_WS}"
for setup_file in /opt/ros/jazzy/setup.bash "$lidar_workspace/install/setup.bash"; do
  if [[ ! -f "$setup_file" ]]; then
    printf 'Missing setup file: %s\nBuild the ROS 2 workspace first.\n' "$setup_file" >&2
    exit 1
  fi
done
source /opt/ros/jazzy/setup.bash
source "$lidar_workspace/install/setup.bash"
exec ros2 launch rplidar_ros rplidar_publisher.py "$@"
