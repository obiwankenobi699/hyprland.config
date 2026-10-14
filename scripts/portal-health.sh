#!/usr/bin/env bash
# Check and repair the Hyprland portal stack used by screen sharing and
# KDE Connect remote mouse/presentation input.

set -u

mode=${1:---repair}
portal_path=/org/freedesktop/portal/desktop

probe_interface() {
    local bus_name=$1 interface=$2
    timeout 4s busctl --user introspect \
        "$bus_name" "$portal_path" "$interface" >/dev/null 2>&1
}

portal_stack_healthy() {
    probe_interface \
        org.freedesktop.portal.Desktop \
        org.freedesktop.portal.RemoteDesktop \
        && probe_interface \
            org.freedesktop.impl.portal.desktop.hypr_kdeconnect \
            org.freedesktop.impl.portal.RemoteDesktop \
        && probe_interface \
            org.freedesktop.impl.portal.desktop.hyprland \
            org.freedesktop.impl.portal.ScreenCast
}

refresh_portals() {
    systemctl --user restart hypr-kdeconnect-portal.service \
        xdg-desktop-portal-hyprland.service
    systemctl --user restart xdg-desktop-portal.service
}

case "$mode" in
    --check)
        portal_stack_healthy
        ;;
    --refresh)
        refresh_portals
        portal_stack_healthy
        ;;
    --repair)
        if portal_stack_healthy; then
            exit 0
        fi
        printf '%s\n' "Portal health check failed; refreshing portal backends." >&2
        refresh_portals
        portal_stack_healthy
        ;;
    *)
        printf 'Usage: %s [--check|--repair|--refresh]\n' "$0" >&2
        exit 2
        ;;
esac
