#!/bin/bash
#
# Builds a .deb package for Lid Control.
# Output: lid-control_<version>_all.deb in the current directory.

set -e

PKG_NAME="lid-control"
PKG_VERSION="1.0.5"
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

# --- Clean previous build --------------------------------------------------
rm -rf "$PKG_DIR" "${PKG_DIR}.deb"

# --- Layout ----------------------------------------------------------------
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/doc/$PKG_NAME"

install -Dm755 lid-control.sh       "$PKG_DIR/usr/bin/lid-control"
install -Dm644 lid-control.desktop  "$PKG_DIR/usr/share/applications/lid-control.desktop"
install -Dm644 lid-control.svg      "$PKG_DIR/usr/share/icons/hicolor/scalable/apps/lid-control.svg"

# --- Control file ----------------------------------------------------------
cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $PKG_VERSION
Section: utils
Priority: optional
Architecture: $PKG_ARCH
Depends: zenity, policykit-1, systemd, xdotool
Maintainer: kbrianps <kbrianps@localhost>
Description: Laptop Lid Control
 Graphical tool to configure what happens when the laptop lid is closed
 (suspend, ignore, lock, power off, hibernate). Uses zenity for the GUI
 and pkexec to apply the change to systemd-logind.
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
