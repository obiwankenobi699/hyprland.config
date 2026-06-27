#!/usr/bin/env bash
# Gruvbox statusline for Claude Code. Reads the status JSON on stdin, prints one line:
#   󰉋 dir  󰘬 branch ✚N  󰚩 Model  󰓅 ▓▓▓░ 66%  $cost  +add -rem  󰅐 5h 59%

input=$(cat)
j() { printf '%s' "$input" | jq -r "$1"; }

dir=$(j '.workspace.current_dir // .cwd // empty')
model=$(j '.model.display_name // "Claude"')
cost=$(j '.cost.total_cost_usd // 0')
add=$(j '.cost.total_lines_added // 0')
rem=$(j '.cost.total_lines_removed // 0')
ctx=$(j '.context_window.used_percentage // 0')
toks=$(j '.context_window.total_input_tokens // 0')
five=$(j '.rate_limits.five_hour.used_percentage // empty')
seven=$(j '.rate_limits.seven_day.used_percentage // empty')

# ── Gruvbox (24-bit) ──
gray=$'\033[38;2;168;153;132m'; green=$'\033[38;2;184;187;38m'
aqua=$'\033[38;2;131;165;152m'; orange=$'\033[38;2;254;128;25m'
yellow=$'\033[38;2;250;189;47m'; red=$'\033[38;2;251;73;52m'
purple=$'\033[38;2;211;134;155m'; fg=$'\033[38;2;235;219;178m'
dim=$'\033[38;2;102;92;84m'; rst=$'\033[0m'
sep="${dim} │ ${rst}"

# colour by usage: <50 green, <80 yellow, else red
heat() { local p=$1; if [ "$p" -lt 50 ]; then printf '%s' "$green"; elif [ "$p" -lt 80 ]; then printf '%s' "$yellow"; else printf '%s' "$red"; fi; }

# 8-segment bar from a 0-100 percentage
bar() {
    local p=$1 w=8 f i out=""
    f=$(( (p * w + 50) / 100 )); [ "$f" -gt "$w" ] && f=$w
    for ((i=0; i<w; i++)); do [ "$i" -lt "$f" ] && out+="▓" || out+="░"; done
    printf '%s' "$out"
}

# pretty dir
pdir="${dir/#$HOME/\~}"

# git
branch=""; dirty=""
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
    n=$(git -C "$dir" status --porcelain 2>/dev/null | grep -c .)
    [ "$n" -gt 0 ] && dirty="${orange} ✚${n}"
fi
cost=$(printf '%.2f' "$cost")
ch=$(heat "$ctx")

# compact token count: 664141 -> 664k, 1200000 -> 1.2M
fmt_tok() {
    local t=$1
    if [ "$t" -ge 1000000 ]; then printf '%d.%dM' $((t/1000000)) $(((t%1000000)/100000));
    elif [ "$t" -ge 1000 ]; then printf '%dk' $((t/1000));
    else printf '%d' "$t"; fi
}

line="${aqua}󰉋 ${fg}${pdir}${rst}"
[ -n "$branch" ] && line+="${sep}${purple}󰘬 ${branch}${dirty}${rst}"
line+="${sep}${yellow}󰚩 ${fg}${model}${rst}"
line+="${sep}${ch}󰓅 $(bar "$ctx") ${ctx}% ${dim}$(fmt_tok "$toks")${rst}"
line+="${sep}${green}\$${cost}${rst}"
[ "$add" != "0" ] || [ "$rem" != "0" ] && line+="${sep}${green}+${add} ${red}-${rem}${rst}"
# usage quotas: session (5h) + weekly (7d), each heat-coloured
if [ -n "$five" ] || [ -n "$seven" ]; then
    line+="${sep}"
    [ -n "$five" ]  && line+="$(heat "$five")󰅐 sesh ${five}%${rst}"
    [ -n "$five" ] && [ -n "$seven" ] && line+="${dim} · ${rst}"
    [ -n "$seven" ] && line+="$(heat "$seven")wk ${seven}%${rst}"
fi

printf '%s\n' "$line"
