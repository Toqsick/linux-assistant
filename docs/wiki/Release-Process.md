# Release-Prozess

Aktueller Milestone: `docs/design/milestone-v0.7.2.md` (Gate, DoD, Changelog-Vorlage).

## Versionierung

Die Datei **`version`** im Repo-Root ist die einzige Source of Truth. Alle
drei Packaging-Skripte lesen sie und ersetzen die Werte zur Build-Zeit –
die eingecheckten Werte in `deb/DEBIAN/control`, `rpmbuild/SPECS/…` und
`PKGBUILD` bleiben unangetastet (Commit `1e90957`).

## Release-Schritte

```bash
# 1. Gate prüfen (siehe Milestone §5): CI grün, Verifikation abgehakt, l10n done

# 2. Version bumpen
echo "0.7.2" > version
git add version && git commit -m "release: v0.7.2"

# 3. Taggen & pushen
git tag -a v0.7.2 -m "Admin-Hub: Werkzeuge-Sektion (Browser, Quick Notes, Dateimanager, Systemmonitor)"
git push origin main --tags

# 4. Pakete bauen
bash ./build-deb.sh   # linux-assistant_0.7.2_amd64.deb (+ Alias linux-assistant.deb für CI/Updater)
bash ./build-rpm.sh   # ~/rpmbuild/RPMS/
```

## Packaging-Details

- **deb:** `build-deb.sh` staged in `build/deb-root/` (schreibt nichts mehr
  in getrackte Dateien), deklariert GTK + Python-Module + keybinder + wmctrl.
  Install: `sudo apt install ./linux-assistant_*_amd64.deb`.
- **rpm:** `build-rpm.sh` (Version-Ersetzung per Feldname, nicht Zeilennummer).
- **arch:** `build-arch-pkg.sh` (nur auf Arch-Systemen).
- **Flatpak:** eigenständiger Track, separates Repo
  (`Jean28518/flathub`, Package-ID `io.github.jean28518.Linux-Assistant`).
- **Desktop-Entry:** `Icon=linux-assistant` (Icon-Theme-Namen statt
  absoluter Pfade) + `StartupWMClass=linux-assistant`.

## CI

`.github/workflows/build.yml`, gepinnt auf **ubuntu-24.04**: gebaute
Binaries tragen die glibc des Build-Images – ein stiller Wechsel von
`ubuntu-latest` würde Artefakte erzeugen, die auf 24.04-basierten Systemen
(Zorin OS 18, Mint 22, Ubuntu 24.04) nicht starten.

Reihenfolge: `flutter test` → Build → Packaging → Artefakt-Upload.

## In-App-Updater

`LinuxAssistantUpdater.isVersionGreaterThanCurrent` toleriert Tags wie
`0.8`, `v0.8.0-rc1` oder Müll (parst nur numerische Präfixe, wirft nie).
Der Updater erwartet das Artefakt unter dem Alias-Namen `linux-assistant.deb`.

## Smoke-Test nach Installation (DoD-Ausschnitt)

- App startet in den Hub (Dashboard)
- Hotkey Super+Q öffnet die Suche
- Alle vier Werkzeuge erreichbar und funktional (Checks:
  `docs/design/admin-hub-followups.md` §1)
- Idle: kein Polling-Lärm im Journal (`kDebugMode`-gated Logs)
