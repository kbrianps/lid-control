#!/bin/bash

CONF_DIR="/etc/systemd/logind.conf.d"
CONF_FILE="$CONF_DIR/lid-control.conf"

get_current() {
    local val=""
    val=$(systemd-analyze cat-config systemd/logind.conf 2>/dev/null \
        | grep "^HandleLidSwitch=" \
        | grep -v "ExternalPower\|Docked" \
        | tail -1 \
        | cut -d= -f2 \
        | tr -d '[:space:]')
    echo "${val:-unknown}"
}

CURRENT=$(get_current)

is() { [ "$CURRENT" = "$1" ] && echo TRUE || echo FALSE; }

ICON=/usr/share/icons/hicolor/scalable/apps/lid-control.svg
[ -f "$ICON" ] || ICON=lid-control

# Rebrand the zenity window so the dock can match it to lid-control.desktop
# (zenity sets WM_CLASS=zenity by default, so without this the dock falls
# back to a generic icon instead of using ours).
fix_wmclass() {
    command -v xdotool >/dev/null 2>&1 || return
    local title="$1" wid=""
    for _ in $(seq 1 20); do
        wid=$(xdotool search --name "^${title}$" 2>/dev/null | head -1)
        [ -n "$wid" ] && break
        sleep 0.1
    done
    [ -n "$wid" ] && xdotool set_window --class lid-control --classname lid-control "$wid" 2>/dev/null
}

fix_wmclass "Lid Control" &

CHOICE=$(zenity --list \
    --title="Lid Control" \
    --window-icon="$ICON" \
    --text="What to do when the <b>lid is closed</b>?\n" \
    --radiolist \
    --column="" --column="Action" --column="Description" \
    --width=520 --height=440 \
    $(is suspend)   "suspend"   "Suspend the system (saves battery)" \
    $(is ignore)    "ignore"    "Do nothing (keeps running)" \
    $(is lock)      "lock"      "Lock the screen" \
    $(is poweroff)  "poweroff"  "Power off the computer" \
    $(is hibernate) "hibernate" "Hibernate (saves state to disk)" \
    2>/dev/null)

[ -z "$CHOICE" ] && exit 0

pkexec bash -c "
    mkdir -p '$CONF_DIR'
    printf '[Login]\nHandleLidSwitch=$CHOICE\nHandleLidSwitchExternalPower=$CHOICE\nHandleLidSwitchDocked=$CHOICE\n' > '$CONF_FILE'
    systemctl reload systemd-logind
"

if [ $? -ne 0 ]; then
    zenity --error --title="Error" --window-icon="$ICON" --text="❌ Could not apply the setting.\nMake sure you have administrator privileges." --width=300 2>/dev/null
fi
