# Lid Control

Small graphical tool to configure what happens when a laptop lid is closed
on systemd-based Linux distributions. Pick between **suspend**, **ignore**,
**lock**, **power off** or **hibernate** for each of the three scenarios
`systemd-logind` distinguishes — on battery, plugged in, and docked — from
a single GTK3 dialog. The choice is written to
`/etc/systemd/logind.conf.d/lid-control.conf` and `systemd-logind` is
reloaded immediately.

![category: system](https://img.shields.io/badge/category-system-blue)
![license: GPLv3](https://img.shields.io/badge/license-GPLv3-blue)

## Requirements

- `systemd` (for `systemd-logind`)
- Python 3 with PyGObject and GTK3 (`python3-gi`, `gir1.2-gtk-3.0` on
  Debian/Ubuntu; `python3-gobject` + `gtk3` on Fedora/Arch). Already
  present on any standard GNOME/Cinnamon/MATE/XFCE desktop install.
- `policykit-1` / `polkit` (provides `pkexec` for the privileged write)

The installer and the `.deb` package both pull these in automatically.

## Installation

### Option A — Debian package (recommended)

Download the latest `.deb` from the
[Releases page](../../releases) and install:

```bash
sudo apt install ./lid-control_1.2.0_all.deb
```

`apt` will resolve and install the dependencies for you.

### Option B — Manual installer

```bash
git clone https://github.com/kbrianps/lid-control.git
cd lid-control
./install.sh
```

The script detects missing dependencies and installs them via `apt`, `dnf`
or `pacman`, then copies the files into place.

## Usage

Open **Lid Control** from the application menu, or run from a terminal:

```bash
lid-control
```

The dialog has three independent radio groups, one for each scenario that
`systemd-logind` distinguishes:

- **On battery** — `HandleLidSwitch`
- **Plugged in (AC power)** — `HandleLidSwitchExternalPower`
- **Docked (external monitor or dock)** — `HandleLidSwitchDocked`

A checkbox at the top — **"Use the same action for all scenarios"** —
locks the second and third groups to mirror the first one. When it is
checked, picking an action in the *On battery* group instantly updates
the other two and disables their controls. Uncheck it to set each
scenario independently.

The checkbox starts checked when all three current values agree, and
unchecked otherwise — so you always see the actual state on entry.

Click **Save**. The change takes effect immediately, with no reboot or
relogin needed — and **no password prompt**: a polkit policy
(`org.kbrianps.lid-control.apply`) lets the active local user invoke
the privileged helper (`/usr/libexec/lid-control-apply`) without
authentication. Remote and inactive sessions still require admin
credentials.

## Building the .deb yourself

```bash
./build-deb.sh
```

Produces `lid-control_1.2.0_all.deb` in the current directory.

## License

GPLv3 — see [LICENSE](LICENSE).
