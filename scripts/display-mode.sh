#!/usr/bin/env bash

set -u

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
mode_config="$config_dir/modes/display-mode.conf"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
state_file="$state_dir/display-mode"
shader_dir="$config_dir/shaders"

die() {
    notify-send -u critical "Display mode" "$1" 2>/dev/null || true
    printf '%s\n' "$1" >&2
    exit 1
}

find_mode() {
    awk -F '|' -v wanted="$1" '$1 == wanted { print; found=1 } END { exit !found }' "$mode_config"
}

apply_mode() {
    local mode="$1" entry label temperature gamma shader
    entry=$(find_mode "$mode") || die "Unknown display mode: $mode"
    IFS='|' read -r mode label temperature gamma shader <<< "$entry"

    command -v hyprsunset >/dev/null 2>&1 || die "hyprsunset is not installed"
    if [[ "$mode" == bw && ( ! -x "$(command -v hyprshade 2>/dev/null || true)" || ! -f "$shader_dir/$shader.glsl" ) ]]; then
        die "Black & White requires hyprshade and the grayscale shader"
    fi
    pkill -x hyprsunset 2>/dev/null || true
    if [[ "$temperature" == 6500 && "$gamma" == 100 ]]; then
        hyprsunset -i >/dev/null 2>&1 &
    else
        hyprsunset -t "$temperature" -g "$gamma" >/dev/null 2>&1 &
    fi

    if command -v hyprshade >/dev/null 2>&1; then
        hyprshade off >/dev/null 2>&1 || true
        if [[ "$shader" != off && -f "$shader_dir/$shader.glsl" ]]; then
            hyprshade on "$shader" >/dev/null 2>&1 || die "Could not activate the $label shader"
        fi
    elif [[ "$shader" != off ]]; then
        notify-send -u low "Display mode" "$label temperature applied; install hyprshade for the filter" 2>/dev/null || true
    fi

    mkdir -p "$state_dir"
    printf '%s\n' "$mode" > "$state_file"
    notify-send -t 1800 -u low "Display mode" "$label" 2>/dev/null || true
}

show_menu() {
    local current=""
    [[ -r "$state_file" ]] && current=$(<"$state_file")
    local selected
    selected=$(awk -F '|' -v current="$current" '{
        marker = ($1 == current ? "●" : "○")
        print marker "  " $2 "\t" $1
    }' "$mode_config" |
        wofi --dmenu --prompt "Display mode" --insensitive 2>/dev/null |
        awk -F '\t' '{ print $2 }' || true)
    [[ -n "${selected:-}" ]] && apply_mode "$selected"
}

case "${1:-menu}" in
    menu) show_menu ;;
    restore)
        if [[ -r "$state_file" ]]; then
            apply_mode "$(<"$state_file")"
        else
            apply_mode standard
        fi
        ;;
    standard|bw) apply_mode "$1" ;;
    *) die "Usage: $0 {menu|restore|standard|cinematic|bw|night|reading|vivid}" ;;
esac
