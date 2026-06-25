#!/usr/bin/env bash
# Toggle fans between MAX speed (for dust-cleaning / hard cooling) and the
# normal automatic curve, via nbfc (NoteBook FanControl, already configured
# for this HP Victus). Needs no sudo — talks to the running nbfc service.

if ! systemctl is-active --quiet nbfc_service; then
    notify-send -u critical "Fan" "nbfc_service is not running"
    exit 1
fi

auto=$(nbfc status 2>/dev/null | grep -m1 'Auto Control Enabled' | grep -o 'true\|false')

if [ "$auto" = "false" ]; then
    # currently manual/max → restore automatic
    nbfc set -a >/dev/null 2>&1
    notify-send -t 2000 -u low "Fan" "󰈐  Auto control restored"
else
    # currently auto → blast to 100%
    nbfc set -s 100 >/dev/null 2>&1
    notify-send -t 4000 -u critical "Fan" "󰈐  MAX speed (cleaning) — press again to restore"
fi

# Refresh the waybar fan-max indicator immediately (signal = 9)
pkill -RTMIN+9 waybar 2>/dev/null || true
