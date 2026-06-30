# Linux Assistant

Linux Assistant is a Linux desktop helper focused on integrated search, routine checks, and common admin workflows.  
The app is built with Flutter (UI) plus Python helper scripts.

Current stable release: **v0.7.0**  
Release page: <https://github.com/Toqsick/linux-assistant/releases/tag/v0.7.0>

## Documentation

1. Mission and product direction: [MANIFEST.md](MANIFEST.md)
2. v0.7 technical report and roadmap: [V0.7_REPORT.md](V0.7_REPORT.md)
3. Feature list: [features.csv](features.csv)

## Requirements

```bash
sudo apt install keybinder-3.0
sudo apt install libkeybinder-3.0-0 libkeybinder-3.0-dev
sudo apt install wmctrl
```

## Build and run

```bash
git clone https://github.com/Toqsick/linux-assistant.git
cd linux-assistant

# Install Flutter (snap variant)
sudo apt install snapd git
sudo snap install flutter --classic
flutter doctor

# Build and run
flutter pub get
flutter build linux
chmod +x additional/python/run_script.py
cp -r additional build/linux/x64/release/bundle/
cd build/linux/x64/release/bundle/
./linux_assistant
```

### Flutter/Snap GLIBC troubleshooting

If Flutter from snap fails with GLIBC errors (for example `GLIBC_2.38 not found`), use a local Flutter SDK tarball instead:

```bash
mkdir -p ~/.local/flutter-sdk
cd ~/.local/flutter-sdk
curl -fL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz
export PATH="$HOME/.local/flutter-sdk/flutter/bin:$PATH"

flutter --version
flutter pub get
flutter test
flutter analyze
```

## Packaging

```bash
# Debian package
bash ./build-deb.sh
sudo dpkg --install linux-assistant.deb

# RPM package
bash ./build-rpm.sh

# Arch package (run on Arch-based distro)
bash ./build-arch-pkg.sh
sudo pacman -U linux-assistant-*.pkg.tar.zst
```

## Flatpak notes

Flatpak companion repository:  
<https://github.com/Toqsick/flathub/tree/com.github.jean28518.Linux-Assistant>

## Development quality checks

```bash
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
```

## Languages

- English
- German
- Italian
