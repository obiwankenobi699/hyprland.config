local home = os.getenv("HOME")

local programs = {
    terminal = "kitty",
    file_manager = "dolphin",
    menu = "wofi --conf " .. home .. "/.config/hypr/wofi/config/config --style " .. home .. "/.config/hypr/wofi/style.css --show drun",
    browser = "zen-browser",
    screenshot = "grimblast copysave area " .. home .. "/Pictures/screenshot/$(date +'%Y-%m-%d_%H-%M-%S_grim.png')",
}

require("config.environment")()
require("config.monitors")()
require("config.appearance")()
require("config.rules")()
require("config.autostart")(home)
require("config.keybinds")(home, programs)
