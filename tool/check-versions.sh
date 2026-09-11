#!/bin/bash
# Fails when the version numbers in the repository disagree.
#
# `version` is the single source of truth: build-deb.sh stamps it into the
# package and main.dart reads it out of the installed bundle at startup.
# pubspec.yaml carries its own copy that Flutter needs, and it used to say
# 1.0.0+1 while the app reported 0.7.1.
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(tr -d '[:space:]' < version)"
PUBSPEC="$(sed -n 's/^version: \([0-9][0-9.]*\).*/\1/p' pubspec.yaml)"

status=0

if [ -z "$VERSION" ]; then
  echo "version: file is empty" >&2
  status=1
fi

if [ "$PUBSPEC" != "$VERSION" ]; then
  echo "pubspec.yaml says $PUBSPEC, the version file says $VERSION" >&2
  status=1
fi

if grep -qE '^(Version|Installed-Size):' deb/DEBIAN/control; then
  echo "deb/DEBIAN/control must not track Version or Installed-Size;" >&2
  echo "build-deb.sh generates both." >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "version $VERSION is consistent"
fi

exit "$status"
