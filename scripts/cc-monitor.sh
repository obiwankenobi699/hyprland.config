#!/usr/bin/env bash
# Claude Code STATE dashboard (cockpit right pane / SUPER+SHIFT+A).
#
# Phase-1 stability:
#   • data collection is split from rendering — the expensive `git` scan runs in
#     collect_project() and is cached on disk with a TTL, while the screen is
#     rendered every second from cheap sources + that cache.
#   • the frame is repainted line-by-line (each line cleared to EOL, then clear
#     below) so it never flickers and never leaves artifacts when text shrinks.
#   • SIGWINCH triggers a full clear so a pane resize can't smear the layout.
#
# Data / cache:
#   ~/.claude/activity.log  (PostToolUse hook) → current action + recent files
#   ~/.claude/metrics.json  (statusline)       → model / cost / lines / ctx
#   ~/.claude/tasks.md      (you / cc-mission) → task checklist
#   $XDG_CACHE_HOME/cc-cockpit/project         → cached git state (TTL below)

log="$HOME/.claude/activity.log"
metrics="$HOME/.claude/metrics.json"
tasks="$HOME/.claude/tasks.md"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cc-cockpit"
mkdir -p "$CACHE"
GIT_CACHE="$CACHE/project"
GIT_TTL=3                       # seconds between git scans

g=$'\033[38;2;168;153;132m'; gr=$'\033[38;2;184;187;38m'; aq=$'\033[38;2;131;165;152m'
or=$'\033[38;2;254;128;25m'; ye=$'\033[38;2;250;189;47m'; rd=$'\033[38;2;251;73;52m'
pu=$'\033[38;2;211;134;155m'; fg=$'\033[38;2;235;219;178m'; dim=$'\033[38;2;102;92;84m'
rs=$'\033[0m'; b=$'\033[1m'
rule="${dim} ────────────────────────────────────────────${rs}"

verb_for() {
    case "$1" in
        Read)                              printf 'Reading' ;;
        Edit|MultiEdit|Write|NotebookEdit) printf 'Editing' ;;
        Bash)                              printf 'Running' ;;
        Grep|Glob)                         printf 'Searching' ;;
        Task)                              printf 'Delegating' ;;
        *)                                 printf '%s' "$1" ;;
    esac
}

fmt_idle() {
    local s=${1:-0}
    if   [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s/3600)) $(((s%3600)/60))
    elif [ "$s" -ge 60 ];   then printf '%dm' $((s/60))
    else printf '%ds' "$s"; fi
}

resolve_repo() {
    local r last
    r=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) && { printf '%s' "$r"; return; }
    last=$(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log" 2>/dev/null | tail -1 | cut -f3)
    last="${last/#\~/$HOME}"
    [ -n "$last" ] && r=$(git -C "$(dirname "$last")" rev-parse --show-toplevel 2>/dev/null) \
        && { printf '%s' "$r"; return; }
    printf '%s' "$HOME/.config/hypr"
}

