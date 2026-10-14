#!/usr/bin/env bash
# health-check.sh — quick status sweep of the Hyprland desktop.
#
# Read-only: it reports, it never changes anything. Covers config validity,
# the Lua config, autostart daemons, monitor resolutions, DPMS wake options,
# package hygiene, and the repo's working-tree state.
#
#   ~/.config/hypr/scripts/health-check.sh

# ── gruvbox truecolor palette (matches the cc-* tools) ──
gr=$'\033[38;2;184;187;38m'; ye=$'\033[38;2;250;189;47m'; rd=$'\033[38;2;251;73;52m'
aq=$'\033[38;2;131;165;152m'; fg=$'\033[38;2;235;219;178m'; dim=$'\033[38;2;102;92;84m'
or=$'\033[38;2;254;128;25m'; rs=$'\033[0m'; b=$'\033[1m'

pass=0; warn=0; fail=0
ok()   { printf '  %s✓%s %s\n'  "$gr" "$rs" "$1"; pass=$((pass+1)); }
wn()   { printf '  %s⚠%s %s\n'  "$ye" "$rs" "$1"; warn=$((warn+1)); }
bad()  { printf '  %s✗%s %s\n'  "$rd" "$rs" "$1"; fail=$((fail+1)); }
note() { printf '  %s•%s %s\n'  "$aq" "$rs" "$1"; }
head() { printf '\n%s%s── %s ──%s\n' "$b" "$or" "$1" "$rs"; }

HYPR="$HOME/.config/hypr"

# ── 1. config syntax ──────────────────────────────────
head "Config"
if command -v Hyprland >/dev/null; then
    if Hyprland --verify-config -c "$HYPR/hyprland.lua" >/dev/null 2>&1; then
        ok "hyprland.lua parses successfully"
    else
        bad "hyprland.lua failed validation — run: Hyprland --verify-config -c $HYPR/hyprland.lua"
    fi
else
    wn "Hyprland binary not found — skipped Lua validation"
fi
if command -v hyprctl >/dev/null; then
    config_errors=$(hyprctl configerrors 2>/dev/null)
    if [ -z "$config_errors" ] || [ "$config_errors" = "ok" ]; then
        ok "hyprctl configerrors: clean"
    else
        bad "hyprctl configerrors: $config_errors"
    fi
fi

# ── 2. autostart daemons ──────────────────────────────
head "Daemons (from config/autostart.lua)"
check_proc() { # name  pgrep-args...
    local label=$1; shift
    if pgrep "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label — not running"; fi
}
check_optional_proc() { # command label pgrep-args...
    local command=$1 label=$2; shift 2
    if ! command -v "$command" >/dev/null 2>&1; then
        note "$label — not installed (optional)"
    elif pgrep "$@" >/dev/null 2>&1; then
        ok "$label"
    else
        bad "$label — installed but not running"
    fi
}
check_proc "awww-daemon (wallpaper)" -x awww-daemon
check_proc "swaync (notifications)" -x swaync
check_proc "nm-applet (network)"  -x nm-applet
check_proc "Polkit authentication agent" -f '^/usr/lib/polkit-(gnome/)?polkit-.*authentication-agent-1$'
check_optional_proc "xsettingsd" "xsettingsd" -x xsettingsd
check_proc "waybar"               -x waybar
if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
    ok "quickshell (overview)"; else bad "quickshell (overview) — not running"; fi
check_proc "hypridle (idle/lock)" -x hypridle
if command -v busctl >/dev/null 2>&1 \
        && timeout 4s busctl --user introspect \
            org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
            org.freedesktop.portal.RemoteDesktop 2>/dev/null \
            | grep -q CreateSession; then
    ok "KDE Connect RemoteDesktop portal"
else
    wn "KDE Connect RemoteDesktop portal unavailable — run scripts/setup-portal-health.sh"
fi
if systemctl --user is-active --quiet portal-health.timer 2>/dev/null \
        && systemctl --user is-active --quiet portal-refresh.path 2>/dev/null; then
    ok "portal self-healing timer and path"
