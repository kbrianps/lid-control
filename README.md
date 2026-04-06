# Lid Control

Small graphical tool to configure what happens when a laptop lid is closed
on systemd-based Linux distributions. Pick between **suspend**, **ignore**,
**lock**, **power off** or **hibernate** from a simple Zenity dialog — the
choice is written to `/etc/systemd/logind.conf.d/lid-control.conf` and
`systemd-logind` is reloaded immediately.

![category: system](https://img.shields.io/badge/category-system-blue)
![license: GPLv3](https://img.shields.io/badge/license-GPLv3-blue)

## Requirements

- `systemd` (for `systemd-logind`)
- `zenity` (GUI dialog)
- `policykit-1` (provides `pkexec` for the privileged write)
- `xdotool` (rebrands the dialog window so the dock shows the right icon)

The installer and the `.deb` package both pull these in automatically.

## Installation

### Option A — Debian package (recommended)

Download the latest `.deb` from the
[Releases page](../../releases) and install:

```bash
sudo apt install ./lid-control_1.0.5_all.deb
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

Pick the action and confirm with your password (the privileged write
goes through `pkexec`).

The chosen action is applied to **all three lid scenarios** that
`systemd-logind` distinguishes:

- `HandleLidSwitch` — on battery
- `HandleLidSwitchExternalPower` — plugged into AC power
- `HandleLidSwitchDocked` — connected to a dock or external monitor

This is intentional: most people expect "close the lid → suspend" to
behave the same way regardless of whether the laptop is on battery or
plugged in. If you need different behaviors per scenario, edit
`/etc/systemd/logind.conf.d/lid-control.conf` by hand.

## Building the .deb yourself

```bash
./build-deb.sh
```

Produces `lid-control_1.0.5_all.deb` in the current directory.

## License

GPLv3 — see [LICENSE](LICENSE).
