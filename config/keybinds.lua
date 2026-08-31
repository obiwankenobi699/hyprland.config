return function(home, programs)
    local main_mod = "SUPER"
    local exec = function(command)
        return hl.dsp.exec_cmd(command)
    end
    local bind = function(keys, dispatcher, flags)
        hl.bind(main_mod .. " + " .. keys, dispatcher, flags)
    end

    bind("T", exec(programs.terminal))
    bind("R", exec(programs.menu))
    bind("E", exec(programs.file_manager))
    bind("B", exec(programs.browser))
    bind("S", exec(programs.screenshot))
    bind("N", exec("swaync-client -t"))
    hl.bind(main_mod .. " + SHIFT + N", exec("swaync-client -d"))
    bind("W", exec("waypaper"))
    hl.bind(main_mod .. " + SHIFT + W", exec(home .. "/.config/hypr/scripts/lock-wallpaper-select.sh"))

    bind("Q", hl.dsp.window.close())
    bind("F", hl.dsp.window.fullscreen({ action = "toggle" }))
    bind("P", hl.dsp.window.float({ action = "toggle" }))
    bind("Return", exec(programs.terminal))
    bind("Space", hl.dsp.window.float({ action = "toggle" }))

    for key, direction in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
        bind(key, hl.dsp.focus({ direction = direction }))
    end

    for key, direction in pairs({ H = "l", L = "r", K = "u", J = "d" }) do
        hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
    end

    for key, delta in pairs({ H = { x = -40, y = 0 }, L = { x = 40, y = 0 }, K = { x = 0, y = -40 }, J = { x = 0, y = 40 } }) do
        hl.bind(main_mod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = delta.x, y = delta.y, relative = true }), { repeating = true })
    end

    for key, delta in pairs({ H = { x = -10, y = 0 }, L = { x = 10, y = 0 }, K = { x = 0, y = -10 }, J = { x = 0, y = 10 } }) do
        hl.bind(main_mod .. " + ALT + " .. key, hl.dsp.window.resize({ x = delta.x, y = delta.y, relative = true }), { repeating = true })
    end

    for i = 1, 10 do
        local key = i == 10 and "0" or tostring(i)
        bind(key, hl.dsp.focus({ workspace = tostring(i) }))
        hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
    end

    local media = {
        ["XF86AudioRaiseVolume"] = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
        ["XF86AudioLowerVolume"] = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
        ["XF86AudioMute"] = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        ["XF86MonBrightnessUp"] = "brightnessctl set 5%+",
        ["XF86MonBrightnessDown"] = "brightnessctl set 5%-",
    }
    for key, command in pairs(media) do
        hl.bind(key, exec(command), { repeating = true })
    end

    hl.bind(main_mod .. " + SHIFT + S", exec("grimblast copy area"))
    hl.bind(main_mod .. " + CTRL + S", exec("grimblast save screen"))
    bind("O", exec("wlr-randr"))
    bind("L", exec(home .. "/.config/hypr/scripts/lock-screen.sh"))
    hl.bind(main_mod .. " + ESCAPE", exec("hyprlock"))
    hl.bind(main_mod .. " + SHIFT + ESCAPE", exec("wlogout"))
    hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exit())

    bind("D", exec("qs ipc call dashboard toggle"))
    bind("C", exec("kitty --class cheatsheet -e nvim +HyprCheat"))
    hl.bind(main_mod .. " + SHIFT + P", exec(home .. "/.config/hypr/scripts/toggle-profile.sh"))
    hl.bind(main_mod .. " + ALT + P", exec(home .. "/.config/hypr/scripts/toggle-profile.sh"))
    hl.bind(main_mod .. " + CTRL + 1", exec(home .. "/.config/hypr/scripts/display-mode.sh standard"))
    hl.bind(main_mod .. " + CTRL + 2", exec(home .. "/.config/hypr/scripts/display-mode.sh bw"))
    hl.bind(main_mod .. " + SHIFT + M", exec(home .. "/.config/hypr/scripts/display-mode.sh menu"))
    hl.bind(main_mod .. " + SHIFT + F", exec(home .. "/.config/hypr/scripts/fan-max.sh"))
    hl.bind(main_mod .. " + SHIFT + A", exec("kitty -o background_opacity=1.0 --class cc-monitor -e " .. home .. "/.config/hypr/scripts/cc-monitor.sh"))
    hl.bind(main_mod .. " + SHIFT + G", exec(home .. "/.config/hypr/scripts/cc-diffpanel.sh"))
    hl.bind(main_mod .. " + SHIFT + D", exec("kitty -o background_opacity=1.0 -e " .. home .. "/.config/hypr/scripts/cc-tmux.sh"))
    hl.bind(main_mod .. " + TAB", exec(home .. "/.config/hypr/quickshell/modules/overview/toggle.sh"))
    hl.bind("XF86Calculator", exec("qalculate-gtk"))
    hl.bind("Insert", hl.dsp.window.float({ action = "toggle" }))
    hl.bind("XF86Launch2", exec("hp-manager"))

    hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
end
