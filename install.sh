#!/usr/bin/env bash
# Installs Linux Assistant from a .deb and clears out an older installation
# first — including the parts no package manager knows about.
#
#   bash install.sh                       # use the .deb next to this script
#   bash install.sh path/to/package.deb   # use a specific one
#   bash install.sh --purge               # also wipe settings, cache and shortcuts
#   bash install.sh --yes                 # never ask, assume yes
#
# Run it as your normal user. It calls sudo where it needs to, so that the
# session-bound parts (gsettings shortcuts, ~/.config) act on your account and
# not on root's.

set -euo pipefail

ASSUME_YES=0
PURGE=0
DEB=""

for arg in "$@"; do
    case "$arg" in
        --yes|-y) ASSUME_YES=1 ;;
        --purge) PURGE=1 ;;
        # Prints the comment header above, up to the first non-comment line.
        -h|--help) sed -n '2,${/^#/!q;s/^# \?//;p;}' "$0"; exit 0 ;;
        *) DEB="$arg" ;;
    esac
done

SCRIPT_DIR="$( cd -- "$( dirname -- "$( readlink -f "${BASH_SOURCE[0]}" )" )" && pwd )"
APP_ID_FLATPAK="io.github.jean28518.Linux-Assistant"

info()  { printf '\033[1;34m::\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m!!\033[0m %s\n' "$1"; }
step()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

# Returns 0 on yes. Under --yes it answers itself.
confirm() {
    if [ "$ASSUME_YES" = "1" ]; then
        return 0
    fi
    local reply
    read -r -p "   $1 [j/N] " reply
    [[ "$reply" =~ ^([jJyY])$ ]]
}

if [ "$(id -u)" = "0" ]; then
    warn "Bitte als normaler Benutzer starten, nicht mit sudo."
    warn "Das Skript ruft sudo selbst auf, wo es nötig ist — sonst landen"
    warn "Einstellungen und Tastenkürzel im Home-Verzeichnis von root."
    exit 1
fi

# --- The package -------------------------------------------------------------

if [ -z "$DEB" ]; then
    # Newest match wins, so a rebuilt package is picked up without an argument.
    DEB="$(ls -t "$SCRIPT_DIR"/linux-assistant_*_*.deb "$SCRIPT_DIR"/linux-assistant.deb 2>/dev/null | head -n1 || true)"
fi

if [ -z "$DEB" ] || [ ! -f "$DEB" ]; then
    warn "Kein .deb gefunden."
    echo "   Entweder eins mitgeben:  bash install.sh /pfad/zum/paket.deb"
    echo "   oder selbst bauen:       bash build-deb.sh"
    exit 1
fi

DEB="$(readlink -f "$DEB")"
NEW_VERSION="$(dpkg-deb --field "$DEB" Version 2>/dev/null || echo "?")"
info "Paket:  $DEB"
info "Version: $NEW_VERSION"

# --- What is already installed ----------------------------------------------

step "1. Bestandsaufnahme"

OLD_DEB_VERSION="$(dpkg-query -W -f='${Version}' linux-assistant 2>/dev/null || true)"
OLD_FLATPAK=""
if command -v flatpak >/dev/null 2>&1; then
    OLD_FLATPAK="$(flatpak list --app --columns=application 2>/dev/null | grep -ix "$APP_ID_FLATPAK" || true)"
fi

# Anything on PATH that dpkg does not claim was put there by hand.
MANUAL_BIN=""
if BIN_PATH="$(command -v linux-assistant 2>/dev/null)"; then
    if ! dpkg-query -S "$(readlink -f "$BIN_PATH")" >/dev/null 2>&1; then
        MANUAL_BIN="$BIN_PATH"
    fi
fi

MANUAL_DESKTOP=""
for d in /usr/share/applications ~/.local/share/applications; do
    [ -d "$d" ] || continue
    while IFS= read -r f; do
        dpkg-query -S "$f" >/dev/null 2>&1 || MANUAL_DESKTOP="$MANUAL_DESKTOP $f"
    done < <(find "$d" -maxdepth 1 -iname '*linux*assistant*.desktop' 2>/dev/null)
done

[ -n "$OLD_DEB_VERSION" ] && info "deb-Installation gefunden: $OLD_DEB_VERSION"
[ -n "$OLD_FLATPAK" ]     && info "Flatpak gefunden: $APP_ID_FLATPAK"
[ -n "$MANUAL_BIN" ]      && info "Manuell abgelegt: $MANUAL_BIN"
[ -n "$MANUAL_DESKTOP" ]  && info "Verwaiste Starter:$MANUAL_DESKTOP"
if [ -z "$OLD_DEB_VERSION$OLD_FLATPAK$MANUAL_BIN$MANUAL_DESKTOP" ]; then
    info "Keine Altinstallation gefunden — es wird frisch installiert."
