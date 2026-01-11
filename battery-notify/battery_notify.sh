#!/bin/bash

# Read battery status
BATTERY_LEVEL=$(acpi -b | grep -P -o '[0-9]+(?=%)')
STATUS=$(acpi -b | awk '{print $3}' | tr -d ',')

# Only notify if discharging and below 18%
if [[ "$STATUS" == "Discharging" ]] && [[ "$BATTERY_LEVEL" -lt 18 ]]; then
    notify-send -u critical -t 10000 "⚠️ Low Battery" "Battery is at ${BATTERY_LEVEL}%"
fi

