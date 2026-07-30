#!/bin/bash
APP_DIR="/usr/lib/linux-assistant"

# If the binary sits next to this script, run that one — this is the case when
# the script is started from inside a build bundle.
#
# Resolved from the script's own location. The previous test looked at the
# current working directory instead, so typing `linux-assistant` while inside a
# build tree launched ./linux-assistant rather than the installed app.
SCRIPT_DIR="$( cd -- "$( dirname -- "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"
if [ -f "$SCRIPT_DIR/linux-assistant" ] && [ "$SCRIPT_DIR" != "/usr/bin" ]; then
   APP_DIR="$SCRIPT_DIR"
fi

# if /app/bin is present change APP_DIR (because then we are in flatpak)
if [ -d "/app/bin" ]; then
   APP_DIR="/app/bin"
fi

if [[ "$1" == "-v" || "$1" == "--version" ]]; then
  VERSION=""
  if [ -f "$APP_DIR/version" ]; then
    VERSION=$( cat "$APP_DIR/version" )
  fi

  echo "Linux-Assistant $VERSION"
  echo "A daily linux helper with powerful integrated search, routines and checks."
  echo "Homepage: https://www.linux-assistant.org"
  exit 0
fi

if wmctrl -l | grep -q 'Linux Assistant'; then
  wmctrl -a 'Linux Assistant'
else
  "$APP_DIR/linux-assistant"
fi
