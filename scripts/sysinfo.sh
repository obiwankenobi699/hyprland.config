#!/usr/bin/env bash
# Emit one JSON line of system stats for the Quickshell dashboard:
#   {"cpu":N,"ram":N,"temp":N,"batt":N,"charging":bool}
# Lightweight: reads /proc and /sys, no external monitors.

# ── CPU % (delta over a short sample) ──
read -r _ a b c idle1 rest < /proc/stat
t1=$((a + b + c + idle1)); i1=$idle1
sleep 0.2
read -r _ a b c idle2 rest < /proc/stat
t2=$((a + b + c + idle2)); i2=$idle2
dt=$((t2 - t1)); di=$((i2 - i1))
cpu=0; [ "$dt" -gt 0 ] && cpu=$(( (100 * (dt - di)) / dt ))

# ── RAM % used ──
ram=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)

# ── Temp (CPU package, °C) ──
temp=0
for z in /sys/class/hwmon/hwmon*/temp1_input; do
    name=$(cat "$(dirname "$z")/name" 2>/dev/null)
    if [ "$name" = "coretemp" ] || [ "$name" = "k10temp" ]; then
        temp=$(( $(cat "$z" 2>/dev/null || echo 0) / 1000 )); break
    fi
done

# ── Battery ──
batt=0; charging=false
bd=$(echo /sys/class/power_supply/BAT*)
if [ -d "$bd" ]; then
    batt=$(cat "$bd/capacity" 2>/dev/null || echo 0)
    [ "$(cat "$bd/status" 2>/dev/null)" = "Charging" ] && charging=true
fi

# ── Disk % used (root) ──
disk=$(df -P / | awk 'NR==2{gsub(/%/,"",$5); print $5}')

# ── Uptime (short) ──
up=$(awk '{s=$1} END{d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60);
    if(d>0) printf "%dd %dh", d, h; else if(h>0) printf "%dh %dm", h, m; else printf "%dm", m}' /proc/uptime)

printf '{"cpu":%d,"ram":%d,"temp":%d,"batt":%d,"charging":%s,"disk":%d,"up":"%s"}\n' \
    "$cpu" "$ram" "$temp" "$batt" "$charging" "$disk" "$up"
