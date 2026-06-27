#!/usr/bin/env bash
# Mission Control — Spotlight-style command palette for the Claude cockpit.
# Launched from a tmux popup (Alt+Space), so it stays in the same terminal:
# no wofi, no new window. Actions run in the popup; prompt recall is typed
# straight into the Claude pane.
#
#   bind -n M-Space display-popup -E ... cc-mission.sh   (set by cc-tmux.sh)

log="$HOME/.claude/activity.log"
prompts="$HOME/.claude/prompts.log"
metrics="$HOME/.claude/metrics.json"
tasks="$HOME/.claude/tasks.md"

# the Claude pane (recorded by cc-tmux.sh as a session env var) for prompt recall
cp=$(tmux show-environment CLAUDE_PANE 2>/dev/null | grep '^CLAUDE_PANE=' | cut -d= -f2-)

# repo: cwd if git, else repo of last-edited file, else hypr
resolve_repo() {
    local r last
    r=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) && { printf '%s' "$r"; return; }
    last=$(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log" 2>/dev/null | tail -1 | cut -f3)
    last="${last/#\~/$HOME}"
    [ -n "$last" ] && r=$(git -C "$(dirname "$last")" rev-parse --show-toplevel 2>/dev/null) \
        && { printf '%s' "$r"; return; }
    printf '%s' "$HOME/.config/hypr"
}
repo=$(resolve_repo)

FZF=(fzf --height=100% --reverse --border --prompt='mission ❯ ' --pointer='▶')

choice=$(printf '%s\n' \
    "󰈍  Review changes (AI queue)" \
    "󰊢  Git diff (lazygit)" \
    "󱎫  Recall a prompt → Claude" \
    "󰈞  Open a file (fzf)" \
    "󱖫  Token / cost usage" \
    "  Add task" \
    "󰄬  Toggle task" \
    "󰷈  Recent files" \
    "󰜉  Reload Hyprland" \
    | "${FZF[@]}")

case "$choice" in
    *"Review changes"*)
        exec "$HOME/.config/hypr/scripts/cc-review.sh" ;;

    *"Git diff"*)
        cd "$repo" && exec lazygit ;;

    *"Recall a prompt"*)
        [ -s "$prompts" ] || { echo "no prompt history yet"; sleep 1; exit 0; }
        sel=$(tac "$prompts" | cut -f2- | awk 'length && !seen[$0]++' \
              | "${FZF[@]}" --prompt='recall ❯ ')
        if [ -n "$sel" ] && [ -n "$cp" ]; then
            tmux send-keys -t "$cp" -l "$sel"   # typed, not submitted — review then Enter
        fi ;;

    *"Open a file"*)
        if command -v rg >/dev/null; then list=(rg --files "$repo"); else list=(find "$repo" -type f); fi
        f=$("${list[@]}" 2>/dev/null | "${FZF[@]}" --prompt='open ❯ ')
        [ -n "$f" ] && exec "${EDITOR:-nvim}" "$f" ;;

    *"Token / cost usage"*)
        if [ -s "$metrics" ]; then
            jq -r '"  model   \(.model)\n  cost    $\(.cost)\n  +lines  \(.add)\n  -lines  \(.rem)\n  context \(.ctx)%\n  tokens  \(.toks)"' "$metrics"
        else echo "  no metrics yet (statusline writes them)"; fi
        echo; read -rp "  [enter to close] " _ ;;

    *"Add task"*)
        read -rp "  new task: " t
        [ -n "$t" ] && printf -- '- [ ] %s\n' "$t" >> "$tasks" && echo "  added." && sleep 0.4 ;;

    *"Toggle task"*)
        [ -s "$tasks" ] || { echo "no tasks yet"; sleep 1; exit 0; }
        pick=$(grep -nE '^- \[[ xX]\]' "$tasks" | "${FZF[@]}" --prompt='toggle ❯ ')
        ln=${pick%%:*}
        if [ -n "$ln" ]; then
            cur=$(sed -n "${ln}p" "$tasks")
            if [[ $cur == '- [ ]'* ]]; then new="- [x]${cur:5}"; else new="- [ ]${cur:5}"; fi
            awk -v n="$ln" -v r="$new" 'NR==n{print r; next} {print}' "$tasks" > "$tasks.tmp" \
                && mv "$tasks.tmp" "$tasks"
        fi ;;

    *"Recent files"*)
        f=$(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log" 2>/dev/null \
            | cut -f3 | awk 'NF && !seen[$0]++' | tac | "${FZF[@]}" --prompt='recent ❯ ')
        f="${f/#\~/$HOME}"
        [ -n "$f" ] && [ -f "$f" ] && exec "${EDITOR:-nvim}" "$f" ;;

    *"Reload Hyprland"*)
        hyprctl reload && notify-send "󰚩 Claude" "Hyprland reloaded." ;;
esac