else
    wn "portal self-healing not enabled — run scripts/setup-portal-health.sh"
fi
if systemctl --user is-active --quiet battery-notify.timer 2>/dev/null; then
    ok "battery-notify timer"
else
    wn "battery-notify timer — not running; run scripts/setup-battery-notify.sh"
fi

# ── 3. monitors ───────────────────────────────────────
head "Monitors"
if command -v hyprctl >/dev/null; then
    while IFS= read -r line; do
        printf '  %s•%s %s\n' "$aq" "$rs" "$line"
    done < <(hyprctl monitors 2>/dev/null | awk '
        /^Monitor/ {name=$2}
        /^\t[0-9]+x[0-9]+@/ {gsub(/^\t/,""); print name": "$0}')
    # Flag any monitor whose active mode is below its best resolution/refresh.
    while read -r mon; do
        cur=$(hyprctl monitors 2>/dev/null | awk -v m="$mon" '
            $0 ~ "Monitor "m" " {f=1} f && /^\t[0-9]+x[0-9]+@/ {print $1; exit}')
        best=$(hyprctl monitors all 2>/dev/null | awk -v m="$mon" '
            $0 ~ "Monitor "m" " {f=1; next}
            f && /^Monitor / {exit}
            f && /availableModes/ {
                for (i=2; i<=NF; i++) {
                    mode=$i
                    sub(/Hz$/, "", mode)
                    split(mode, parts, "@")
                    split(parts[1], size, "x")
                    area=size[1] * size[2]
                    hz=parts[2] + 0
                    if (area > best_area || (area == best_area && hz > best_hz)) {
                        best_area=area
                        best_hz=hz
                        best_mode=mode
                    }
                }
            }
            END {print best_mode}')

        if [ -n "$best" ] && [ -n "$cur" ]; then
            cur_resolution=${cur%@*}
            best_resolution=${best%@*}

            if [ "$cur_resolution" != "$best_resolution" ]; then
                wn "$mon running $cur_resolution, best available is $best_resolution"
            fi
        fi
    done < <(hyprctl monitors 2>/dev/null | awk '/^Monitor/{print $2}')
else
    bad "cannot query monitors (no hyprctl)"
fi

# ── 4. dpms wake options ──────────────────────────────
head "DPMS wake (screen-won't-relight guard)"
getopt_bool() {
    hyprctl getoption "misc:$1" 2>/dev/null | awk '
        /^bool:/ { print $2 == "true" ? 1 : 0; exit }
        /^int:/  { print $2; exit }
    '
}
for opt in mouse_move_enables_dpms key_press_enables_dpms; do
    v=$(getopt_bool "$opt")
    if [ "$v" = "1" ]; then ok "misc:$opt = true"
    else wn "misc:$opt = ${v:-unset} — input may not wake the display"; fi
done

# ── 5. package hygiene ────────────────────────────────
head "Packages"
if command -v pacman >/dev/null 2>&1; then
    if pacman -Dk >/dev/null 2>&1; then
        ok "Pacman database integrity"
    else
        bad "Pacman database integrity check failed — run: pacman -Dk"
    fi

    orphan_count=$(pacman -Qdtq 2>/dev/null | awk 'END { print NR + 0 }')
    foreign_count=$(pacman -Qqm 2>/dev/null | awk 'END { print NR + 0 }')
    if [ "$orphan_count" -eq 0 ]; then
        ok "no orphan packages"
    else
        wn "$orphan_count orphan package(s) — review with: pacman -Qdt"
    fi
    [ "$foreign_count" -eq 0 ] \
        && note "no foreign/AUR packages" \
        || note "$foreign_count foreign/AUR package(s) installed — inventory with: pacman -Qm"

    helper_count=0
    for helper in yay paru; do
        command -v "$helper" >/dev/null 2>&1 && helper_count=$((helper_count+1))
    done
    if [ "$helper_count" -le 1 ]; then
        ok "one AUR helper installed"
    else
        wn "multiple AUR helpers installed — keep one to reduce duplicated caches and workflows"
    fi

    cache_bytes=$(find /var/cache/pacman/pkg -maxdepth 1 -type f -printf '%s\n' 2>/dev/null \
        | awk '{ total += $1 } END { print total + 0 }')
    cache_label=$(numfmt --to=iec-i --suffix=B "$cache_bytes" 2>/dev/null || printf '%s bytes' "$cache_bytes")
    if [ "$cache_bytes" -gt 5368709120 ] && ! systemctl is-enabled --quiet paccache.timer 2>/dev/null; then
        wn "Pacman cache is $cache_label — enable paccache.timer or prune retained versions"
    elif [ "$cache_bytes" -gt 5368709120 ]; then
        note "Pacman cache is $cache_label with automatic pruning enabled"
    else
        ok "Pacman cache is $cache_label"
    fi

    if systemctl is-enabled --quiet paccache.timer 2>/dev/null; then
        ok "paccache.timer enabled"
    else
        wn "paccache.timer disabled — package cache will grow indefinitely"
    fi

    active_policy=""
    enabled_policy=""
    for service in power-profiles-daemon auto-cpufreq tlp; do
        systemctl is-active --quiet "$service" 2>/dev/null && active_policy="$active_policy $service"
        systemctl is-enabled --quiet "$service" 2>/dev/null && enabled_policy="$enabled_policy $service"
    done
    active_count=$(awk '{ print NF }' <<< "$active_policy")
    enabled_count=$(awk '{ print NF }' <<< "$enabled_policy")
    if [ "$active_count" -eq 1 ]; then
        ok "one active CPU power-policy service:$active_policy"
    elif [ "$active_count" -eq 0 ]; then
        wn "no active CPU power-policy service"
    else
        bad "multiple active CPU power-policy services:$active_policy"
    fi
    [ "$enabled_count" -le 1 ] \
        || wn "multiple CPU power-policy services enabled:$enabled_policy"
else
    wn "Pacman not found — skipped package checks"
fi

if ! command -v flatpak >/dev/null 2>&1 && [ -d /var/lib/flatpak ]; then
    flatpak_bytes=$(du -sb /var/lib/flatpak 2>/dev/null | awk '{ print $1 }')
    flatpak_label=$(numfmt --to=iec-i --suffix=B "${flatpak_bytes:-0}" 2>/dev/null || printf '%s bytes' "${flatpak_bytes:-0}")
    wn "Flatpak is not installed but $flatpak_label of system Flatpak data remains"
elif command -v flatpak >/dev/null 2>&1; then
    ok "Flatpak installed; unified updater will include it"
else
    note "Flatpak not installed; unified updater will skip it"
fi

root_usage=$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')
if [ "${root_usage:-100}" -ge 90 ]; then
    bad "root filesystem is ${root_usage}% full"
elif [ "${root_usage:-100}" -ge 80 ]; then
    wn "root filesystem is ${root_usage}% full"
else
    ok "root filesystem is ${root_usage}% full"
fi

# ── 6. repo state ─────────────────────────────────────
head "Repo ($HYPR)"
if git -C "$HYPR" rev-parse >/dev/null 2>&1; then
    dirty=$(git -C "$HYPR" status --porcelain | wc -l)
    ahead=$(git -C "$HYPR" rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
    [ "$dirty" -eq 0 ] && ok "working tree clean" || wn "$dirty uncommitted change(s)"
    [ "$ahead" = "0" ] && ok "in sync with remote" || wn "$ahead commit(s) not pushed"
else
    wn "not a git repo"
fi

# ── summary ───────────────────────────────────────────
printf '\n%s%s━━ %s%d ok%s · %s%d warn%s · %s%d fail%s ━━%s\n' \
    "$b" "$fg" "$gr" "$pass" "$fg" "$ye" "$warn" "$fg" "$rd" "$fail" "$fg" "$rs"
[ "$fail" -gt 0 ] && exit 1 || exit 0
