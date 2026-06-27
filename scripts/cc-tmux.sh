#!/usr/bin/env bash
# cc-tmux.sh — Claude Code "cockpit" tmux layout, per project.
#
#   ┌──────────────────┬──────────────┐
#   │  Claude (chat)   │ cc-monitor   │   left  = conversation
#   │  ~60%            ├──────────────┤   right = everything Claude touched
#   │                  │ lazygit      │          (activity feed, diff, shell)
#   │                  ├──────────────┤
#   │                  │ shell        │
#   └──────────────────┴──────────────┘
#
# Picks a project with fzf (fallback: numbered menu), names the tmux session
# after it, and re-attaches if that session already exists — so the same
# layout drives many projects. Bound to SUPER+SHIFT+D (opens in a fresh kitty).

SCRIPTS="$HOME/.config/hypr/scripts"

# ── where to look for git projects (edit to taste) ──
ROOTS=("$HOME/Main" "$HOME/Rice" "$HOME/PycharmProjects" "$HOME/.config")

# collect git repos: deep scan of the roots + shallow scan of ~ for top-level
# repos (skipping hidden dirs), plus the hypr config itself
mapfile -t projects < <(
    for r in "${ROOTS[@]}"; do
        [ -d "$r" ] && find "$r" -maxdepth 3 -type d -name .git -prune 2>/dev/null \
            | sed 's,/\.git$,,'
    done
    find "$HOME" -maxdepth 2 -type d -name .git -not -path "$HOME/.*" 2>/dev/null \
        | sed 's,/\.git$,,'
    printf '%s\n' "$HOME/.config/hypr"
)
# de-dupe, keep order
mapfile -t projects < <(printf '%s\n' "${projects[@]}" | awk 'NF && !seen[$0]++')

# ── pick one (or type a custom path) ──
if command -v fzf >/dev/null 2>&1; then
    # --print-query: line 1 = whatever you typed, line 2 = the highlighted match.
    # Prefer a real match; otherwise fall back to the typed path → custom dirs work.
    out=$(printf '%s\n' "${projects[@]}" | sed "s,$HOME,~," \
        | fzf --print-query --prompt='project (type a path for custom) ❯ ' \
              --height=40% --reverse --border)
    query=$(printf '%s\n' "$out" | sed -n 1p)
    pick=$(printf '%s\n' "$out" | sed -n 2p)
    proj="${pick:-$query}"
    proj="${proj/#\~/$HOME}"
else
    echo "Select a project (last option = custom path):"
    select p in "${projects[@]}" "↳ custom path…"; do
        if [ "$p" = "↳ custom path…" ]; then
            read -rp "Path: " proj; proj="${proj/#\~/$HOME}"
        else
            proj="$p"
        fi
        break
    done
fi
[ -z "$proj" ]   && { echo "no project chosen"; exit 1; }
[ -d "$proj" ]   || { echo "not a directory: $proj"; exit 1; }

# tmux session name = sanitized basename
name=$(basename "$proj" | tr -c 'a-zA-Z0-9_' '_')

attach() { if [ -n "$TMUX" ]; then tmux switch-client -t "$name"; else tmux attach -t "$name"; fi; }

# already running? just go to it
tmux has-session -t "$name" 2>/dev/null && { attach; exit 0; }

# ── build the cockpit ──
tmux new-session -d -s "$name" -c "$proj" -n dev

# pane 0 = Claude (left); carve a 40% column on the right
tmux send-keys     -t "$name:dev.0" 'claude' C-m
tmux split-window  -h -l 40% -t "$name:dev.0" -c "$proj"   # pane 1 (right, top)
tmux send-keys     -t "$name:dev.1" "$SCRIPTS/cc-monitor.sh" C-m
tmux split-window  -v -l 67% -t "$name:dev.1" -c "$proj"   # pane 2 (right, mid)
tmux send-keys     -t "$name:dev.2" 'lazygit' C-m
tmux split-window  -v -l 50% -t "$name:dev.2" -c "$proj"   # pane 3 (right, bottom = shell)

tmux select-pane -t "$name:dev.0"
attach
