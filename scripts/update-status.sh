#!/usr/bin/env bash
# Emits Waybar JSON when system or AUR updates are pending.

if ! command -v checkupdates >/dev/null 2>&1 || ! command -v yay >/dev/null 2>&1; then
    printf '%s\n' '{"text":"󰚰 ?","tooltip":"Update status unavailable: checkupdates or yay is missing","class":"unavailable"}'
    exit 0
fi

repo_updates=$(checkupdates 2>/dev/null)
repo_status=$?
aur_updates=$(yay -Qua 2>/dev/null)
aur_status=$?

if [ "$repo_status" -ne 0 ] && [ "$repo_status" -ne 2 ] || [ "$aur_status" -ne 0 ]; then
    printf '%s\n' '{"text":"󰚰 ?","tooltip":"Update status unavailable. Try again later.","class":"unavailable"}'
    exit 0
fi

repo_names=$(printf '%s\n' "$repo_updates" | awk 'NF { print $1 }' | paste -sd ',' - | sed 's/,/, /g')
aur_names=$(printf '%s\n' "$aur_updates" | awk 'NF { print $1 }' | paste -sd ',' - | sed 's/,/, /g')
repo_count=$(printf '%s\n' "$repo_updates" | awk 'NF { count++ } END { print count + 0 }')
aur_count=$(printf '%s\n' "$aur_updates" | awk 'NF { count++ } END { print count + 0 }')
total=$((repo_count + aur_count))

if [ "$total" -eq 0 ]; then
    exit 0
fi

printf '{"text":"󰚰 %s","tooltip":"Official (%s): %s\\nAUR (%s): %s\\nRun: yay -Syu","class":"pending"}\n' \
    "$total" "$repo_count" "$repo_names" "$aur_count" "$aur_names"
