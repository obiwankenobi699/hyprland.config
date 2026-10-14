#!/usr/bin/env bash
# Emits Waybar JSON when Pacman, AUR, or Flatpak updates are pending.

if ! command -v checkupdates >/dev/null 2>&1 || ! command -v yay >/dev/null 2>&1; then
    printf '%s\n' '{"text":"󰚰 ?","tooltip":"Update status unavailable: checkupdates or yay is missing","class":"unavailable"}'
    exit 0
fi

repo_updates=$(checkupdates 2>/dev/null)
repo_status=$?
aur_updates=$(yay -Qua 2>/dev/null)
aur_status=$?
flatpak_updates=""
flatpak_status=0
if command -v flatpak >/dev/null 2>&1; then
    flatpak_updates=$(flatpak remote-ls --updates --columns=application 2>/dev/null)
    flatpak_status=$?
fi

if { [ "$repo_status" -ne 0 ] && [ "$repo_status" -ne 2 ]; } \
        || [ "$aur_status" -ne 0 ] || [ "$flatpak_status" -ne 0 ]; then
    printf '%s\n' '{"text":"󰚰 ?","tooltip":"Update status unavailable. Try again later.","class":"unavailable"}'
    exit 0
fi

repo_count=$(printf '%s\n' "$repo_updates" | awk 'NF { count++ } END { print count + 0 }')
aur_count=$(printf '%s\n' "$aur_updates" | awk 'NF { count++ } END { print count + 0 }')
flatpak_count=$(printf '%s\n' "$flatpak_updates" | awk 'NF { count++ } END { print count + 0 }')
total=$((repo_count + aur_count + flatpak_count))

summarize_names() {
    local count=$1
    awk -v count="$count" '
        NF && shown < 8 { names = names (names ? ", " : "") $1; shown++ }
        END {
            if (!names) names = "none"
            if (count > shown) names = names ", … +" (count - shown) " more"
            print names
        }
    '
}
repo_names=$(printf '%s\n' "$repo_updates" | summarize_names "$repo_count")
aur_names=$(printf '%s\n' "$aur_updates" | summarize_names "$aur_count")
flatpak_names=$(printf '%s\n' "$flatpak_updates" | summarize_names "$flatpak_count")

if [ "$total" -eq 0 ]; then
    exit 0
fi

printf '{"text":"󰚰 %s","tooltip":"Official (%s): %s\\nAUR (%s): %s\\nFlatpak (%s): %s\\nClick to update everything","class":"pending"}\n' \
    "$total" "$repo_count" "${repo_names:-none}" "$aur_count" "${aur_names:-none}" \
    "$flatpak_count" "${flatpak_names:-none}"
