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

case "$CURRENT" in
    suspend)   CURRENT_LABEL="Suspend (current)" ;;
    ignore)    CURRENT_LABEL="Do nothing (current)" ;;
    lock)      CURRENT_LABEL="Lock screen (current)" ;;
    poweroff)  CURRENT_LABEL="Power off (current)" ;;
    hibernate) CURRENT_LABEL="Hibernate (current)" ;;
    unknown)   CURRENT_LABEL="Unknown (system default)" ;;
    *)         CURRENT_LABEL="$CURRENT (current)" ;;
esac

is() { [ "$CURRENT" = "$1" ] && echo TRUE || echo FALSE; }

CHOICE=$(zenity --list \
    --title="Laptop Lid Control" \
    --text="What to do when the <b>lid is closed</b>?\n\nCurrent setting: <b>$CURRENT_LABEL</b>" \
    --radiolist \
    --column="" --column="Action" --column="Description" \
    --width=480 --height=340 \
    $(is suspend)   "suspend"   "Suspend the system (saves battery)" \
    $(is ignore)    "ignore"    "Do nothing (keeps running)" \
    $(is lock)      "lock"      "Lock the screen" \
    $(is poweroff)  "poweroff"  "Power off the computer" \
    $(is hibernate) "hibernate" "Hibernate (saves state to disk)" \
    2>/dev/null)

[ -z "$CHOICE" ] && exit 0

pkexec bash -c "
    mkdir -p '$CONF_DIR'
    printf '[Login]\nHandleLidSwitch=$CHOICE\n' > '$CONF_FILE'
    systemctl restart systemd-logind
"

if [ $? -eq 0 ]; then
    case "$CHOICE" in
        suspend)   MSG="Lid set to: Suspend" ;;
        ignore)    MSG="Lid set to: Do nothing" ;;
        lock)      MSG="Lid set to: Lock screen" ;;
        poweroff)  MSG="Lid set to: Power off" ;;
        hibernate) MSG="Lid set to: Hibernate" ;;
    esac
    zenity --info --title="Settings saved" --text="✅ $MSG\n\nThe new setting is already active." --width=300 2>/dev/null
else
    zenity --error --title="Error" --text="❌ Could not apply the setting.\nMake sure you have administrator privileges." --width=300 2>/dev/null
fi
