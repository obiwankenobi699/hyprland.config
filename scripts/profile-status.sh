#!/usr/bin/env bash
# Emits waybar JSON for the current power-profiles-daemon profile.
p=$(busctl get-property org.freedesktop.UPower.PowerProfiles \
        /org/freedesktop/UPower/PowerProfiles \
        org.freedesktop.UPower.PowerProfiles ActiveProfile 2>/dev/null \
    | awk '{gsub(/"/,"",$2); print $2}')

case "$p" in
    performance) echo '{"text":"󰓅","tooltip":"Performance — click to balance","class":"performance"}';;
    balanced)    echo '{"text":"󰾅","tooltip":"Balanced — click for performance","class":"balanced"}';;
    power-saver) echo '{"text":"󰾆","tooltip":"Power Saver","class":"power-saver"}';;
    *)           echo '{"text":"󰓅","tooltip":"power-profiles-daemon not running","class":"unknown"}';;
esac
