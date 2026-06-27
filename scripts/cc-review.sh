#!/usr/bin/env bash
# cc-review.sh — step through AI-generated changes like a PR review queue.
#
# Links the most recent prompt (the *intent*) to the files that changed, then
# walks them one at a time showing each diff through delta (falls back to git +
# less if delta isn't installed). Optimized for reviewing Claude's edits fast,
# not for authoring — it complements lazygit, it doesn't replace it.
#
#   per-file keys:  n next · p prev · s stage · o open in $EDITOR · g lazygit · q quit
#
# Launched from Mission Control or tmux prefix+r (full-screen popup).

log="$HOME/.claude/activity.log"
prompts="$HOME/.claude/prompts.log"

or=$'\033[38;2;254;128;25m'; gr=$'\033[38;2;184;187;38m'; aq=$'\033[38;2;131;165;152m'
ye=$'\033[38;2;250;189;47m'; rd=$'\033[38;2;251;73;52m'; fg=$'\033[38;2;235;219;178m'
dim=$'\033[38;2;102;92;84m'; pu=$'\033[38;2;211;134;155m'; rs=$'\033[0m'; b=$'\033[1m'

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
cd "$repo" || { echo "not a repo: $repo"; exit 1; }

# changed files: modified + untracked (-uall expands untracked dirs to files;
# rename "old -> new" keeps the new path)
mapfile -t files < <(git status --porcelain -uall | sed 's/^...//; s/.* -> //')
if [ "${#files[@]}" -eq 0 ]; then
    printf '%s  ✓ working tree clean — nothing to review.%s\n' "$gr" "$rs"
    read -rsn1 -p "  [enter to close] "; exit 0
fi

intent=$(tail -n 1 "$prompts" 2>/dev/null | cut -f2-)

# seconds -> "3s"/"4m"/"1h2m"
ago() { local s=${1:-0}; if [ "$s" -ge 3600 ]; then printf '%dh%dm' $((s/3600)) $(((s%3600)/60)); elif [ "$s" -ge 60 ]; then printf '%dm' $((s/60)); else printf '%ds' "$s"; fi; }

# show one file's diff, paged. delta if present, else git color + less.
show_diff() {
    local f="$1" tracked=1
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 || tracked=0
    {
        if [ "$tracked" -eq 1 ]; then
            if git diff --quiet -- "$f"; then git diff --cached -- "$f"; else git diff -- "$f"; fi
        else
            git diff --no-index -- /dev/null "$f"
        fi
    } | {
        if command -v delta >/dev/null; then
            delta --side-by-side --line-numbers --paging=always --syntax-theme=gruvbox-dark
        else
            sed 's/^/ /' | less -R   # delta missing: plain (already colored by git below)
        fi
    }
}

i=0; n=${#files[@]}
while :; do
    (( i < 0 )) && i=0
    if (( i >= n )); then
        clear
        printf '%s%s  ✓ end of review queue (%d files)%s\n\n' "$b" "$gr" "$n" "$rs"
        printf '  %sCommit them?%s  open lazygit with %sg%s, or %sq%s to quit.\n' "$dim" "$rs" "$ye" "$rs" "$ye" "$rs"
        read -rsn1 k; [ "$k" = "g" ] && exec lazygit; exit 0
    fi
    f="${files[$i]}"

    # per-file stats
    read -r ins del _ < <(git diff --numstat -- "$f" 2>/dev/null)
    [ -z "$ins$del" ] && read -r ins del _ < <(git diff --no-index --numstat -- /dev/null "$f" 2>/dev/null)
    code=$(git status --porcelain -- "$f" | cut -c1-2)
    staged=""; [[ ${code:0:1} =~ [MARC] ]] && staged="${gr} ✓staged${rs}"
    age=""; [ -f "$f" ] && age=$(ago $(( $(date +%s) - $(stat -c %Y "$f" 2>/dev/null||date +%s) )))

    clear
    printf '%s%s 󰈍 REVIEW%s  %s[%d/%d]%s  %s%s%s%s\n' "$b" "$or" "$rs" "$dim" $((i+1)) "$n" "$rs" "$fg" "$f" "$rs" "$staged"
    printf '%s ───────────────────────────────────────────────%s\n' "$dim" "$rs"
    [ -n "$intent" ] && printf '   %sintent%s %s%.70s%s\n' "$pu" "$rs" "$dim" "$intent" "$rs"
    printf '   %s+%s%s %s-%s%s   %schanged %s ago%s\n\n' "$gr" "${ins:-0}" "$rs" "$rd" "${del:-0}" "$rs" "$dim" "${age:-?}" "$rs"
    printf '   %s[enter] view diff →%s\n' "$dim" "$rs"
    read -rsn1 _

    show_diff "$f"

    printf '\n  %sn%snext  %sp%srev  %ss%stage  %so%spen  %sg%sit  %sq%suit > ' \
        "$ye" "$rs" "$ye" "$rs" "$ye" "$rs" "$ye" "$rs" "$ye" "$rs" "$ye" "$rs"
    read -rsn1 k; echo
    case "$k" in
        n|'') i=$((i+1)) ;;
        p)    i=$((i-1)) ;;
        s)    git add -- "$f" ;;
        o)    "${EDITOR:-nvim}" "$f" ;;
        g)    exec lazygit ;;
        q)    exit 0 ;;
    esac
done
