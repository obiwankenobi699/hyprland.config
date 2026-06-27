#!/usr/bin/env bash
# Toggle a lazygit overlay showing what Claude edited (git changes: file list +
# before/after diffs + new untracked files). Bound to SUPER+SHIFT+P.
class="cc-diffpanel"

# already open? -> close it (toggle back to normal UI)
addr=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class==\"$class\") | .address" | head -1)
if [ -n "$addr" ]; then
    hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1
    exit 0
fi

# pick the repo: git root of the most-recently edited file, else active window cwd, else hypr
log="$HOME/.claude/activity.log"
repo=""
last=$(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log" 2>/dev/null | tail -1 | cut -f3)
last="${last/#\~/$HOME}"
[ -n "$last" ] && repo=$(git -C "$(dirname "$last")" rev-parse --show-toplevel 2>/dev/null)

if [ -z "$repo" ]; then
    pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty')
    [ -n "$pid" ] && cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null) && \
        repo=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
fi
[ -z "$repo" ] && repo="$HOME/.config/hypr"

kitty -o background_opacity=1.0 --class "$class" --directory "$repo" -e lazygit
