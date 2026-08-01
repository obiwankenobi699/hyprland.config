return function()
    local function rule(match, effects)
        effects.match = match
        hl.window_rule(effects)
    end

    rule({ class = "^(org.gnome.Nautilus)$" }, { opacity = "0.85 0.85" })
    rule({ class = "^(org.kde.dolphin)$" }, { opacity = "0.9 0.9" })
    rule({ class = "^(kitty)$" }, { opacity = "1.0 0.9" })
    rule({ class = "^(kitty)$" }, { rounding = 10 })
    rule({ class = "^(code-oss)$" }, { opacity = "1.0 1.0" })
    rule({ class = "^(brave-browser)$" }, { opacity = "1.0 1.0" })
    rule({ class = "^(pavucontrol)$" }, { float = true, center = true })
    rule({ class = "^(blueman-manager)$" }, { float = true, center = true })
    rule({ fullscreen = true }, { opacity = "1.0 1.0 1.0 override" })
    rule({ class = "^(qalculate-gtk)$" }, { float = true, center = true, size = { 480, 640 } })
    rule({ title = "^(quickshell-dashboard)$" }, { float = true, center = true, rounding = 20 })
    rule({ class = "^(cc-diffpanel)$" }, { float = true, center = true, size = { "monitor_w * 0.9", "monitor_h * 0.9" } })

    rule({ class = "^(mpv)$" }, { no_auto_hdr = true })
    rule({ class = "^(vlc)$" }, { no_auto_hdr = true })

    -- Tearing is opt-in per game. Hyprland requires the general master gate,
    -- but only these immediate=true rules request tearing for matched windows.
    rule({ class = "^(steam_app_.*)$" }, { immediate = true })
    rule({ class = "^(gamescope)$" }, { immediate = true })
    rule({ class = "^(cs2|csgo_linux64|.*\\.exe)$" }, { immediate = true })
end
