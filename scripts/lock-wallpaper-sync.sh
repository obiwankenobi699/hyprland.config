#!/usr/bin/env bash
set -euo pipefail

lock_cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"

if [[ $# -ne 2 ]]; then
    printf 'Usage: %s MONITOR IMAGE_PATH\n' "$0" >&2
    exit 2
fi

monitor=$1
wallpaper=$2
case "$monitor" in
    eDP-1|HDMI-A-1) ;;
    *) printf 'Unsupported monitor: %s\n' "$monitor" >&2; exit 2 ;;
esac

lock_wallpaper="$lock_cache/lock-wallpaper-$monitor"

if [[ "$wallpaper" == "~/"* ]]; then
    wallpaper="$HOME/${wallpaper:2}"
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    printf 'Waypaper wallpaper does not exist: %s\n' "${wallpaper:-<empty>}" >&2
    exit 1
fi

mkdir -p "$lock_cache"
ln -sfn -- "$wallpaper" "$lock_wallpaper"
