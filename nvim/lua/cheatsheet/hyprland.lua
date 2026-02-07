-- Hyprland keybindings organized by category
return {
  {
    title = "Applications",
    badge = "apps",
    items = {
      { "SUPER + T", "Terminal (Kitty)" },
      { "SUPER + B", "Browser (Firefox)" },
      { "SUPER + E", "File Manager" },
      { "SUPER + R", "App Launcher" },
      { "SUPER + S", "Screenshot" },
      { "SUPER + W", "EWW Dashboard" },
    }
  },
  {
    title = "Window Management",
    badge = "windows",
    items = {
      { "SUPER + Q", "Kill window" },
      { "SUPER + F", "Fullscreen" },
      { "SUPER + SPACE", "Toggle floating" },
      { "SUPER + P", "Toggle floating" },
      { "SUPER + M", "Exit Hyprland" },
    }
  },
  {
    title = "Focus",
    badge = "switch",
    items = {
      { "SUPER + ←", "Window left" },
      { "SUPER + →", "Window right" },
      { "SUPER + ↑", "Window up" },
      { "SUPER + ↓", "Window down" },
    }
  },
  {
    title = "Move Windows",
    badge = "move",
    items = {
      { "SUPER+SHIFT+H", "Move left" },
      { "SUPER+SHIFT+L", "Move right" },
      { "SUPER+SHIFT+K", "Move up" },
      { "SUPER+SHIFT+J", "Move down" },
    }
  },
  {
    title = "Resize",
    badge = "resize",
    items = {
      { "SUPER+CTRL+H", "Resize left" },
      { "SUPER+CTRL+L", "Resize right" },
      { "SUPER+CTRL+K", "Resize up" },
      { "SUPER+CTRL+J", "Resize down" },
    }
  },
  {
    title = "Workspaces",
    badge = "workspace",
    items = {
      { "SUPER + 1-9", "Switch workspace" },
      { "SUPER + 0", "Workspace 10" },
      { "SUPER+SHIFT+1-9", "Move to workspace" },
    }
  },
  {
    title = "System",
    badge = "system",
    items = {
      { "Volume Up", "Raise volume" },
      { "Volume Down", "Lower volume" },
      { "Brightness Up", "Increase" },
      { "Brightness Down", "Decrease" },
    }
  },
  {
    title = "Screenshots",
    badge = "capture",
    items = {
      { "SUPER+SHIFT+S", "Copy area" },
      { "SUPER+CTRL+S", "Save full screen" },
    }
  },
  {
    title = "Notifications",
    badge = "notify",
    items = {
      { "SUPER + N", "Toggle notifications" },
      { "SUPER+SHIFT+N", "Dismiss all" },
      { "SUPER + V", "Dashboard" },
    }
  },
  {
    title = "Misc",
    badge = "misc",
    items = {
      { "SUPER + L", "Lock screen" },
      { "SUPER + O", "Display settings" },
      { "SUPER + R", "Reload Hyprland" },
      { "SUPER + C", "This cheatsheet" },
    }
  },
}