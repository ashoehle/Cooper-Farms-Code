#!/usr/bin/env bash
# Open the camera viewer. Start camera.sh or main.sh first.
# Optional: IMAGE_TOPIC=/camera/image_raw ./viewcamera.sh
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


exec ros2 run rqt_image_view rqt_image_view "${IMAGE_TOPIC:-/camera/image_raw}" "$@"
