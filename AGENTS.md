# Repository Guidelines

## Project Structure & Module Organization

This repository is the source of a Hyprland/Wayland desktop configuration. The active entry point is `hyprland.lua`, which loads modules from `config/` for environment, monitors, autostart, appearance, keybindings, and window rules. Application configurations live in `waybar/`, `kitty/`, `wofi/`, `swaync/`, `btop/`, `yazi/`, `wlogout/`, `Kvantum/`, `fastfetch/`, and `nvim/`. `quickshell/` contains QML modules; `scripts/` contains Bash helpers for desktop and Claude cockpit workflows. Document machine-specific paths and hardware assumptions when changing them.

## Build, Test, and Development Commands

There is no compiled build or automated test suite. Use targeted checks after edits:

- `hyprctl configerrors` — validate the active Hyprland configuration.
- `hyprctl reload` — reload configuration after syntax or keybinding changes.
- `bash -n scripts/<name>.sh` — check Bash syntax without executing a script.
- `jsonlint waybar/config` — validate Waybar’s JSON configuration when available.
- `bash scripts/health-check.sh` — run the read-only desktop, daemon, monitor, and repository health sweep.
- `git diff --check` — catch whitespace errors before committing.

Run scripts in a Hyprland session when they depend on `hyprctl`, D-Bus, Waybar, or desktop services. Review `readme.md` for symlink setup and prerequisites.

## Coding Style & Naming Conventions

Preserve the existing indentation style in each configuration format. Bash scripts should use `#!/usr/bin/env bash`, quote paths and variables, and fail softly for optional services. Name scripts with lowercase names such as `health-check.sh`; use descriptive lowercase configuration filenames. Preserve the Gruvbox palette and existing comments when editing themed files.

## Testing Guidelines

Tests are manual and environment-based. Validate the affected subsystem, then run `scripts/health-check.sh` when changing startup, display, power, or service behavior. For scripts, use `bash -n` and exercise read-only paths before actions that alter hardware or session state.

## Commit & Pull Request Guidelines

Use concise Conventional Commit-style subjects, for example `feat: add fan status indicator`, `fix: correct monitor mode`, or `chore: update theme`. Keep commits focused. Pull requests should explain the user-visible change, list affected configuration areas, mention hardware or package assumptions, include validation commands and results, and attach screenshots for visual changes. Do not commit secrets, personal logs, generated caches, or machine-specific credentials.

## Configuration Safety

Prefer editing repository files rather than generated symlink targets. Check `git diff` before reloading Hyprland, and preserve unrelated working-tree changes. Treat power, fan, display, and autostart edits as hardware-specific; document fallbacks and avoid requiring `sudo` unless installation documentation explicitly calls for it.
