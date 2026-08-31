#!/usr/bin/env bash
set -eu

repo_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/diagnosticsd"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/diagnosticsd"

mkdir -p "$config_dir" "$unit_dir" "$data_dir"
if [ ! -e "$config_dir/thresholds.toml" ]; then
    cp "$repo_dir/diagnosticsd/thresholds.toml" "$config_dir/thresholds.toml"
fi

# Add new defaults without overwriting user-tuned thresholds from earlier phases.
if ! grep -q '^\[network.link_state\]' "$config_dir/thresholds.toml"; then
    cat >> "$config_dir/thresholds.toml" <<'EOF'

[network.link_state]
direction = "low"
warning = 0.5
critical = 0.0
warning_reason = "The default network interface is down"
critical_reason = "No active default network link is available"
EOF
fi

if ! grep -q '^\[kernel.failed_units\]' "$config_dir/thresholds.toml"; then
    cat >> "$config_dir/thresholds.toml" <<'EOF'

[kernel.failed_units]
direction = "high"
warning = 1
critical = 3
warning_reason = "A systemd unit has failed"
critical_reason = "Multiple systemd units have failed"
EOF
fi
ln -sfn "$repo_dir/systemd/user/diagnosticsd.service" "$unit_dir/diagnosticsd.service"
systemctl --user daemon-reload
systemctl --user enable --now diagnosticsd.service

printf 'diagnosticsd installed; edit %s and send SIGHUP with: systemctl --user reload-or-restart diagnosticsd\n' \
    "$config_dir/thresholds.toml"
