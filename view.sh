#!/usr/bin/env bash
# Open all viewers. Start main.sh or the individual publishers first.
# Each viewer can also run independently using viewcamera.sh, viewlidar.sh,
# or viewsensors.sh. Arguments are forwarded to the LiDAR launch command.
set -eo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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

"$script_dir/viewlidar.sh" "$@" &
children+=("$!")
"$script_dir/viewcamera.sh" &
children+=("$!")
"$script_dir/viewsensors.sh" &
children+=("$!")
# Closing any viewer stops the others; Ctrl+C stops all viewers.
wait -n "${children[@]}"
