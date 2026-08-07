#!/usr/bin/env bash
# cc-tmux.sh — Claude Code "cockpit" tmux layout, per project.
#
#   ┌────────────────────┬────────────┐
#   │  Claude (chat)     │ cockpit    │   left  = conversation (~68%)
#   │  ~68%              │ dashboard  │   right = live STATE + shell
#   │                    ├────────────┤
#   │                    │ shell      │   lazygit → prefix + g  (popup)
#   └────────────────────┴────────────┘   palette → Alt+Space   (popup)
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

attach() {
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$name"
    else
        tmux attach -t "$name"
    fi
}

# Reuse a complete cockpit, but do not treat an old/restored partial session
# as healthy. Resurrect can restore a session after one of its panes exited;
# in that case create a new cockpit window without destroying the old work.
window=dev
if tmux has-session -t "$name" 2>/dev/null; then
    complete_window=""
    while read -r candidate pane_count; do
        case "$candidate" in
            dev|cockpit|cockpit-[0-9]*) ;;
            *) continue ;;
        esac

        if [ "$pane_count" -eq 3 ] &&
            ! tmux list-panes -t "$name:$candidate" -F '#{pane_dead}' | grep -Fxq 1; then
            complete_window=$candidate
            break
        fi
    done < <(tmux list-windows -t "$name" -F '#{window_name} #{window_panes}')

    if [ -n "$complete_window" ]; then
        tmux select-window -t "$name:$complete_window"
        attach
        exit 0
    fi

    window=cockpit
    suffix=1
    while tmux list-windows -t "$name" -F '#{window_name}' | grep -Fxq "$window"; do
        window="cockpit-$suffix"
        suffix=$((suffix + 1))
    done
fi

# ── build the cockpit ──
# CC_COCKPIT=1 → panes' .bashrc skips fastfetch (stays in the startup path for
# normal terminals only). -e sets it for the very first pane too.
if tmux has-session -t "$name" 2>/dev/null; then
    claude_pane=$(tmux new-window -d -t "$name:" -n "$window" -c "$proj" -e CC_COCKPIT=1 -P -F '#{pane_id}')
else
    claude_pane=$(tmux new-session -d -s "$name" -c "$proj" -n "$window" -e CC_COCKPIT=1 -P -F '#{pane_id}')
fi
tmux set-option -w -t "$name:$window" remain-on-exit on

# Capture pane IDs rather than assuming numeric indexes. The active tmux
# configuration uses pane-base-index 1, and pane IDs remain stable as splits
# are created.
# Claude (left, ~68%)
tmux send-keys -t "$claude_pane" 'claude' C-m

# record the Claude pane so Mission Control can type recalled prompts into it
tmux set-environment -t "$name" CLAUDE_PANE "$claude_pane"

# STATE dashboard (right column, ~32% wide, top ~55%)
cockpit_pane=$(tmux split-window -h -l 32% -t "$claude_pane" -c "$proj" -P -F '#{pane_id}')
tmux send-keys -t "$cockpit_pane" "$SCRIPTS/cc-monitor.sh" C-m

# shell (right column, bottom ~45%) — lazygit is now prefix+g popup
shell_pane=$(tmux split-window -v -l 45% -t "$cockpit_pane" -c "$proj" -e CC_COCKPIT=1 -P -F '#{pane_id}')

# labeled pane headers (shown by pane-border-status — clear separation)
tmux select-pane -t "$claude_pane" -T " 󰚩 claude "
tmux select-pane -t "$cockpit_pane" -T " 󰕮 cockpit "
tmux select-pane -t "$shell_pane" -T "  shell "

tmux select-window -t "$name:$window"
tmux select-pane -t "$claude_pane"
attach