# ── DATA COLLECTION ────────────────────────────────────────
# Expensive git scan → cached as tab-separated values. Only re-runs when the
# cache is older than GIT_TTL, so the 1s render loop stays cheap.
collect_project() {
    local now mt
    now=$(date +%s); mt=0
    [ -f "$GIT_CACHE" ] && mt=$(stat -c %Y "$GIT_CACHE" 2>/dev/null)
    [ $(( now - mt )) -lt "$GIT_TTL" ] && return        # still fresh

    local repo branch porc n_new n_del n_tot n_mod ab behind ahead
    repo=$(resolve_repo)
    branch=$(git -C "$repo" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null)
    porc=$(git -C "$repo" status --porcelain 2>/dev/null)
    n_new=$(printf '%s\n' "$porc" | grep -c '^??')
    n_del=$(printf '%s\n' "$porc" | grep -cE '^.?D')
    n_tot=$(printf '%s\n' "$porc" | grep -c .)
    n_mod=$(( n_tot - n_new - n_del )); [ "$n_mod" -lt 0 ] && n_mod=0
    ab=$(git -C "$repo" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
    behind=$(printf '%s' "$ab" | awk '{print $1+0}'); ahead=$(printf '%s' "$ab" | awk '{print $2+0}')

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$repo" "${branch:-—}" "$n_mod" "$n_new" "$n_del" "${ahead:-0}" "${behind:-0}" \
        > "$GIT_CACHE.tmp" && mv "$GIT_CACHE.tmp" "$GIT_CACHE"
}

# ── RENDER (pure: read cache + cheap sources → append to $out) ──
render_project() {
    [ -f "$GIT_CACHE" ] || { out+="${dim} PROJECT${rs}  ${g}scanning…${rs}\n"; return; }
    local repo branch n_mod n_new n_del ahead behind track=""
    IFS=$'\t' read -r repo branch n_mod n_new n_del ahead behind < "$GIT_CACHE"
    [ "${ahead:-0}" -gt 0 ]  && track+=" ${gr}↑${ahead}${rs}"
    [ "${behind:-0}" -gt 0 ] && track+=" ${rd}↓${behind}${rs}"
    out+="${dim} PROJECT${rs}  ${pu}󰘬 ${fg}${branch}${rs}   ${dim}${repo##*/}${rs}${track}\n"
    out+="          ${gr}~ ${fg}${n_mod}${dim} mod${rs}   ${ye}+ ${fg}${n_new}${dim} new${rs}   ${rd}- ${fg}${n_del}${dim} del${rs}\n"
}

render_claude() {
    local now mt idle ltool ltgt verb base
    now=$(date +%s)
    if [ -s "$log" ]; then
        mt=$(stat -c %Y "$log" 2>/dev/null || echo "$now")
        idle=$(( now - mt )); [ "$idle" -lt 0 ] && idle=0
        IFS=$'\t' read -r _ ltool ltgt < <(tail -n 1 "$log")
        verb=$(verb_for "$ltool"); base=$(basename "${ltgt:-—}")
        if [ "$idle" -le 4 ]; then
            out+="${dim} CLAUDE${rs}   ${gr}▶ ${fg}${verb} ${aq}${base}${rs}\n"
        else
            out+="${dim} CLAUDE${rs}   ${g}● idle $(fmt_idle "$idle")${rs}   ${dim}last: ${verb} ${base}${rs}\n"
        fi
    else
        out+="${dim} CLAUDE${rs}   ${g}waiting for a tool…${rs}\n"
    fi
    if [ -s "$metrics" ]; then
        local mmodel mcost madd mrem mctx
        IFS=$'\t' read -r mmodel mcost madd mrem mctx < <(jq -r \
            '[(.model//"Claude"),(.cost//0),(.add//0),(.rem//0),(.ctx//0)] | @tsv' "$metrics" 2>/dev/null)
        out+="          ${ye}${mmodel}${rs}  ${gr}\$$(printf '%.2f' "${mcost:-0}")${rs}  ${gr}+${madd}${rs} ${rd}-${mrem}${rs}  ${aq}${mctx}% ctx${rs}\n"
    fi
}

render_tasks() {
    out+="${dim} TASKS${rs}\n"
    if [ -s "$tasks" ] && grep -qE '^- \[[ xX]\]' "$tasks"; then
        local n=0 t
        while IFS= read -r t; do
            case "$t" in
                '- [x]'*|'- [X]'*) out+="   ${dim}☑ ${t:6}${rs}\n" ;;
                '- [ ]'*)          out+="   ${ye}☐${rs} ${fg}${t:6}${rs}\n" ;;
                *) continue ;;
            esac
            n=$((n+1)); [ "$n" -ge 6 ] && break
        done < "$tasks"
    else
        out+="   ${dim}(none — add one from Mission Control: Alt+Space)${rs}\n"
    fi
}

render_recent() {
    out+="${dim} RECENT${rs}\n"
    [ -s "$log" ] || return
    local f d bn
    while read -r f; do
        [ -z "$f" ] && continue
        d=$(dirname "$f"); bn=$(basename "$f")
        out+="   ${gr}󰷈 ${fg}${bn}${dim}  ${d}${rs}\n"
    done < <(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log" \
             | cut -f3 | awk 'NF && !seen[$0]++' | tail -6)
}

# flicker-free repaint: home cursor, clear each line to EOL, clear below.
paint() {
    printf '\033[H'
    printf '%b' "${1//\\n/\\033[K\\n}"
    printf '\033[J'
}

printf '\033[?25l\033[2J\033[H'                          # hide cursor, clear once
trap 'printf "\033[?25h\033[2J\033[H"; exit 0' INT TERM
trap 'printf "\033[2J\033[H"' WINCH                       # resize → full clear

while true; do
    collect_project                                      # refresh cache if stale
    out="${b}${or} 󰚩 CLAUDE COCKPIT${rs}${dim}   ·   $(date +%H:%M:%S)${rs}\n$rule\n\n"
    render_project; out+="$rule\n\n"
    render_claude;  out+="$rule\n\n"
    render_tasks;   out+="\n$rule\n\n"
    render_recent
    paint "$out"
    sleep 1
done
