#!/usr/bin/env bash
# Install the low-overhead portal health timer and package/config change watcher.

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
portal_dir="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal"

mkdir -p "$unit_dir" "$portal_dir"

ln -sfn "$repo_dir/xdg-desktop-portal/hyprland-portals.conf" \
    "$portal_dir/hyprland-portals.conf"

for unit in portal-health.service portal-health.timer portal-refresh.service portal-refresh.path; do
    ln -sfn "$repo_dir/systemd/user/$unit" "$unit_dir/$unit"
done

systemctl --user daemon-reload
systemctl --user enable --now portal-health.timer portal-refresh.path
systemctl --user start portal-refresh.service

printf '%s\n' "Portal self-healing enabled."
