return function()
    hl.config({
        general = {
            gaps_in = 6,
            gaps_out = 12,
            border_size = 2,
            col = {
                active_border = { colors = { "rgba(b8bb26ff)", "rgba(83a598ff)", "rgba(fe8019ff)" }, angle = 45 },
                inactive_border = "rgba(665c5488)",
            },
            resize_on_border = true,
            extend_border_grab_area = 15,
            -- Master gate for tearing; only matching immediate=true game rules
            -- in rules.lua can actually request tearing.
            allow_tearing = true,
        },
        decoration = {
            rounding = 10,
            active_opacity = 0.90,
            inactive_opacity = 0.90,
            fullscreen_opacity = 1.0,
            dim_inactive = true,
            dim_strength = 0.10,
            shadow = {
                enabled = true,
                range = 4,
                color = "rgba(1a1a1ab3)",
            },
            glow = {
                enabled = true,
                color = "rgba(b8bb26ff)",
                color_inactive = "rgba(665c5488)",
                range = 6,
            },
            blur = { enabled = false },
        },
        animations = { enabled = true },
        dwindle = {
            preserve_split = true,
            split_width_multiplier = 1.3,
            smart_split = true,
            smart_resizing = true,
        },
        master = { new_on_top = true },
        misc = {
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            mouse_move_enables_dpms = true,
            key_press_enables_dpms = true,
            focus_on_activate = true,
        },
        debug = { vfr = true },
    })

    hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "default", style = "loop" })

    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({
        fingers = 3,
        direction = "up",
        action = function()
            hl.exec_cmd("" .. os.getenv("HOME") .. "/.config/hypr/quickshell/modules/overview/toggle.sh")
        end,
    })
end
