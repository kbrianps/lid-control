#!/bin/bash
#
# Builds a .deb package for Lid Control.
# Output: lid-control_<version>_all.deb in the current directory.

set -e

PKG_NAME="lid-control"
PKG_VERSION="1.3.0"
PKG_ARCH="all"
PKG_DIR="${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# --- Make sure the build tools are available -------------------------------
if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "dpkg-deb not found. Installing build dependencies..."
    sudo apt-get update
    sudo apt-get install -y dpkg-dev fakeroot
fi

if ! python3 -c "from PIL import Image" >/dev/null 2>&1; then
    echo "python3-pil not found. Installing it (used to resize the icon)..."
    sudo apt-get install -y python3-pil
fi

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "msgfmt not found. Installing gettext (used to compile translations)..."
    sudo apt-get install -y gettext
fi

# --- Clean previous build --------------------------------------------------
rm -rf "$PKG_DIR" "${PKG_DIR}.deb"

# --- Layout ----------------------------------------------------------------
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/doc/$PKG_NAME"

install -Dm755 lid-control                          "$PKG_DIR/usr/bin/lid-control"
install -Dm755 lid-control-apply                    "$PKG_DIR/usr/libexec/lid-control-apply"
install -Dm644 lid-control.desktop                  "$PKG_DIR/usr/share/applications/lid-control.desktop"
install -Dm644 org.kbrianps.lid-control.policy      "$PKG_DIR/usr/share/polkit-1/actions/org.kbrianps.lid-control.policy"

# Compile translation catalogs (.po -> .mo) into the package
for po in po/*.po; do
    [ -f "$po" ] || continue
    lang=$(basename "$po" .po)
    out_dir="$PKG_DIR/usr/share/locale/$lang/LC_MESSAGES"
    mkdir -p "$out_dir"
    msgfmt "$po" -o "$out_dir/lid-control.mo"
done

# Generate hicolor PNG sizes from the master lid-control.png.
# Crops the source to its non-transparent bounding box and recenters it on a
# square canvas at each target size, leaving a small ~4% margin so the icon
# matches the visual size of other dock icons (Yaru, Adwaita, etc.).
PKG_DIR="$PKG_DIR" python3 - <<'PY'
import os
from PIL import Image

pkg_dir = os.environ["PKG_DIR"]
src = Image.open("lid-control.png").convert("RGBA")

bbox = src.getbbox()
content = src.crop(bbox)
cw, ch = content.size
side = max(cw, ch)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
square.paste(content, ((side - cw) // 2, (side - ch) // 2), content)

MARGIN = 0.0  # full-bleed; the master icon already includes any desired padding
for size in (48, 64, 128, 256, 512):
    inner = max(1, round(size * (1 - 2 * MARGIN)))
    resized = square.resize((inner, inner), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - inner) // 2
    canvas.paste(resized, (offset, offset), resized)
    out_dir = f"{pkg_dir}/usr/share/icons/hicolor/{size}x{size}/apps"
    os.makedirs(out_dir, exist_ok=True)
    canvas.save(f"{out_dir}/lid-control.png", optimize=True)
PY

# --- Control file ----------------------------------------------------------
cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $PKG_VERSION
Section: utils
Priority: optional
Architecture: $PKG_ARCH
Depends: python3, python3-gi, gir1.2-gtk-3.0, policykit-1, systemd
Maintainer: kbrianps <kbrianps@localhost>
Description: Lid Control
 Graphical tool to configure what happens when the laptop lid is closed
 (suspend, ignore, lock, power off, hibernate). Lets you set independent
 actions for on-battery, plugged-in and docked scenarios, with a master
 toggle to apply one action to all of them. Available in English and
 Portuguese. Uses GTK3 (PyGObject) for the dialog and pkexec to apply
 the change to systemd-logind.
EOF

# --- postinst / postrm -----------------------------------------------------
cat > "$PKG_DIR/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "$PKG_DIR/DEBIAN/postinst"

cat > "$PKG_DIR/DEBIAN/postrm" <<'EOF'
#!/bin/bash
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "$PKG_DIR/DEBIAN/postrm"

# --- Build -----------------------------------------------------------------
fakeroot dpkg-deb --build "$PKG_DIR"

rm -rf "$PKG_DIR"

echo ""
echo "✅ Built: ${PKG_DIR}.deb"
echo ""
echo "Install with:"
echo "    sudo apt install ./${PKG_DIR}.deb"
