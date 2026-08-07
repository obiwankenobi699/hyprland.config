#!/usr/bin/env bash
set -euo pipefail

monitor=$(kdialog \
    --menu 'Choose lockscreen monitor' \
    eDP-1 'Internal display (eDP-1)' \
    HDMI-A-1 'External display (HDMI-A-1)' \
    --title 'Choose monitor')

[[ -n "$monitor" ]] || exit 0

wallpaper=$(kdialog \
    --getopenfilename "$HOME/Pictures/wallpaper" \
    'Images (*.png *.jpg *.jpeg *.webp *.avif)' \
    --title "Choose lockscreen wallpaper for $monitor")

[[ -n "$wallpaper" ]] || exit 0
exec "$HOME/.config/hypr/scripts/lock-wallpaper-sync.sh" "$monitor" "$wallpaper"
