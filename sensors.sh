#!/bin/bash

echo "Starting sensor system..."

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/PIM_WS" || exit 1

if [[ -f "$HOME/ros2_venv/bin/activate" ]]; then
    source "$HOME/ros2_venv/bin/activate" || exit 1
fi
source install/setup.bash || exit 1

pids=()
cleanup() {
    trap - EXIT INT TERM
    echo "Stopping sensor system..."
    if ((${#pids[@]})); then
        kill -TERM "${pids[@]}" 2>/dev/null || true
        wait "${pids[@]}" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Starting SCD41..."
ros2 run sensors SCD41.py &
pids+=("$!")

echo "Starting BME680..."
ros2 run sensors BME680.py &
pids+=("$!")

echo "Starting SEN0469..."
ros2 run sensors SEN0469.py &
pids+=("$!")

# Keep the launcher running; stop the group if any sensor node exits.
wait -n "${pids[@]}"
status=$?
echo "A sensor node exited (status $status)."
exit "$status"
