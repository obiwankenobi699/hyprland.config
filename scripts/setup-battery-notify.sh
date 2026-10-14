#!/usr/bin/env bash
# Install the repository-owned low-battery user timer.

set -eu

repo_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"

mkdir -p "$unit_dir" "$state_dir"
ln -sfn "$repo_dir/systemd/user/battery-notify.service" "$unit_dir/battery-notify.service"
ln -sfn "$repo_dir/systemd/user/battery-notify.timer" "$unit_dir/battery-notify.timer"

systemctl --user daemon-reload
systemctl --user enable --now battery-notify.timer

printf 'battery-notify.timer installed and started\n'