fi

# --- Remove what apt cannot replace -----------------------------------------

step "2. Altinstallation entfernen"

if [ -n "$OLD_DEB_VERSION" ]; then
    # Same package name and the same paths since 0.5.3, so apt replaces this
    # one during the install below. Nothing to do here.
    info "deb $OLD_DEB_VERSION wird beim Installieren ersetzt."
fi

if [ -n "$OLD_FLATPAK" ]; then
    # A Flatpak lives beside the deb rather than replacing it, so it has to go
    # explicitly or you end up with two assistants in the menu.
    warn "Das Flatpak läuft sonst parallel zur neuen Installation weiter."
    if confirm "Flatpak $APP_ID_FLATPAK entfernen?"; then
        flatpak uninstall -y "$APP_ID_FLATPAK"
    fi
fi

if [ -n "$MANUAL_BIN" ]; then
    warn "$MANUAL_BIN gehört zu keinem Paket."
    if confirm "Datei löschen?"; then
        sudo rm -f "$MANUAL_BIN"
    fi
fi

for f in $MANUAL_DESKTOP; do
    warn "$f gehört zu keinem Paket."
    if confirm "Starter löschen?"; then
        if [ -w "$(dirname "$f")" ]; then rm -f "$f"; else sudo rm -f "$f"; fi
    fi
done

# --- Install -----------------------------------------------------------------

step "3. Installieren"

# apt, not `dpkg -i`: it pulls the declared dependencies. dpkg would leave the
# package half configured when one of them is missing.
sudo apt-get update -qq || warn "apt update fehlgeschlagen — versuche es trotzdem."

APT_ARGS=(install -y)
if [ "$OLD_DEB_VERSION" = "$NEW_VERSION" ]; then
    # Without this apt reports "already the newest version" and does nothing,
    # which is the wrong answer when you re-run the script to repair an
    # installation whose files were removed by hand.
    info "Gleiche Version bereits installiert — erzwinge Neuinstallation."
    APT_ARGS+=(--reinstall)
fi
sudo apt-get "${APT_ARGS[@]}" "$DEB"

# --- Leftovers no package manager tracks -------------------------------------

step "4. Reste"

if [ "$PURGE" = "1" ]; then
    rm -rf ~/.config/linux-assistant ~/.cache/linux-assistant
    info "Einstellungen und Cache gelöscht."
else
    for d in ~/.config/linux-assistant ~/.cache/linux-assistant; do
        if [ -d "$d" ]; then
            info "Behalten: $d  (mit --purge löschen für einen frischen Start)"
        fi
    done
fi

# The app registers its shortcut through gsettings and appends a new entry each
# time, without checking for one it already made. Over several installs those
# add up, and a removal never takes them away.
if command -v gsettings >/dev/null 2>&1 && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
    BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    if gsettings list-schemas 2>/dev/null | grep -qx "$SCHEMA"; then
        KEEP=()
        DROP=()
        while IFS= read -r path; do
            [ -n "$path" ] || continue
            cmd="$(gsettings get "$SCHEMA.custom-keybinding:$path" command 2>/dev/null || echo "")"
            if [[ "$cmd" == *linux-assistant* ]]; then DROP+=("$path"); else KEEP+=("$path"); fi
        done < <(gsettings get "$SCHEMA" custom-keybindings 2>/dev/null \
                 | tr -d "[]' " | tr ',' '\n')

        if [ "${#DROP[@]}" -gt 0 ]; then
            info "Gefundene Tastenkürzel für linux-assistant: ${#DROP[@]}"
            if [ "$PURGE" = "1" ] || [ "${#DROP[@]}" -gt 1 ]; then
                if [ "$PURGE" = "1" ]; then
                    prompt="Alle entfernen? Die App legt beim nächsten Start ein neues an."
                else
                    prompt="Mehrfach vorhanden — Duplikate entfernen?"
                fi
                if confirm "$prompt"; then
                    if [ "$PURGE" = "1" ]; then
                        remaining=("${KEEP[@]:-}")
                    else
                        remaining=("${KEEP[@]:-}" "${DROP[0]}")   # eins behalten
                    fi
                    list="["
                    for p in "${remaining[@]}"; do
                        [ -n "$p" ] || continue
                        [ "$list" != "[" ] && list="$list, "
                        list="$list'$p'"
                    done
                    gsettings set "$SCHEMA" custom-keybindings "$list]"
                    info "Bereinigt."
                fi
            fi
        fi
    fi
fi

step "Fertig"
linux-assistant --version || true
echo
echo "Starten:  linux-assistant   (oder über das Anwendungsmenü)"
echo "Kürzel:   Super+Q, sobald es die App beim ersten Start eingerichtet hat"
