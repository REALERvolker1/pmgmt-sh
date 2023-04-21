#!/usr/bin/bash
# script by vlk
# vim:ft=sh

LOCK_COMMAND="vlkexec --lock 1"

BAT_CRITICAL=69

bat_backlight=40
bat_kbd=1
bat_powerprof='balanced'

bat_high=true
is_ac=true

program_name="${0##*/}"
program_id="$$"
pids="$(pidof -x "$program_name")"

if [ "$(printf '%s\n' "$pids" | tr ' ' '\n' | wc -l)" -gt 1 ]; then
    for i in $pids; do
        [ "$i" = "$program_id" ] && continue
        kill "$i" && printf "%s is already running. Killed %s\n" "$program_name" "$i"
    done
fi

ac_command_center () {
    echo "$1"
    killall xidlehook 2> /dev/null
    if [ "$1" = 'true' ]; then
        light -Srs "sysfs/leds/asus::kbd_backlight" 3
        light -S 75
        powerprofilesctl set performance
        asusctl bios -O "true"
        if [ -z "$WAYLAND_DISPLAY" ]; then
            xidlehook --not-when-audio --not-when-fullscreen --detect-sleep \
                --timer 600 "light -S 40" "light -I" \
                --timer 120 "$LOCK_COMMAND" "light -I" &
        fi
    elif [ "$1" = 'false' ]; then
        light -Srs "sysfs/leds/asus::kbd_backlight" "$bat_kbd"
        light -S "$bat_backlight"
        powerprofilesctl set "$bat_powerprof"
        asusctl bios -O "false"
        if [ -z "$WAYLAND_DISPLAY" ]; then
            xidlehook --not-when-audio --not-when-fullscreen --detect-sleep \
                --timer 120 "light -S 20" "light -I" \
                --timer 120 "$LOCK_COMMAND" "light -I" \
                --timer 60 "systemctl suspend" "light -I" &
        fi
    fi
}

ac_monitor () {
    #gdbus monitor -y -d org.freedesktop.UPower --object-path "/org/freedesktop/UPower/devices/line_power_ACAD" | grep --line-buffered -Po "'Online':\s+<\K[^>]*" | while read -r line; do
    dbus-monitor --system "type='signal',sender='org.freedesktop.UPower',path='/org/freedesktop/UPower/devices/line_power_ACAD',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" |& grep --line-buffered -oP 'boolean \K.*$' | while read -r line; do
        ac_command_center "$line"
    done
}

case "$(cat '/sys/class/power_supply/ACAD/online')" in
    1) ac_command_center "true"
    ;; 0) ac_command_center "false"
    ;; *) echo "ERR"
    ;;
esac

ac_monitor

wait

# for battery, do gdbus monitor --system --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower/devices/DisplayDevice
# receives:
#   /org/freedesktop/UPower/devices/DisplayDevice: org.freedesktop.DBus.Properties.PropertiesChanged ('org.freedesktop.UPower.Device', {'UpdateTime': <uint64 1673888959>, 'Percentage': <98.0>, 'TimeToEmpty': <int64 13045>, 'EnergyRate': <19.358595000000001>, 'Energy': <70.152998999999994>}, @as [])
