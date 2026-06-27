#!/usr/bin/env bash
# Live Claude Code activity monitor (node9-style side panel).
# Reads ~/.claude/activity.log (written by the cc-log-activity.sh hook).
log="$HOME/.claude/activity.log"

g=$'\033[38;2;168;153;132m'; gr=$'\033[38;2;184;187;38m'; aq=$'\033[38;2;131;165;152m'
or=$'\033[38;2;254;128;25m'; ye=$'\033[38;2;250;189;47m'; rd=$'\033[38;2;251;73;52m'
pu=$'\033[38;2;211;134;155m'; fg=$'\033[38;2;235;219;178m'; dim=$'\033[38;2;102;92;84m'
rs=$'\033[0m'; b=$'\033[1m'

color_tool() {
    case "$1" in
        Read)                            printf '%s' "$aq" ;;
        Edit|MultiEdit|Write|NotebookEdit) printf '%s' "$gr" ;;
        Bash)                            printf '%s' "$or" ;;
        Grep|Glob)                       printf '%s' "$ye" ;;
        Task)                            printf '%s' "$pu" ;;
        *)                               printf '%s' "$g" ;;
    esac
}

# ms -> "2h18m" / "47m" / "12s"
fmt_dur() {
    local s=$((${1:-0}/1000))
    if   [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s/3600)) $(((s%3600)/60))
    elif [ "$s" -ge 60 ];   then printf '%dm' $((s/60))
    else printf '%ds' "$s"; fi
}

# prompts submitted this session (epoch col >= session-start), else all-time
prompt_count() {
    local pl="$HOME/.claude/prompts.log" sf="$HOME/.claude/session-start" start=0
    [ -s "$pl" ] || { printf '0'; return; }
    [ -r "$sf" ] && start=$(cat "$sf" 2>/dev/null)
    awk -F'\t' -v s="${start:-0}" '$1>=s' "$pl" | wc -l
}

trap 'printf "\033[?25h\033[2J\033[H"; exit 0' INT TERM
printf '\033[?25l'   # hide cursor

while true; do
    out="${b}${or} 󰚩 CLAUDE ACTIVITY${rs}${dim}   ·   $(date +%H:%M:%S)${rs}\n"
    out+="${dim} ────────────────────────────────────────────${rs}\n\n"

    # ── SESSION metrics (from statusline's metrics.json + prompts.log) ──
    m="$HOME/.claude/metrics.json"
    if [ -s "$m" ]; then
        read -r mcost madd mrem mdur mmodel < <(jq -r \
            '[(.cost//0), (.add//0), (.rem//0), (.dur_ms//0), (.model//"Claude")] | @tsv' "$m" 2>/dev/null)
        pc=$(prompt_count)
        out+="${dim} SESSION${rs}  ${ye}${mmodel}${rs}   ${pu}󱎫 ${fg}${pc}${dim} prompts${rs}   ${aq}⏱ ${fg}$(fmt_dur "$mdur")${rs}\n"
        out+="          ${gr}\$$(printf '%.2f' "${mcost:-0}")${rs}   ${gr}+${madd}${rs} ${rd}-${mrem}${rs}\n\n"
    fi

    if [ ! -s "$log" ]; then
        out+="${g}  waiting for Claude to use a tool…${rs}\n"
    else
        rc=$(grep -cP '\tRead\t' "$log")
        ec=$(grep -cP '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log")
        bc=$(grep -cP '\tBash\t' "$log")
        sc=$(grep -cP '\t(Grep|Glob)\t' "$log")
        tc=$(grep -cP '\tTask\t' "$log")

        out+="${dim} TOOLS${rs}   ${aq}Read ${fg}${rc}${rs}   ${gr}Edit ${fg}${ec}${rs}   ${or}Bash ${fg}${bc}${rs}   ${ye}Search ${fg}${sc}${rs}   ${pu}Task ${fg}${tc}${rs}\n\n"

        out+="${dim} RECENT${rs}\n"
        while IFS=$'\t' read -r ts tool tgt; do
            [ -z "$tool" ] && continue
            c=$(color_tool "$tool")
            out+="  ${dim}${ts}${rs}  ${c}$(printf '%-7s' "$tool")${rs}${fg}${tgt}${rs}\n"
        done < <(tail -n 14 "$log")

        out+="\n${dim} FILES TOUCHED${rs}\n"
        while read -r f; do
            [ -n "$f" ] && out+="  ${gr}󰷈 ${fg}${f}${rs}\n"
        done < <(grep -P '\t(Edit|MultiEdit|Write|NotebookEdit)\t' "$log" | cut -f3 | awk 'NF' | sort -u | tail -8)
    fi

    printf '\033[H%b\033[J' "$out"
    sleep 1
done
