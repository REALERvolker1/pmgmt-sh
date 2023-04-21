# pmgmt-sh

A simple and customizable power management script

# USAGE

```bash
# Customize the script variables
# AC device paths
UPOWER_AC_DEVICE='/org/freedesktop/UPower/devices/ac-device'
SYSFS_AC_DEVICE='/sys/class/power_supply/ac-device'

# configuration
bat_kbd=1
bat_backlight=40
bat_powerprof='balanced'

ac_kbd=3
ac_backlight=80
ac_powerprof='performance'

# Customize actions
if [ "$ac_state" = 'true' ]; then
        light -S "$ac_backlight"
        # the rest of the actions
        # If you have wayland or xorg-specific actions, you can use the following:
        if [ -z "$WAYLAND_DISPLAY" ]; then
            echo 'xorg stuff'
        else
            echo 'wayland stuff'
        fi
# ...
```

```bash
# Finally, symlink the binary and run the command
ln -s "$PWD/pmgmt.sh" "$HOME/.local/bin/pmgmt.sh"
pmgmt.sh

# You might want to add it to your i3 autostarts. To do this, add this in your "$XDG_CONFIG_HOME/i3/config"
exec --no-startup-id pmgmt.sh
```

# Description

pmgmt.sh is a power management script I made, refined, and optimized over many months. I learned a lot over the course of this time period, and I regret not publishing this sooner or keeping many records of my progress with learning dbus.

Currently it only supports AC detection. I have not implemented battery level checks yet, because I do not want to make the performance trade-off. I want it to be simple, lightweight, and easy to debug.
