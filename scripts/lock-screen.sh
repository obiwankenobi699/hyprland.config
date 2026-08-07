#!/usr/bin/env bash
set -euo pipefail

config_file="$HOME/.config/hypr/hyprlock.conf"

choice=$(printf '%s\n' \
    'eDP-1' \
    'HDMI-A-1' \
    'Both' |
    wofi --dmenu --prompt 'Lock monitor' --lines 3)

case "$choice" in
    Both)
        exec hyprlock --config "$config_file"
        ;;
    eDP-1|HDMI-A-1)
        temporary_config=$(mktemp "${TMPDIR:-/tmp}/hyprlock.XXXXXX.conf")
        cleanup() {
            rm -f -- "$temporary_config"
        }
        trap cleanup EXIT INT TERM

        awk -v target="$choice" '
            function flush_block(    i, line, monitor, keep) {
                monitor = ""
                for (i = 1; i <= block_length; i++) {
                    line = block[i]
                    if (line ~ /^[[:space:]]*monitor[[:space:]]*=/) {
                        sub(/^[[:space:]]*monitor[[:space:]]*=[[:space:]]*/, "", line)
                        monitor = line
                    }
                }

                # Render backgrounds only on the selected output. An empty
                # monitor value means every monitor in Hyprlock.
                keep = block_type != "background" || monitor == target
                if (keep) {
                    for (i = 1; i <= block_length; i++) {
                        line = block[i]
                        if (block_type != "background" && line ~ /^[[:space:]]*monitor[[:space:]]*=[[:space:]]*$/)
                            line = "    monitor = " target
                        print line
                    }
                }
                delete block
                block_length = 0
            }

            /^[[:space:]]*(background|label|image|input-field)[[:space:]]*\{/ {
                in_block = 1
                block_type = $1
                block_length = 0
            }

            in_block {
                block[++block_length] = $0
                if ($0 ~ /^[[:space:]]*}[[:space:]]*$/) {
                    flush_block()
                    in_block = 0
                }
                next
            }

            { print }
        ' "$config_file" > "$temporary_config"

        if hyprlock --config "$temporary_config"; then
            status=0
        else
            status=$?
        fi
        cleanup
        trap - EXIT INT TERM
        exit "$status"
        ;;
    *)
        exit 0
        ;;
esac
