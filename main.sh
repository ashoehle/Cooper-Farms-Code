#!/usr/bin/env bash
# Start all publishers and the camera image subscriber. Ctrl+C stops all.
set -eo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
publishers=(camera.sh lidar.sh sensors.sh)
for publisher in "${publishers[@]}"; do
  if [[ ! -f "$script_dir/$publisher" ]]; then
    printf 'Missing publisher script: %s\n' "$script_dir/$publisher" >&2
    exit 1
  fi
done
command -v setsid >/dev/null || {
  printf 'Missing setsid. Install the util-linux package.\n' >&2
  exit 1
}
if [[ ! -f /opt/ros/jazzy/setup.bash ]]; then
  printf 'Missing ROS 2 Jazzy setup: /opt/ros/jazzy/setup.bash\n' >&2
  exit 1
fi
# Provide the ROS environment to sensors.sh as well as the other launchers.
source /opt/ros/jazzy/setup.bash

publisher_groups=()
cleanup() {
  trap - EXIT INT TERM
  printf 'Stopping all publishers...\n'
  # Each launcher has its own process group, including its ROS child nodes.
  for group in "${publisher_groups[@]}"; do
    kill -TERM -- "-$group" 2>/dev/null || true
  done
  if (( ${#publisher_groups[@]} )); then
    wait "${publisher_groups[@]}" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for publisher in "${publishers[@]}"; do
  printf 'Starting %s...\n' "$publisher"
  setsid bash "$script_dir/$publisher" &
  publisher_groups+=("$!")
done

# Stop the remaining publishers if any launcher exits, including on failure.
status=0
wait -n "${publisher_groups[@]}" || status=$?
printf 'A publisher stopped (status %s).\n' "$status"
exit "$status"
