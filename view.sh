#!/usr/bin/env bash
# Open LiDAR RViz and camera rqt. Start lidar.sh and camera.sh separately.
# Optional: IMAGE_TOPIC=/camera/image_raw ./view_sensors.sh
set -eo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
viewer_workspace="${PIM_WS:-$script_dir/PIM_WS}"
for setup_file in /opt/ros/jazzy/setup.bash "$viewer_workspace/install/setup.bash"; do
  if [[ ! -f "$setup_file" ]]; then
    printf 'Missing setup file: %s\nBuild the ROS 2 workspace first.\n' "$setup_file" >&2
    exit 1
  fi
done
source /opt/ros/jazzy/setup.bash
source "$viewer_workspace/install/setup.bash"

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

ros2 launch rplidar_ros rplidar_rviz.py "$@" &
children+=("$!")
ros2 run rqt_image_view rqt_image_view "${IMAGE_TOPIC:-/camera/image_raw}" &
children+=("$!")
# Closing either viewer stops the other; Ctrl+C stops both.
wait -n "${children[@]}"
