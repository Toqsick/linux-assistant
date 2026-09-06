#!/bin/bash
set -euo pipefail

VERSION="$( cat version )"
ARCH="$( dpkg --print-architecture )"

# The package is assembled in build/ rather than in the tracked deb/ directory.
# Stamping Version and Installed-Size used to rewrite the checked-in
# deb/DEBIAN/control, so every build left the working tree dirty and the
# committed file carried whatever the last local build measured.
STAGE="build/deb-root"
rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN"
cp deb/DEBIAN/control "$STAGE/DEBIAN/control"

# Build Linux Assistant
# The two privileged entry points are named in the polkit policy by path, so
# pkexec has to be able to execute them directly.
chmod +x additional/python/run_multiple_commands.py
chmod +x additional/python/read_security_report.py
flutter build linux
cp -r additional build/linux/x64/release/bundle/
# The runner's unit tests are not part of the product.
rm -rf build/linux/x64/release/bundle/additional/python/tests
cp version build/linux/x64/release/bundle/

# Prepare deb files for packaging
mkdir -p "$STAGE/usr/lib/linux-assistant/"
cp -r build/linux/x64/release/bundle/* "$STAGE/usr/lib/linux-assistant/"
mkdir -p "$STAGE/usr/share/icons/hicolor/scalable/apps/"
cp linux-assistant.svg "$STAGE/usr/share/icons/hicolor/scalable/apps/"
mkdir -p "$STAGE/usr/share/icons/hicolor/256x256/apps/"
cp linux-assistant.png "$STAGE/usr/share/icons/hicolor/256x256/apps/"
mkdir -p "$STAGE/usr/share/applications/"
cp linux-assistant.desktop "$STAGE/usr/share/applications/"
mkdir -p "$STAGE/usr/share/polkit-1/actions/"
cp org.linux-assistant.operations.policy "$STAGE/usr/share/polkit-1/actions/"
mkdir -p "$STAGE/usr/bin/"
cp linux-assistant.sh "$STAGE/usr/bin/linux-assistant"
chmod +x "$STAGE/usr/bin/linux-assistant"
chmod 755 "$STAGE/DEBIAN"

# Version and Installed-Size are generated, not tracked. The checked-in
# control file used to carry both, and both went stale: the committed Version
# was whatever the last release happened to be, and Installed-Size was whatever
# the last local build measured.
SIZE=$(du -s "$STAGE" | cut -f1)
sed -i "/^Description:/i Version: $VERSION\nInstalled-Size: $SIZE" \
  "$STAGE/DEBIAN/control"

# Build deb package
dpkg-deb --build -Zxz --root-owner-group "$STAGE"
mv "$STAGE.deb" "linux-assistant_${VERSION}_${ARCH}.deb"

# The CI artifact step and the in-app updater both expect this name.
cp "linux-assistant_${VERSION}_${ARCH}.deb" linux-assistant.deb

echo "Built linux-assistant_${VERSION}_${ARCH}.deb"
