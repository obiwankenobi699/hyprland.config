#!/usr/bin/env bash
# One-time setup for conservative package cleanup and one CPU power manager.

set -euo pipefail

if ! command -v yay >/dev/null 2>&1; then
    printf 'yay is required.\n' >&2
    exit 1
fi

printf 'Configuring yay to check VCS packages and clean successful build directories...\n'
yay -Y --gendb
yay -Y --devel --cleanafter --save

printf '\nEnabling weekly Pacman cache pruning (keeps the latest three versions)...\n'
sudo systemctl enable --now paccache.timer
printf 'Pruning the current cache to two installed versions and no uninstalled versions...\n'
sudo paccache -r -k 2
sudo paccache -ruk0

printf '\nUsing power-profiles-daemon as the only CPU power-policy service...\n'
sudo systemctl disable --now tlp.service tlp-sleep.service 2>/dev/null || true
sudo systemctl disable --now auto-cpufreq.service 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon.service

removals=(battery-notify paru paru-debug yay-debug python-pyamdgpuinfo swaylock-effects-git)
installed=()
for package in "${removals[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 && installed+=("$package")
done
if [ "${#installed[@]}" -gt 0 ]; then
    printf '\nRedundant packages found:\n  %s\n' "${installed[*]}"
    printf 'Remove only these named packages? [y/N] '
    read -r answer
    case ${answer:-n} in
        y|Y|yes|YES) sudo pacman -R -- "${installed[@]}" ;;
        *) printf 'Package removal skipped.\n' ;;
    esac
fi

if [ ! -x /usr/bin/flatpak ] && [ -d /var/lib/flatpak ]; then
    quarantine="$HOME/.local/share/flatpak-system-quarantine-$(date +%Y%m%d)"
    printf '\nAn unused system Flatpak tree is using: '
    du -sh /var/lib/flatpak 2>/dev/null | awk '{ print $1 }'
    find /var/lib/flatpak/app -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null || true
    printf 'Move it to this recoverable quarantine on your home filesystem?\n  %s\n[y/N] ' "$quarantine"
    read -r answer
    case ${answer:-n} in
        y|Y|yes|YES)
            if [ -e "$quarantine" ]; then
                printf 'Quarantine destination already exists; Flatpak data was not moved.\n' >&2
            else
                sudo mv /var/lib/flatpak "$quarantine"
                sudo chown -R "$USER:$(id -gn)" "$quarantine"
                printf 'Flatpak data quarantined. Delete it later only after confirming nothing is missed.\n'
            fi
            ;;
        *) printf 'Flatpak quarantine skipped.\n' ;;
    esac
fi

printf '\nMaintenance setup complete. Run system updates with:\n  %s/.config/hypr/scripts/system-update.sh\n' "$HOME"
