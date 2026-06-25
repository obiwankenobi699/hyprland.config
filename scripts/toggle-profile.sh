#!/usr/bin/env bash
# Toggle the power profile between balanced and performance.
# 'performance' ramps the HP Victus fan curve aggressively for better cooling.
#
# Talks to power-profiles-daemon over D-Bus (busctl) so it needs no extra
# packages and no sudo/polkit password for the active session. The
# `powerprofilesctl` CLI is avoided because it depends on python-gobject (gi).

BUS=org.freedesktop.UPower.PowerProfiles
OBJ=/org/freedesktop/UPower/PowerProfiles
IFACE=org.freedesktop.UPower.PowerProfiles

get() { busctl get-property "$BUS" "$OBJ" "$IFACE" ActiveProfile | awk '{gsub(/"/,"",$2); print $2}'; }
set() { busctl set-property "$BUS" "$OBJ" "$IFACE" ActiveProfile s "$1"; }

if ! busctl get-property "$BUS" "$OBJ" "$IFACE" ActiveProfile >/dev/null 2>&1; then
    notify-send -u critical "Power profile" "power-profiles-daemon not running"
    exit 1
fi

current=$(get)
if [ "$current" = "performance" ]; then
    new=balanced
else
    new=performance
fi

set "$new"
notify-send -t 2000 -u low "Power profile" "Now: ${new^}"

# Refresh the waybar power-profile module immediately (signal = 8)
pkill -RTMIN+8 waybar 2>/dev/null || true
