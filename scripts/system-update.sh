#!/usr/bin/env bash
# One interactive, full-system update path for Pacman, AUR, and Flatpak.

set -uo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-maintenance"
mkdir -p "$state_dir"
log_file="$state_dir/update-$(date +%Y%m%d-%H%M%S).log"
started=0
completed=0

exec 9>"$state_dir/update.lock"
if ! flock -n 9; then
    printf 'Another system update is already running.\n'
    exit 1
fi

finish() {
    local status=$?
    if [ "$status" -eq 0 ] && [ "$completed" -eq 1 ]; then
        command -v notify-send >/dev/null 2>&1 \
            && notify-send 'System maintenance complete' 'Pacman, AUR, and available Flatpak updates are finished.'
    elif [ "$started" -eq 1 ]; then
        command -v notify-send >/dev/null 2>&1 \
            && notify-send -u critical 'System maintenance stopped' "See $log_file"
    fi
    command -v pkill >/dev/null 2>&1 && pkill -RTMIN+10 waybar 2>/dev/null || true
    printf '\nLog: %s\n' "$log_file"
}
trap finish EXIT

printf '\033[1;38;2;254;128;25mSystem maintenance\033[0m\n'
printf 'Full upgrade only: official repositories + AUR, then optional Flatpak.\n\n'

if ! command -v yay >/dev/null 2>&1; then
    printf 'yay is required for the combined Pacman/AUR upgrade.\n'
    exit 1
fi

if ! curl -fsSI --connect-timeout 5 https://archlinux.org/ >/dev/null 2>&1; then
    printf 'No network connection to archlinux.org. Nothing was changed.\n'
    exit 1
fi

printf '\033[1mRecent Arch Linux news\033[0m\n'
yay -Pw 2>/dev/null || printf 'News could not be fetched; continuing is still possible.\n'
printf '\nContinue with the full upgrade? [Y/n] '
read -r answer
case ${answer:-y} in
    y|Y|yes|YES) ;;
    *) printf 'Cancelled.\n'; exit 0 ;;
esac

printf '\n\033[1m1/4 Pacman + AUR\033[0m\n'
# yay delegates repository packages to pacman. -Syu avoids partial upgrades;
# --devel also checks installed VCS packages such as *-git packages.
started=1
if command -v script >/dev/null 2>&1; then
    script --quiet --flush --return --command 'yay -Syu --devel' "$log_file"
    upgrade_status=$?
else
    yay -Syu --devel
    upgrade_status=$?
fi
if [ "$upgrade_status" -ne 0 ]; then
    printf '\nThe package upgrade failed; cleanup was skipped.\n'
    exit 1
fi

printf '\n\033[1m2/4 Flatpak\033[0m\n'
if command -v flatpak >/dev/null 2>&1; then
    if ! flatpak update; then
        printf '\nFlatpak update failed; maintenance stopped before cleanup.\n'
        exit 1
    fi
    flatpak uninstall --unused || printf 'Flatpak unused-runtime cleanup was skipped.\n'
else
    printf 'Flatpak is not installed; skipped. The updater will include it automatically if installed later.\n'
fi

printf '\n\033[1m3/4 Safe cleanup\033[0m\n'
if command -v paccache >/dev/null 2>&1; then
    sudo paccache -r -k 2
    sudo paccache -ruk0
else
    printf 'paccache is unavailable; install pacman-contrib to manage the package cache.\n'
fi

printf '\n\033[1m4/4 Checks requiring review\033[0m\n'
orphans=$(pacman -Qdtq 2>/dev/null || true)
if [ -n "$orphans" ]; then
    printf 'Potential orphan packages (not removed automatically):\n%s\n' "$orphans"
else
    printf 'No orphan packages.\n'
fi

pacnew_files=$(pacdiff -o 2>/dev/null || true)
if [ -n "$pacnew_files" ]; then
    printf '\nConfiguration files need manual review with sudo pacdiff:\n%s\n' "$pacnew_files"
else
    printf 'No .pacnew/.pacsave files found.\n'
fi

if command -v checkrebuild >/dev/null 2>&1; then
    checkrebuild || true
else
    printf 'Shared-library rebuild check skipped; optional package: rebuild-detector.\n'
fi

printf '\nSystem maintenance completed successfully.\n'
completed=1
