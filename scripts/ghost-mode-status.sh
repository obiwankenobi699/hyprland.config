#!/usr/bin/env bash

set -u

wolf="/home/mukul/Pictures/face/wolf.jpg"
hyde_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hyde/hyde.conf"
wallbash_mode=""

if [[ -r "$hyde_conf" ]]; then
    wallbash_mode=$(awk -F= '$1 == "enableWallDcol" { gsub(/[[:space:]]/, "", $2); gsub(/"/, "", $2); print $2; exit }' "$hyde_conf")
fi

# wallbashtoggle.sh uses: 0=theme, 1=auto, 2=dark, 3=light.
if [[ "$wallbash_mode" == "3" ]]; then
    printf '\nLight theme · Ghost Mode inactive\n'
    exit 0
elif [[ "$wallbash_mode" == "2" ]]; then
    printf '%s\nGhost Mode · Dark theme\n' "$wolf"
    exit 0
fi

scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)

if [[ "$scheme" == *prefer-dark* ]]; then
    printf '%s\nGhost Mode · Dark theme\n' "$wolf"
else
    printf '\nLight theme · Ghost Mode inactive\n'
fi
