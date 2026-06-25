#!/usr/bin/env bash
# Waybar JSON: shows a fan icon ONLY when fans are forced to max (nbfc manual);
# emits empty text when on auto so the module stays hidden.
auto=$(nbfc status 2>/dev/null | grep -m1 'Auto Control Enabled' | grep -o 'true\|false')

if [ "$auto" = "false" ]; then
    echo '{"text":"󰈐","tooltip":"Fans forced MAX — click to restore auto","class":"max"}'
else
    echo '{"text":"","tooltip":"","class":"auto"}'
fi
