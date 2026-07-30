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
chmod +x additional/python/run_script.py
flutter build linux
cp -r additional build/linux/x64/release/bundle/
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

# Estimate the installed size by summing the sizes of all files in the package
SIZE=$(du -s "$STAGE" | cut -f1)
sed -i "s/^Installed-Size: .*/Installed-Size: $SIZE/" "$STAGE/DEBIAN/control"

# Match by field name, not by line number: the previous "2s/.*/..." overwrote
# whatever happened to be on line two, so reordering control silently
# destroyed a field.
sed -i "s/^Version: .*/Version: $VERSION/" "$STAGE/DEBIAN/control"

# Build deb package
dpkg-deb --build -Zxz --root-owner-group "$STAGE"
mv "$STAGE.deb" "linux-assistant_${VERSION}_${ARCH}.deb"

# The CI artifact step and the in-app updater both expect this name.
cp "linux-assistant_${VERSION}_${ARCH}.deb" linux-assistant.deb

echo "Built linux-assistant_${VERSION}_${ARCH}.deb"
