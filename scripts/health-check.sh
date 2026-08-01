#!/usr/bin/env bash
# health-check.sh — quick status sweep of the Hyprland desktop.
#
# Read-only: it reports, it never changes anything. Covers config validity,
# the Lua config, autostart daemons, monitor resolutions, the dpms-wake options, and the
# repo's working-tree state. Run it after a reload or when something feels off.
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
check_proc "awww-daemon (wallpaper)" -x awww-daemon
check_proc "swaync (notifications)" -x swaync
check_proc "nm-applet (network)"  -x nm-applet
check_proc "xsettingsd"           -x xsettingsd
check_proc "waybar"               -x waybar
if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
    ok "quickshell (overview)"; else bad "quickshell (overview) — not running"; fi
check_proc "hypridle (idle/lock)" -x hypridle
if pgrep -f battery_notify.sh >/dev/null 2>&1; then
    ok "battery-notify poll loop"; else wn "battery-notify poll loop — not running"; fi

# ── 3. monitors ───────────────────────────────────────
head "Monitors"
if command -v hyprctl >/dev/null; then
    while IFS= read -r line; do
        printf '  %s•%s %s\n' "$aq" "$rs" "$line"
    done < <(hyprctl monitors 2>/dev/null | awk '
        /^Monitor/ {name=$2}
        /^\t[0-9]+x[0-9]+@/ {gsub(/^\t/,""); print name": "$0}')
    # flag any monitor whose active mode is not its highest available one
    while read -r mon; do
        cur=$(hyprctl monitors 2>/dev/null | awk -v m="$mon" '
            $0 ~ "Monitor "m" " {f=1} f && /^\t[0-9]+x[0-9]+@/ {print $1; exit}')
        best=$(hyprctl monitors all 2>/dev/null | awk -v m="$mon" '
            $0 ~ "Monitor "m" " {f=1} f && /availableModes/ {print $2; exit}')
        [ -n "$best" ] && [ -n "$cur" ] && [ "${cur%@*}" != "${best%@*}" ] \
            && wn "$mon running ${cur%@*}, native max is ${best%@*}"
    done < <(hyprctl monitors 2>/dev/null | awk '/^Monitor/{print $2}')
else
    bad "cannot query monitors (no hyprctl)"
fi

# ── 4. dpms wake options ──────────────────────────────
head "DPMS wake (screen-won't-relight guard)"
getopt_int() { hyprctl getoption "misc:$1" 2>/dev/null | awk '/^int:/{print $2; exit}'; }
for opt in mouse_move_enables_dpms key_press_enables_dpms; do
    v=$(getopt_int "$opt")
    if [ "$v" = "1" ]; then ok "misc:$opt = true"
    else wn "misc:$opt = ${v:-unset} — input may not wake the display"; fi
done

# ── 5. repo state ─────────────────────────────────────
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
