#!/usr/bin/bash
# script by vlk
# vim:ft=sh

set -eu

LOCK_COMMAND='vlkexec --lock 1'

UPOWER_AC_DEVICE='/org/freedesktop/UPower/devices/line_power_ACAD'
SYSFS_AC_DEVICE='/sys/class/power_supply/ACAD/online'

bat_kbd=1
bat_backlight=40
bat_powerprof='balanced'

ac_kbd=3
ac_backlight=80
ac_powerprof='performance'

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
    if [ "$1" = 'true' ]; then
        light -Srs "sysfs/leds/asus::kbd_backlight" "$ac_kbd"
        light -S "$ac_backlight"
        powerprofilesctl set "$ac_powerprof"
        asusctl bios -O "true"
        #if [ -z "$WAYLAND_DISPLAY" ]; then
        #fi

    elif [ "$1" = 'false' ]; then
        light -Srs "sysfs/leds/asus::kbd_backlight" "$bat_kbd"
        light -S "$bat_backlight"
        powerprofilesctl set "$bat_powerprof"
        asusctl bios -O "false"
        #if [ -z "$WAYLAND_DISPLAY" ]; then
        #fi
    fi
}

ac_monitor () {
    #gdbus monitor -y -d org.freedesktop.UPower --object-path "" | grep --line-buffered -Po "'Online':\s+<\K[^>]*" | while read -r line; do
    dbus-monitor --system "type='signal',sender='org.freedesktop.UPower',path='$UPOWER_AC_DEVICE',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" |& grep --line-buffered -oP 'boolean \K.*$' | while read -r line; do
        ac_command_center "$line"
    done
}

case "$(cat "$SYSFS_AC_DEVICE")" in
    1)
        ac_command_center 'true'
    ;; 0)
        ac_command_center 'false'
    ;; *)
        echo "ERROR: Failed to get current AC state"
        exit 1
    ;;
esac

ac_monitor

wait

# for battery, do gdbus monitor --system --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower/devices/DisplayDevice
# receives:
#   /org/freedesktop/UPower/devices/DisplayDevice: org.freedesktop.DBus.Properties.PropertiesChanged ('org.freedesktop.UPower.Device', {'UpdateTime': <uint64 1673888959>, 'Percentage': <98.0>, 'TimeToEmpty': <int64 13045>, 'EnergyRate': <19.358595000000001>, 'Energy': <70.152998999999994>}, @as [])
