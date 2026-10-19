#!/usr/bin/env bash
# Start the IMX219 camera ROS 2 publisher. Stop with Ctrl+C.
set -eo pipefail

camera_workspace="${CAMERA_WS:-$HOME/Cooper-Farms-Code/PIM_WS}"

for setup_file in /opt/ros/jazzy/setup.bash "$camera_workspace/install/setup.bash"; do
  if [[ ! -f "$setup_file" ]]; then
    printf 'Missing setup file: %s\nInstall ROS 2 Jazzy and build the camera workspace first.\n' "$setup_file" >&2
    exit 1
  fi
done

source /opt/ros/jazzy/setup.bash
source "$camera_workspace/install/setup.bash"

exec ros2 run camera_ros camera_node --ros-args \
  -r __node:=camera \
  -p camera:=0 \
  -p width:=640 \
  -p height:=480 \
  "$@"
