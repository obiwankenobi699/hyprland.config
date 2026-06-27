#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook: append each submitted prompt to prompts.log.
# Reads the hook JSON on stdin. Line format:  EPOCH \t PROMPT (newlines collapsed).
# MUST print nothing to stdout (stdout would be injected into Claude's context).
log="$HOME/.claude/prompts.log"
payload=$(cat)

prompt=$(printf '%s' "$payload" | jq -r '.prompt // empty')
[ -z "$prompt" ] && exit 0

# collapse to a single line, squeeze whitespace
line=$(printf '%s' "$prompt" | tr '\n\t' '  ' | tr -s ' ')
printf '%s\t%s\n' "$(date +%s)" "$line" >> "$log"

# keep the log bounded (last 500 lines)
if [ "$(wc -l < "$log" 2>/dev/null || echo 0)" -gt 700 ]; then
    tail -n 500 "$log" > "$log.tmp" && mv "$log.tmp" "$log"
fi
exit 0
