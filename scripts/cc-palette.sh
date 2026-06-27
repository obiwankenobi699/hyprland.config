#!/usr/bin/env bash
# Claude Code command palette (wofi). Central launcher for the dev tools.
# Bound to SUPER+SHIFT+C.
choice=$(printf '%s\n' \
    "󰊢  Git diff (lazygit)" \
    "󰚩  Activity monitor" \
    "󱎫  Prompt history" \
    "󰉋  Project files" \
    "󰌷  Activity log (raw)" \
    "󰜉  Reload Hyprland" \
    | wofi --dmenu --insensitive --prompt "Claude actions" --width 440 --height 320)

S="$HOME/.config/hypr/scripts"

# resolve a repo: git root of the last-edited file, else hypr config
repo=""
last=$(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$HOME/.claude/activity.log" 2>/dev/null | tail -1 | cut -f3)
last="${last/#\~/$HOME}"
[ -n "$last" ] && repo=$(git -C "$(dirname "$last")" rev-parse --show-toplevel 2>/dev/null)
[ -z "$repo" ] && repo="$HOME/.config/hypr"

case "$choice" in
    *"Git diff"*)         "$S/cc-diffpanel.sh" ;;
    *"Activity monitor"*) kitty --class cc-monitor -e "$S/cc-monitor.sh" ;;
    *"Prompt history"*)   "$S/cc-prompt-history.sh" ;;
    *"Project files"*)    kitty --class cc-monitor --directory "$repo" ;;
    *"Activity log"*)     kitty --class cc-monitor -e bash -c "less +G ~/.claude/activity.log" ;;
    *"Reload Hyprland"*)  hyprctl reload && notify-send "󰚩 Claude" "Hyprland reloaded." ;;
esac
