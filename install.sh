#!/bin/bash
#
# Manual installer for Laptop Lid Control.
# Installs missing dependencies and copies files into place.
# For a packaged installation use the generated .deb instead.

set -e

echo "Installing Laptop Lid Control..."

# --- Dependency check ------------------------------------------------------
NEEDED=()
command -v zenity >/dev/null 2>&1 || NEEDED+=("zenity")
command -v pkexec >/dev/null 2>&1 || NEEDED+=("policykit-1")
command -v systemctl >/dev/null 2>&1 || NEEDED+=("systemd")
command -v xdotool >/dev/null 2>&1 || NEEDED+=("xdotool")

if [ ${#NEEDED[@]} -gt 0 ]; then
    echo "Installing missing dependencies: ${NEEDED[*]}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y "${NEEDED[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "${NEEDED[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm "${NEEDED[@]}"
    else
        echo "No supported package manager found. Please install manually: ${NEEDED[*]}"
        exit 1
    fi
fi

# --- Install files ---------------------------------------------------------
sudo install -Dm755 lid-control.sh /usr/local/bin/lid-control.sh

mkdir -p ~/.local/share/applications
install -Dm644 lid-control.desktop ~/.local/share/applications/lid-control.desktop

echo "✅ Installed successfully!"
echo ""
echo "You can find it in the application menu by searching 'Laptop Lid Control'"
echo "or run directly: lid-control.sh"
