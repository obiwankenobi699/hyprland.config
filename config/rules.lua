return function()
    local function rule(match, effects)
        effects.match = match
        hl.window_rule(effects)
    end

    -- Keep client-requested maximize events from hiding the rest of the tiling tree.
    -- Explicit compositor actions such as SUPER+F still work normally.
    rule({ class = ".*" }, { suppress_event = "maximize" })

    rule({ class = "^(org.gnome.Nautilus)$" }, { opacity = "0.85 0.85" })
    rule({ class = "^(org.kde.dolphin)$" }, { opacity = "0.9 0.9" })
    rule({ class = "^(kitty)$" }, { opacity = "1.0 0.9" })
    rule({ class = "^(kitty)$" }, { rounding = 10 })
    rule({ class = "^(code-oss)$" }, { opacity = "1.0 1.0" })
    rule({ class = "^(brave-browser)$" }, { opacity = "1.0 1.0" })
    rule({ class = "^(pavucontrol)$" }, { float = true, center = true })
    rule({ class = "^(blueman-manager)$" }, { float = true, center = true })
    rule({ class = "^(xdg-desktop-portal-gtk|xdg-desktop-portal-kde|org.kde.kdialog)$" }, {
        float = true,
        center = true,
        size = { 960, 640 },
    })
    rule({ class = "^(polkit-gnome-authentication-agent-1|org.kde.polkit-kde-authentication-agent-1)$" }, {
        float = true,
        center = true,
        stay_focused = true,
    })
    rule({ title = "^[Pp]icture[- ]in[- ][Pp]icture$" }, {
        float = true,
        pin = true,
        keep_aspect_ratio = true,
        no_initial_focus = true,
        no_shadow = true,
        size = { "monitor_w * 0.28", "monitor_h * 0.28" },
        move = { "monitor_w * 0.70", "monitor_h * 0.66" },
    })
    rule({ fullscreen = true }, { opacity = "1.0 1.0 1.0 override" })
    rule({ class = "^(qalculate-gtk)$" }, { float = true, center = true, size = { 480, 640 } })
    rule({ title = "^(quickshell-dashboard)$" }, {
        float = true,
        center = true,
        rounding = 18,
        size = { 1480, 820 },
        opacity = "1.0 override 1.0 override 1.0 override",
        opaque = true,
        stay_focused = true,
    })
    rule({ class = "^(cc-diffpanel)$" }, { float = true, center = true, size = { "monitor_w * 0.9", "monitor_h * 0.9" } })

    rule({ class = "^(mpv)$" }, { no_auto_hdr = true })
    rule({ class = "^(vlc)$" }, { no_auto_hdr = true })

    -- Tearing is opt-in per game. Hyprland requires the general master gate,
    -- but only these immediate=true rules request tearing for matched windows.
    rule({ class = "^(steam_app_.*)$" }, { immediate = true })
    rule({ class = "^(gamescope)$" }, { immediate = true })
    rule({ class = "^(cs2|csgo_linux64|.*\\.exe)$" }, { immediate = true })
end
