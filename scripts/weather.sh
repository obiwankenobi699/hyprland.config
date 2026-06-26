#!/usr/bin/env bash
# Emit weather JSON for the dashboard: {"temp":"+30°C","desc":"Partly cloudy"}
# Uses wttr.in (no API key; auto-detects location by IP). Fails soft when offline.

out=$(curl -s --max-time 6 'https://wttr.in/?format=%t|%C' 2>/dev/null)

if [ -z "$out" ] || [[ "$out" == *"Unknown"* ]] || [[ "$out" == *"<"* ]]; then
    echo '{"temp":"—","desc":"unavailable"}'
    exit 0
fi

temp="$(echo "${out%%|*}" | xargs)"
desc="$(echo "${out#*|}" | xargs)"
printf '{"temp":"%s","desc":"%s"}\n' "$temp" "$desc"
