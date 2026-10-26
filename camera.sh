#!/usr/bin/env bash
# Start the camera and image subscriber. Stop both with Ctrl+C.
set -eo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
camera_workspace="${CAMERA_WS:-$script_dir/PIM_WS}"
subscriber="$camera_workspace/src/vision/image_subscriber.py"

for setup_file in /opt/ros/jazzy/setup.bash "$camera_workspace/install/setup.bash"; do
  if [[ ! -f "$setup_file" ]]; then
    printf 'Missing setup file: %s\nInstall ROS 2 Jazzy and build the camera workspace first.\n' "$setup_file" >&2
    exit 1
  fi
done

source /opt/ros/jazzy/setup.bash
source "$camera_workspace/install/setup.bash"

if [[ ! -f "$subscriber" ]]; then
  printf 'Missing image subscriber: %s\n' "$subscriber" >&2
  exit 1
fi
/usr/bin/python3 -c 'import rclpy, cv_bridge; from sensor_msgs.msg import Image' || {
  printf 'Missing ROS Python dependencies. Install ros-jazzy-cv-bridge.\n' >&2
  exit 1
}

children=()
cleanup() {
  trap - EXIT INT TERM
  if (( ${#children[@]} )); then
    kill -TERM "${children[@]}" 2>/dev/null || true
    wait "${children[@]}" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

/usr/bin/python3 "$subscriber" --ros-args \
  -p image_topic:="${IMAGE_TOPIC:-/camera/image_raw}" &
children+=("$!")

ros2 run camera_ros camera_node --ros-args \
  -r __node:=camera \
  -p camera:=0 \
  -p width:=640 \
  -p height:=480 \
  "$@" &
children+=("$!")

# If either process exits, the EXIT trap stops the other one.
wait -n "${children[@]}"
