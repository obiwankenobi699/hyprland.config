#!/usr/bin/env bash
set -euo pipefail

waypaper_config="${XDG_CONFIG_HOME:-$HOME/.config}/waypaper/config.ini"
lock_cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
lock_wallpaper="$lock_cache/lock-wallpaper"

if [[ ! -r "$waypaper_config" ]]; then
    printf 'Waypaper config not found: %s\n' "$waypaper_config" >&2
    exit 1
fi

wallpaper=$(awk -F= '
    /^[[:space:]]*wallpaper[[:space:]]*=/ {
        value = $2
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        print value
        exit
    }
' "$waypaper_config")

case "$wallpaper" in
    "~/"*) wallpaper="$HOME/${wallpaper:2}" ;;
    /*) ;;
    *) wallpaper="$(dirname "$waypaper_config")/$wallpaper" ;;
esac

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    printf 'Waypaper wallpaper does not exist: %s\n' "${wallpaper:-<empty>}" >&2
    exit 1
fi

mkdir -p "$lock_cache"
ln -sfn -- "$wallpaper" "$lock_wallpaper"
