#!/usr/bin/env bash
# wofi overlay: search past Claude prompts (newest first, de-duped) and copy the
# chosen one to the clipboard so you can paste it back. Bound to SUPER+SHIFT+R.
log="$HOME/.claude/prompts.log"

if [ ! -s "$log" ]; then
    notify-send "󰚩 Claude" "No prompt history yet."
    exit 0
fi

# newest first, drop the epoch column, keep first occurrence of each prompt
sel=$(tac "$log" | cut -f2- | awk 'length && !seen[$0]++' \
    | wofi --dmenu --insensitive --prompt "Prompt history" \
           --width 820 --height 520)

[ -z "$sel" ] && exit 0
printf '%s' "$sel" | wl-copy
notify-send "󰚩 Claude" "Prompt copied — paste with Ctrl+V."
