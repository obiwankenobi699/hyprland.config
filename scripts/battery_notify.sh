#!/usr/bin/env bash
# Notify once per low-battery threshold. The systemd timer runs this script
# periodically; state prevents repeated notifications at the same threshold.

set -u

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
state_file="$state_dir/battery-notify-level"
battery_dir=""

for candidate in /sys/class/power_supply/BAT*; do
    if [[ -d "$candidate" ]]; then
        battery_dir="$candidate"
        break
    fi
done

[[ -n "$battery_dir" ]] || exit 0

capacity=$(<"$battery_dir/capacity") || exit 0
status=$(<"$battery_dir/status") || exit 0
[[ "$capacity" =~ ^[0-9]+$ ]] || exit 0

mkdir -p "$state_dir"

if [[ "$status" != "Discharging" ]]; then
    printf '%s\n' ready > "$state_file"
    exit 0
fi

threshold=""
urgency=normal
timeout=10000
case "$capacity" in
    [0-5]) threshold=5; urgency=critical; timeout=0 ;;
    [6-9]|10) threshold=10; urgency=critical ;;
    1[1-9]|20) threshold=20 ;;
    *) printf '%s\n' ready > "$state_file"; exit 0 ;;
esac

last_level=ready
[[ -r "$state_file" ]] && last_level=$(<"$state_file")
[[ "$last_level" == "$threshold" ]] && exit 0

if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -t "$timeout" \
        "Low battery · ${capacity}%" \
        "Connect the charger. This alert will not repeat until the next threshold."
fi
printf '%s\n' "$threshold" > "$state_file"
