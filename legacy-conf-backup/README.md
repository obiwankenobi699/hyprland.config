# Archived legacy Hyprland configuration

These files are preserved for rollback/reference only. They are not sourced by
`hyprland.lua` and must not be restored alongside the active Lua configuration.

The active daemon configs remain at the repository root because `hypridle` and
`hyprlock` discover those paths by default.

For rollback testing only, start with:

```sh
Hyprland --config ~/.config/hypr/legacy-conf-backup/hyprland.conf
```
