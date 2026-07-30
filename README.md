# linux-assistant

A linux application which is a daily linux helper with powerful integrated search, routines checks and admninistrative tasks. The Project is built with flutter and python.

## Requirements

To build:

```bash
sudo apt install libkeybinder-3.0-0 libkeybinder-3.0-dev wmctrl
```

To run an installed package, only the runtime libraries are needed — the `.deb`
declares them, so `apt` pulls them in for you.

## Build

```bash
# Install keybinder, see requirements
sudo rm /etc/apt/preferences.d/nosnap.pref # (For Linux Mint)
sudo apt install snapd git
sudo snap install flutter --classic
flutter doctor # If command not found: Reboot and try again
git clone https://github.com/Jean28518/linux-assistant.git
cd linux-assistant

# Option 1: Build with flutter manually
flutter build linux
chmod +x additional/python/run_script.py
cp -r additional build/linux/x64/release/bundle/
cd build/linux/x64/release/bundle/
./linux-assistant

# Option 2: Build .deb and install .deb package:
bash ./build-deb.sh
sudo apt install ./linux-assistant_*_amd64.deb

# Option 3: Build .rpm package:
bash ./build-rpm.sh

# Option 4: Build Arch package
# You can only do this on an arch based distro
bash ./build-arch-pkg.sh
# To Install:
sudo pacman -U linux-assistant-*.pkg.tar.zst
```

Prefer `apt install ./…deb` over `dpkg -i`: `apt` resolves the declared
dependencies, whereas `dpkg` leaves the package half configured if one is
missing.

## Uninstall

```bash
sudo apt remove linux-assistant
```

Two things no package manager knows about and that therefore survive:

```bash
# Settings, search history and caches
rm -rf ~/.config/linux-assistant ~/.cache/linux-assistant
```

…and the keyboard shortcut, which is written into the desktop environment's own
configuration. On GNOME based desktops (Ubuntu, Zorin OS, Fedora) it is a custom
shortcut running `linux-assistant`; remove it under
*Settings ▸ Keyboard ▸ Custom Shortcuts*. On KDE the entry lives in
`~/.config/khotkeysrc`, on XFCE in the xfconf command bindings.

If the app was installed as a Flatpak instead, it is removed separately:

```bash
flatpak uninstall io.github.jean28518.Linux-Assistant
```

## Run as flatpak

Repo: <https://github.com/Jean28518/flathub/tree/com.github.jean28518.Linux-Assistant>

- Uncomment the archive from the web and use e.g. this local one:

```yaml
      - type: archive
        path: /path/to/linux-assistant-bundle.zip
```

```bash
flatpak install runtime/org.freedesktop.Sdk/x86_64/23.08

rm -r .flatpak-builder/ # Only if you built something before.
flatpak-builder build-dir io.github.jean28518.Linux-Assistant.yml  --user --force-clean --install 
flatpak run io.github.jean28518.Linux-Assistant
```

## Features

<https://github.com/Jean28518/linux-assistant/blob/main/features.csv>

## Current Languages

- English
- German
- Italian

## Mission

<https://github.com/Jean28518/linux-assistant/blob/main/MANIFEST.md>

## Development

```bash
# Install flutter

flutter run
```
