#!/bin/bash
#
# Manual installer for Lid Control.
# Installs missing dependencies and copies files into place system-wide.
# For a packaged installation use the generated .deb instead.

set -e

echo "Installing Lid Control..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# --- Dependency check ------------------------------------------------------
need_python_gi=0
python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk" \
    >/dev/null 2>&1 || need_python_gi=1

need_pkexec=0
command -v pkexec >/dev/null 2>&1 || need_pkexec=1

need_systemctl=0
command -v systemctl >/dev/null 2>&1 || need_systemctl=1

if [ "$need_python_gi" = "1" ] || [ "$need_pkexec" = "1" ] || [ "$need_systemctl" = "1" ]; then
    echo "Installing missing dependencies..."
    if command -v apt-get >/dev/null 2>&1; then
        PKGS=()
        [ "$need_python_gi" = "1" ] && PKGS+=("python3" "python3-gi" "gir1.2-gtk-3.0")
        [ "$need_pkexec"    = "1" ] && PKGS+=("policykit-1")
        [ "$need_systemctl" = "1" ] && PKGS+=("systemd")
        sudo apt-get update
        sudo apt-get install -y "${PKGS[@]}"
    elif command -v dnf >/dev/null 2>&1; then
        PKGS=()
        [ "$need_python_gi" = "1" ] && PKGS+=("python3" "python3-gobject" "gtk3")
        [ "$need_pkexec"    = "1" ] && PKGS+=("polkit")
        [ "$need_systemctl" = "1" ] && PKGS+=("systemd")
        sudo dnf install -y "${PKGS[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        PKGS=()
        [ "$need_python_gi" = "1" ] && PKGS+=("python" "python-gobject" "gtk3")
        [ "$need_pkexec"    = "1" ] && PKGS+=("polkit")
        [ "$need_systemctl" = "1" ] && PKGS+=("systemd")
        sudo pacman -S --noconfirm "${PKGS[@]}"
    else
        echo "No supported package manager found."
        echo "Please install manually: python3 + PyGObject + GTK3, polkit, systemd."
        exit 1
    fi
fi

# --- Install files (system-wide, matching the .deb layout) -----------------
sudo install -Dm755 lid-control                     /usr/bin/lid-control
sudo install -Dm755 lid-control-apply               /usr/libexec/lid-control-apply
sudo install -Dm644 lid-control.desktop             /usr/share/applications/lid-control.desktop
sudo install -Dm644 org.kbrianps.lid-control.policy /usr/share/polkit-1/actions/org.kbrianps.lid-control.policy

# Generate hicolor PNG sizes from the master lid-control.png. Needs PIL.
if ! python3 -c "from PIL import Image" >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y python3-pil
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3-pillow
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm python-pillow
    fi
fi

sudo python3 - <<'PY'
import os
from PIL import Image

src = Image.open("lid-control.png").convert("RGBA")
bbox = src.getbbox()
content = src.crop(bbox)
cw, ch = content.size
side = max(cw, ch)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
square.paste(content, ((side - cw) // 2, (side - ch) // 2), content)

MARGIN = 0.0
for size in (48, 64, 128, 256, 512):
    inner = max(1, round(size * (1 - 2 * MARGIN)))
    resized = square.resize((inner, inner), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - inner) // 2
    canvas.paste(resized, (offset, offset), resized)
    out_dir = f"/usr/share/icons/hicolor/{size}x{size}/apps"
    os.makedirs(out_dir, exist_ok=True)
    canvas.save(f"{out_dir}/lid-control.png", optimize=True)
PY

if command -v update-desktop-database >/dev/null 2>&1; then
    sudo update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    sudo gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi

echo "✅ Installed successfully!"
echo ""
echo "Find it in the application menu as 'Lid Control', or run: lid-control"
