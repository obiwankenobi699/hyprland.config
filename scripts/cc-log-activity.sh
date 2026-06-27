#!/usr/bin/env bash
# Claude Code PostToolUse hook: append one line per tool call to the activity log.
# Reads the hook JSON on stdin. Line format:  TIME \t TOOL \t TARGET
log="$HOME/.claude/activity.log"
payload=$(cat)

tool=$(printf '%s' "$payload" | jq -r '.tool_name // "?"')
target=$(printf '%s' "$payload" | jq -r '
    .tool_input.file_path
    // .tool_input.path
    // .tool_input.notebook_path
    // .tool_input.pattern
    // .tool_input.command
    // .tool_input.url
    // .tool_input.description
    // "" ' 2>/dev/null)

# shorten $HOME -> ~ and clamp length
target="${target/#$HOME/\~}"
printf '%s\t%s\t%s\n' "$(date +%H:%M:%S)" "$tool" "${target:0:74}" >> "$log"

# keep the log bounded (last 800 lines)
if [ "$(wc -l < "$log" 2>/dev/null || echo 0)" -gt 1000 ]; then
    tail -n 800 "$log" > "$log.tmp" && mv "$log.tmp" "$log"
fi
exit 0
