# Hyprland Dotfiles Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Directory Structure](#directory-structure)
3. [Core Components](#core-components)
4. [Application Configurations](#application-configurations)
5. [Execution Flow](#execution-flow)
6. [Configuration Management](#configuration-management)
7. [Installation Guide](#installation-guide)
8. [Troubleshooting](#troubleshooting)

---

## System Overview

### What is This Setup

This is a complete Wayland-based desktop environment configuration centered around Hyprland, a dynamic tiling compositor. The setup includes window management, status bars, notifications, application launchers, and terminal configurations, all managed through a unified Git repository.

### Architecture Model

```
User Login
    |
    v
Display Manager (ly-dm)
    |
    v
Hyprland Compositor
    |
    +---> Reads hyprland.conf
    |
    +---> Sources modular configs
    |     (variables, monitors, keybinds, rules, autostart)
    |
    +---> Launches background services
    |     (waybar, swaync, wallpaper daemon)
    |
    +---> Applications read configs via symlinks
          (kitty, wofi, fastfetch, etc.)
```

### Design Philosophy

This configuration follows a single-source-of-truth approach where all configurations live in one directory (`~/.config/hypr/`) and are version-controlled with Git. Other applications access their configurations through symbolic links, ensuring consistency and easy backup/restore capabilities.

---

## Directory Structure

### Root Configuration Directory

```
~/.config/hypr/
├── .git/                      # Git repository metadata
├── hyprland.conf              # Main Hyprland configuration (entry point)
├── autostart.conf             # Services to launch at startup
├── keybinds.conf              # Keyboard shortcuts
├── monitors.conf              # Display configuration
├── variables.conf             # Environment variables and settings
├── windowrules.conf           # Window-specific rules
├── hyprpaper.conf             # Wallpaper configuration
├── readme.md                  # Documentation
│
├── kitty/                     # Terminal emulator configuration
│   ├── kitty.conf
│   └── style.conf
│
├── fastfetch/                 # System information tool
│   └── config.jsonc
│
├── waybar/                    # Status bar
│   ├── .git/
│   ├── assets/
│   ├── catppuccin/
│   ├── gitmodules/
│   ├── colors.css
│   ├── config.jsonc
│   ├── gitmodules-config.yaml
│   ├── README.md
│   ├── style.css
│   └── wlr.sh
│
├── swaync/                    # Notification center
│   ├── icons/
│   ├── themes/
│   ├── config.json
│   └── style.css
│
├── wofi/                      # Application launcher
│   ├── themes/
│   ├── config.rasi
│   └── config.rasi.save
│
├── wlogout/                   # Logout menu
│   ├── icons/
│   ├── layout_1
│   ├── layout_2
│   ├── style_1.css
│   └── style_2.css
│
└── eww/                       # Widget system
    └── (widget configurations)
```

### Symbolic Link Structure

Applications expect configurations in standard locations, but these are symlinked to the centralized repository:

```
~/.config/kitty/      -> ~/.config/hypr/kitty/
~/.config/fastfetch/  -> ~/.config/hypr/fastfetch/
~/.config/waybar/     -> ~/.config/hypr/waybar/
~/.config/swaync/     -> ~/.config/hypr/swaync/
~/.config/wofi/       -> ~/.config/hypr/wofi/
~/.config/wlogout/    -> ~/.config/hypr/wlogout/
~/.config/eww/        -> ~/.config/hypr/eww/
```

---

## Core Components

### Hyprland Configuration Files

#### hyprland.conf

**Purpose**: Main entry point for Hyprland compositor configuration.

**Function**: This file is read first when Hyprland starts. It sources all other configuration files and sets up the basic environment.

**Key Sections**:

- Source statements for modular configs
- Basic compositor settings
- Plugin loading (if any)

**Example Structure**:
```
source = ~/.config/hypr/variables.conf
source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/keybinds.conf
source = ~/.config/hypr/windowrules.conf
source = ~/.config/hypr/autostart.conf
```

#### variables.conf

**Purpose**: Centralized environment variables and global settings.

**Contains**:

- Environment variables (GTK themes, cursor themes)
- XDG environment settings
- Default applications
- Graphics API settings (Vulkan, OpenGL)
- Input method configuration

**Why Separate**: Keeping variables in one place makes it easy to adjust environment settings without searching through multiple files.

#### monitors.conf

**Purpose**: Display configuration for single or multi-monitor setups.

**Contains**:

- Monitor names and identifiers
- Resolution and refresh rate settings
- Monitor positioning (x, y coordinates)
- Scaling factors
- Primary monitor designation

**Example Configuration**:
```
monitor = eDP-1, 1920x1080@60, 0x0, 1.0
monitor = HDMI-A-1, 1920x1080@60, 1920x0, 1.0
```

#### keybinds.conf

**Purpose**: All keyboard shortcuts and mouse bindings.

**Contains**:

- Application launchers (terminal, browser, file manager)
- Window management (move, resize, focus)
- Workspace switching
- Volume and brightness controls
- Screenshot bindings
- System controls (logout, lock, shutdown)

**Syntax**:
```
bind = MODIFIER, KEY, action, parameters
```

**Example**:
```
bind = SUPER, RETURN, exec, kitty
bind = SUPER, Q, killactive
bind = SUPER, 1, workspace, 1
```

#### windowrules.conf

**Purpose**: Define behavior for specific applications.

**Contains**:

- Floating window rules
- Workspace assignments
- Opacity settings
- Size and position rules
- Focus behavior

**Example**:
```
windowrule = float, pavucontrol
windowrule = workspace 2, firefox
windowrule = opacity 0.9, kitty
```

#### autostart.conf

**Purpose**: Services and applications to launch when Hyprland starts.

**Contains**:

- Status bar (waybar)
- Notification daemon (swaync)
- Wallpaper daemon (hyprpaper or swww)
- Authentication agent
- Network manager applet
- Background services

**Execution Order**: Services listed here start sequentially after Hyprland initializes.

**Example**:
```
exec-once = waybar &
exec-once = swaync &
exec-once = swww-daemon &
exec-once = nm-applet &
```

#### hyprpaper.conf

**Purpose**: Wallpaper configuration for hyprpaper daemon.

**Contains**:

- Image preload declarations
- Monitor-to-wallpaper mappings
- Splash screen settings
- IPC settings

**Note**: Hyprpaper requires images to be preloaded into memory before assignment.

---

## Application Configurations

### Kitty Terminal

**Location**: `~/.config/hypr/kitty/`

**Purpose**: Terminal emulator configuration.

**Files**:

- `kitty.conf`: Main configuration (fonts, behavior, shortcuts)
- `style.conf`: Color scheme and visual styling

**Key Settings**:

- Font family and size
- Color scheme (often Catppuccin)
- Window padding and opacity
- Tab bar configuration
- Keybindings for terminal operations

**Integration**: Kitty is launched via Hyprland keybinds and reads its config through the symlink at `~/.config/kitty/`.

### Fastfetch

**Location**: `~/.config/hypr/fastfetch/`

**Purpose**: System information display tool.

**Files**:

- `config.jsonc`: JSON configuration with comments

**Function**: Displays system information (OS, kernel, CPU, GPU, memory) in ASCII art format. Often run in terminal startup (added to shell rc files).

**Configuration Options**:

- Modules to display
- ASCII art logo
- Color scheme
- Information format

### Waybar

**Location**: `~/.config/hypr/waybar/`

**Purpose**: Status bar for Wayland compositors.

**Files**:

- `config.jsonc`: Module configuration (what to display)
- `style.css`: Visual styling (colors, fonts, spacing)
- `colors.css`: Color definitions
- `wlr.sh`: Workspace indicator script
- `assets/`: Icons and images
- `catppuccin/`: Theme files
- `gitmodules/`: Git submodule configurations

**Modules**:

- Clock and calendar
- CPU, memory, temperature
- Network status
- Battery indicator
- Volume control
- Workspace indicators
- System tray
- Custom scripts

**Execution**: Started by `autostart.conf` and runs continuously in the background.

### SwayNC (Sway Notification Center)

**Location**: `~/.config/hypr/swaync/`

**Purpose**: Notification daemon and control center.

**Files**:

- `config.json`: Notification behavior and settings
- `style.css`: Visual styling
- `icons/`: Notification icons
- `themes/`: Color themes

**Features**:

- Desktop notifications
- Notification history
- Do Not Disturb mode
- Custom notification rules
- Control center panel

**Integration**: Started at login via `autostart.conf` and accessed via keybinds or status bar click.

### Wofi

**Location**: `~/.config/hypr/wofi/`

**Purpose**: Application launcher and dmenu replacement.

**Files**:

- `config.rasi`: Main configuration
- `themes/`: Color themes and styling

**Modes**:

- `drun`: Application launcher (reads .desktop files)
- `run`: Command runner
- `dmenu`: Menu mode for scripts

**Invocation**: Triggered by keybind (usually Super+D or Super+R) defined in `keybinds.conf`.

### Wlogout

**Location**: `~/.config/hypr/wlogout/`

**Purpose**: Logout/shutdown menu.

**Files**:

- `layout_1`, `layout_2`: Button layouts
- `style_1.css`, `style_2.css`: Visual themes
- `icons/`: Action icons (shutdown, reboot, logout, lock)

**Actions**:

- Logout (exit Hyprland)
- Lock screen
- Suspend
- Reboot
- Shutdown

**Invocation**: Triggered by keybind, displays graphical menu with power options.

### Eww (ElKowar's Wacky Widgets)

**Location**: `~/.config/hypr/eww/`

**Purpose**: Custom widget system for creating desktop widgets and bars.

**Capabilities**:

- Custom dashboard
- System monitors
- Calendar widgets
- Music player controls
- Custom bars

**Language**: Uses Yuck (Lisp-like) for widget definitions and Eww's scripting capabilities.

---

## Execution Flow

### System Boot to Desktop

#### Stage 1: System Initialization

```
Power On
    |
    v
BIOS/UEFI
    |
    v
Bootloader (GRUB/systemd-boot)
    |
    v
Linux Kernel loads
    |
    v
systemd init system starts
    |
    v
Display Manager (ly-dm) launches
```

#### Stage 2: User Login

```
Display Manager shows login prompt
    |
    v
User enters credentials
    |
    v
ly-dm validates authentication
    |
    v
ly-dm reads session files from:
    - /usr/share/wayland-sessions/hyprland.desktop
    |
    v
Session file contains:
    Exec=Hyprland
    |
    v
ly-dm executes Hyprland binary
```

#### Stage 3: Hyprland Initialization

```
Hyprland process starts
    |
    v
Reads ~/.config/hypr/hyprland.conf
    |
    v
Processes source directives in order:
    |
    +---> source = variables.conf
    |       (Sets environment variables)
    |
    +---> source = monitors.conf
    |       (Configures displays)
    |
    +---> source = keybinds.conf
    |       (Registers keyboard shortcuts)
    |
    +---> source = windowrules.conf
    |       (Sets window behavior rules)
    |
    +---> source = autostart.conf
          (Launches background services)
```

#### Stage 4: Autostart Execution

```
autostart.conf processes exec-once directives:
    |
    +---> waybar &
    |       (Status bar starts, reads config via symlink)
    |
    +---> swaync &
    |       (Notification daemon starts)
    |
    +---> swww-daemon &
    |       (Wallpaper daemon initializes)
    |
    +---> swww img ~/Pictures/wallpaper/image.jpg
    |       (Wallpaper sets)
    |
    +---> nm-applet &
    |       (Network manager tray icon)
    |
    +---> /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
          (Authentication agent for sudo prompts)
```

#### Stage 5: Ready State

```
Desktop is ready
    |
    +---> Compositor running (Hyprland)
    +---> Status bar visible (Waybar)
    +---> Wallpaper displayed
    +---> Background services active
    +---> Waiting for user input
```

### Application Launch Flow

#### Terminal Launch Example

```
User presses Super+Return
    |
    v
Hyprland detects key combination
    |
    v
Looks up binding in keybinds.conf:
    bind = SUPER, RETURN, exec, kitty
    |
    v
Executes kitty binary
    |
    v
Kitty looks for config at ~/.config/kitty/kitty.conf
    |
    v
Symlink redirects to ~/.config/hypr/kitty/kitty.conf
    |
    v
Kitty reads configuration
    |
    v
Kitty applies settings:
    - Font
    - Colors
    - Opacity
    - Keybinds
    |
    v
Kitty window appears on screen
    |
    v
Hyprland applies window rules from windowrules.conf
    |
    v
Window is ready for user input
```

#### Application Launcher Flow

```
User presses Super+D
    |
    v
Hyprland executes: wofi --show drun
    |
    v
Wofi process starts
    |
    v
Reads config from ~/.config/wofi/ (symlink)
    |
    v
Scans for .desktop files in:
    - /usr/share/applications/
    - ~/.local/share/applications/
    |
    v
Displays application list with search
    |
    v
User selects application (e.g., Firefox)
    |
    v
Wofi executes command from .desktop file:
    Exec=firefox
    |
    v
Firefox launches
    |
    v
Hyprland checks windowrules.conf:
    windowrule = workspace 2, firefox
    |
    v
Moves Firefox to workspace 2
    |
    v
Application is running
```

### Notification Flow

```
Application wants to show notification
    |
    v
Sends D-Bus notification message
    |
    v
SwayNC (notification daemon) receives message
    |
    v
Reads config from ~/.config/swaync/ (symlink)
    |
    v
Checks notification rules:
    - Priority
    - Application-specific settings
    - Do Not Disturb status
    |
    v
If not suppressed, displays notification:
    - Popup on screen (temporary)
    - Adds to notification center (persistent)
    |
    v
User can click to dismiss or open notification center
    |
    v
Notification center shows history with actions
```

---

## Configuration Management

### Why This Structure Works

#### Centralization Benefits

All configurations in one directory provides:

**Version Control**: Single Git repository tracks all changes. You can view history, revert changes, and maintain branches for different setups.

**Backup and Restore**: Backing up `~/.config/hypr/` preserves entire desktop environment. Restoration is copying one directory and creating symlinks.

**Portability**: Clone repository on new machine, create symlinks, and environment is identical.

**Consistency**: Related configurations are co-located. Changing color scheme affects all applications in one place.

#### Symlink Strategy

**Problem**: Applications expect configs in standard locations (`~/.config/appname/`).

**Solution**: Symbolic links redirect reads to centralized location.

**Mechanism**:
```bash
ln -s ~/.config/hypr/kitty ~/.config/kitty
```

This creates a pointer. When kitty reads `~/.config/kitty/kitty.conf`, it actually reads `~/.config/hypr/kitty/kitty.conf`.

**Advantages**:

- Applications work without modification
- Single source of truth maintained
- Changes propagate automatically
- No configuration duplication

### Modular Configuration Pattern

#### Why Split Hyprland Config

Large monolithic configuration files become difficult to maintain. Splitting into focused modules provides:

**Readability**: Each file has single responsibility.

**Maintainability**: Finding and changing specific settings is faster.

**Reusability**: Monitor configs differ between machines, but keybinds might be identical.

**Collaboration**: Multiple people can edit different files without conflicts.

#### Source Directive

Hyprland's `source` directive includes external files at that position:

```
source = ~/.config/hypr/monitors.conf
```

Is equivalent to copying the contents of `monitors.conf` into that location in `hyprland.conf`.

**Order Matters**: Variables must be defined before use. Typical order:

1. variables.conf (defines values)
2. monitors.conf (may use variables)
3. keybinds.conf (references applications)
4. windowrules.conf (defines behaviors)
5. autostart.conf (launches services using above configs)

### Git Integration

#### Repository Structure

```
~/.config/hypr/.git/
```

This directory is a Git repository. All files in `~/.config/hypr/` are tracked.

**Common Git Operations**:

**Check Status**:
```bash
cd ~/.config/hypr
git status
```

**Commit Changes**:
```bash
git add .
git commit -m "Update waybar theme"
```

**View History**:
```bash
git log --oneline
```

**Revert Changes**:
```bash
git checkout -- keybinds.conf
```

**Create Backup Branch**:
```bash
git branch laptop-backup
```

#### Submodules

Some subdirectories (like waybar) may have their own Git repositories:

```
~/.config/hypr/waybar/.git/
```

These are Git submodules, allowing independent version control of components while maintaining parent repository structure.

**Update Submodule**:
```bash
cd ~/.config/hypr/waybar
git pull origin main
```

---

## Installation Guide

### Prerequisites

**Required Packages**:

- Hyprland compositor
- Waybar (status bar)
- Kitty (terminal emulator)
- Wofi (launcher)
- SwayNC (notifications)
- swww (wallpaper daemon)
- ly-dm (display manager)
- polkit-gnome (authentication agent)
- network-manager-applet

**Arch Linux Installation**:
```bash
sudo pacman -S hyprland waybar kitty wofi swaync swww ly polkit-gnome network-manager-applet fastfetch
```

### Fresh Installation

#### Step 1: Clone Repository

```bash
cd ~/.config
git clone <your-repo-url> hypr
```

#### Step 2: Create Symlinks

```bash
# Kitty
rm -rf ~/.config/kitty
ln -s ~/.config/hypr/kitty ~/.config/kitty

# Fastfetch
rm -rf ~/.config/fastfetch
ln -s ~/.config/hypr/fastfetch ~/.config/fastfetch

# Waybar
rm -rf ~/.config/waybar
ln -s ~/.config/hypr/waybar ~/.config/waybar

# SwayNC
rm -rf ~/.config/swaync
ln -s ~/.config/hypr/swaync ~/.config/swaync

# Wofi
rm -rf ~/.config/wofi
ln -s ~/.config/hypr/wofi ~/.config/wofi

# Wlogout
rm -rf ~/.config/wlogout
ln -s ~/.config/hypr/wlogout ~/.config/wlogout

# Eww (if used)
rm -rf ~/.config/eww
ln -s ~/.config/hypr/eww ~/.config/eww
```

#### Step 3: Verify Symlinks

```bash
ls -la ~/.config | grep -E "kitty|waybar|wofi|swaync"
```

Expected output shows arrows pointing to `hypr/` subdirectories.

#### Step 4: Configure Display Manager

Ensure ly-dm is enabled:
```bash
sudo systemctl enable ly.service
sudo systemctl start ly.service
```

#### Step 5: Set Wallpaper

Place wallpaper image:
```bash
mkdir -p ~/Pictures/wallpaper
cp /path/to/image.jpg ~/Pictures/wallpaper/
```

Update wallpaper config:
```bash
# Edit hyprpaper.conf or autostart.conf
# Point to your wallpaper path
```

#### Step 6: Login

Logout of current session, select Hyprland from ly-dm, and login.

### Updating Existing Installation

#### Pull Latest Changes

```bash
cd ~/.config/hypr
git pull origin main
```

#### Restart Components

**Restart Hyprland**:
```
Super+Shift+M (or configured exit bind)
```
Then login again.

**Reload Waybar**:
```bash
killall waybar
waybar &
```

**Reload Notifications**:
```bash
killall swaync
swaync &
```

---

## Troubleshooting

### Hyprland Won't Start

**Symptom**: Black screen after login or immediate logout.

**Diagnosis**:

Check Hyprland logs:
```bash
cat /tmp/hypr/$(ls -t /tmp/hypr | head -1)/hyprland.log
```

**Common Causes**:

**Syntax Error in Config**: Look for error messages referencing line numbers.

**Solution**: Fix syntax in referenced file.

**Missing Dependencies**: Log shows "command not found" errors.

**Solution**: Install missing packages.

**Monitor Configuration**: Invalid monitor name or resolution.

**Solution**: Run `hyprctl monitors` in TTY, correct `monitors.conf`.

### Waybar Not Appearing

**Symptom**: Hyprland starts but no status bar visible.

**Diagnosis**:

Check if running:
```bash
ps aux | grep waybar
```

Check logs:
```bash
waybar --log-level debug
```

**Common Causes**:

**Configuration Error**: Syntax error in `config.jsonc` or `style.css`.

**Solution**: Validate JSON syntax, check CSS syntax.

**Missing Modules**: Waybar module references non-existent script.

**Solution**: Verify script paths, ensure executables exist.

**Font Issues**: Fonts not installed for icons.

**Solution**: Install required fonts (often Nerd Fonts).

### Keybinds Not Working

**Symptom**: Keyboard shortcuts don't trigger actions.

**Diagnosis**:

Check Hyprland log for keybind registration errors.

**Common Causes**:

**Syntax Error**: Incorrect keybind syntax in `keybinds.conf`.

**Solution**: Verify syntax: `bind = MODIFIER, KEY, action, parameters`

**Application Not Installed**: Keybind launches non-existent application.

**Solution**: Install application or update keybind.

**Conflicting Binds**: Same key combination defined multiple times.

**Solution**: Remove or modify duplicate bindings.

### Applications Don't Apply Themes

**Symptom**: Applications use default themes instead of configured ones.

**Diagnosis**:

Check if symlinks exist:
```bash
ls -la ~/.config/kitty
```

Should show symlink arrow, not directory.

**Common Causes**:

**Symlink Not Created**: Application reads from wrong location.

**Solution**: Create symlink as described in Installation Guide.

**Theme Files Missing**: Config references non-existent theme files.

**Solution**: Verify theme files exist in subdirectories.

**Environment Variables**: GTK or Qt theme variables not set.

**Solution**: Check `variables.conf` for theme environment variables.

### Wallpaper Not Loading

**Symptom**: Desktop background is solid color or black.

**Diagnosis**:

Check wallpaper daemon:
```bash
ps aux | grep swww
```

**Common Causes**:

**Daemon Not Running**: Wallpaper daemon didn't start.

**Solution**: Manually start: `swww-daemon &` and `swww img /path/to/image.jpg`

**Image Path Wrong**: Config references non-existent image.

**Solution**: Verify image path, use absolute paths.

**Hyprpaper Issues**: Hyprpaper didn't preload image.

**Solution**: Check hyprpaper.conf syntax, ensure preload line exists.

### Notifications Not Showing

**Symptom**: Applications send notifications but nothing appears.

**Diagnosis**:

Check SwayNC:
```bash
ps aux | grep swaync
```

Test notification:
```bash
notify-send "Test" "This is a test notification"
```

**Common Causes**:

**Daemon Not Running**: SwayNC didn't start.

**Solution**: Start manually: `swaync &`

**Do Not Disturb Enabled**: Notifications suppressed.

**Solution**: Toggle DND mode via keybind or control center.

**Configuration Error**: Syntax error in `config.json`.

**Solution**: Validate JSON syntax, check for missing commas or brackets.

---

## Advanced Topics

### Multi-Monitor Workflow

**Configuration**: Edit `monitors.conf` to define each display.

**Example**:
```
monitor = eDP-1, 1920x1080@60, 0x0, 1.0
monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1.0
```

**Workspace Assignment**: Assign workspaces to specific monitors in `hyprland.conf`.

**Per-Monitor Wallpapers**: Configure different wallpapers in `hyprpaper.conf` or `autostart.conf`.

### Laptop vs Desktop Profiles

**Strategy**: Use Git branches for different machines.

**Laptop Branch**:
```bash
git checkout -b laptop
```

Modify `monitors.conf` for single display, adjust power settings in `variables.conf`.

**Desktop Branch**:
```bash
git checkout -b desktop
```

Configure multiple monitors, remove battery-related waybar modules.

**Switching**:
```bash
git checkout laptop  # or desktop
```

### Custom Scripts Integration

**Location**: Store scripts in `~/.config/hypr/scripts/`.

**Usage**: Reference in keybinds or waybar modules.

**Example Keybind**:
```
bind = SUPER, P, exec, ~/.config/hypr/scripts/screenshot.sh
```

**Example Waybar Module**:
```json
"custom/script": {
    "exec": "~/.config/hypr/scripts/check-updates.sh",
    "interval": 3600
}
```

### Theme Synchronization

**Approach**: Use consistent color schemes across all applications.

**Common Choice**: Catppuccin theme family.

**Files to Coordinate**:

- `waybar/colors.css`
- `kitty/style.conf`
- `swaync/style.css`
- `wofi/themes/`
- GTK theme (in `variables.conf`)

**Tool**: Consider theme generators or dotfile managers for consistency.

---

## Appendix

### File Reference Quick Guide

**Configuration Entry Point**: `hyprland.conf`

**Display Settings**: `monitors.conf`

**Keyboard Shortcuts**: `keybinds.conf`

**Environment Variables**: `variables.conf`

**Window Behavior**: `windowrules.conf`

**Startup Services**: `autostart.conf`

**Terminal**: `kitty/kitty.conf`

**Status Bar**: `waybar/config.jsonc`, `waybar/style.css`

**Notifications**: `swaync/config.json`, `swaync/style.css`

**Launcher**: `wofi/config.rasi`

**Wallpaper**: `hyprpaper.conf` or `autostart.conf` (swww)

### Common Commands

**Reload Hyprland Config**:
```bash
hyprctl reload
```

**List Monitors**:
```bash
hyprctl monitors
```

**List Windows**:
```bash
hyprctl clients
```

**Reload Waybar**:
```bash
killall waybar && waybar &
```

**Test Notification**:
```bash
notify-send "Title" "Message"
```

**Launch Application Manually**:
```bash
kitty
wofi --show drun
```

### Glossary

**Compositor**: Software that manages window rendering and display in Wayland. Combines window manager and display server roles.

**Wayland**: Modern display protocol replacing X11. Defines communication between applications and compositors.

**Symlink**: Symbolic link, a file that points to another file or directory. Applications read symlink target transparently.

**Source Directive**: Hyprland configuration command to include external file contents.

**Autostart**: Applications and services launched automatically when compositor starts.

**Module**: Self-contained configuration component (in Waybar) or config file section.

**IPC**: Inter-Process Communication, mechanism for processes to exchange data. Hyprland exposes IPC for runtime control.

**DPI/Scaling**: Dots Per Inch or scaling factor for high-resolution displays.

**Workspace**: Virtual desktop, separate screen space for organizing windows.

**Keybind**: Keyboard shortcut, combination of modifier keys and regular key triggering action.

**Window Rule**: Configuration that defines specific window behavior based on application or window properties.

---

## Maintenance Checklist

### Regular Tasks

**Weekly**:

- Check for compositor updates
- Test backup and restore procedure
- Review and clean unused configurations

**Monthly**:

- Update themes and color schemes
- Review and optimize startup time
- Clean up old Git commits with squash/rebase

**Quarterly**:

- Document custom scripts and modifications
- Review security of executed scripts
- Update this documentation with new features

### Backup Strategy

**What to Backup**:

- Entire `~/.config/hypr/` directory
- `~/.local/share/applications/` (custom .desktop files)
- `~/.local/bin/` (custom scripts if not in hypr/)

**Backup Methods**:

**Git Remote**: Push to GitHub/GitLab private repository

**External Drive**: Periodic full copy

**Cloud Sync**: Sync repository to cloud storage

**Backup Command**:
```bash
cd ~/.config/hypr
git add .
git commit -m "Backup $(date +%Y-%m-%d)"
git push origin main
```

---

## Conclusion

This configuration represents a complete, maintainable, and portable Wayland desktop environment. The centralized structure with symbolic links ensures consistency while maintaining compatibility with standard application expectations. Version control enables safe experimentation and easy recovery, while modular configuration files keep the system organized and understandable.

The execution flow from login through application launch is transparent and predictable, allowing for easy debugging and customization. Whether deploying on a new machine or maintaining an existing setup, this architecture provides the tools and structure necessary for efficient system management.