# Roadmap: Linux Assistant (Toqsick-Fork) — V0.8.0 → V0.9

**Stand:** 2026-09-10 · **Konsolidiert aus:** PR #24 (Implementierungsplan Admin-Hub v0.8.5 — wird hiermit ersetzt), Issues #25–#30, `.claude/plans/den-linux-assistant-weiter-swift-adleman.md` (Härtungs-Plan 0.7.1→0.8.0), 5-Agenten-Recon 2026-09-10, Bastis Zielbild („Admin Linux Hub", All-in-One).

## Status quo (Kurzfassung)

- `main` (GitHub): v0.7.1-Basis + **E1–E4-Werkzeuge gemergt** (Browser-Launcher, Quick Notes, Dateimanager, Systemmonitor als HubTool-Screens), Werkzeuge-Sektion in der Sidebar, MintYColors-ThemeExtension, Design-Docs (12), Wiki (9), CI mit Gates + deb/rpm-Artefakten.
- `hardening/0.8.0` (lokal, rebase auf main): Phase 0+1+2 der Härtung — argv statt Shell im Root-Pfad, Polkit-Split (2 präzise Actions), deb822-Fix (`apt_sources.py`), Single-Instance-Socket statt wmctrl, Keybinding-Idempotenz, Install-Robustheit, Versions-Gate (eine Quelle: `version`).
- Installiert auf Bastis Laptop (Stand Aufnahme): noch v0.7.1 — deren Security-Check crasht nach Passwort-Eingabe (deb822-`IndexError`, UI zeigt falsch „Root-Rechte nötig"). **Evidence:** `screenshots/v0.7.1/04b…04c` + journal 2026-09-10 21:53.

---

## V0.8.0 — „Alles nutzbar" (Release-Zyklus, läuft)

Ziel: Jede angezeigte Funktion funktioniert auf Zorin/Ubuntu 24.04 ohne Fehlertext-Lügen. Release als Tag + GitHub-Release + deb.

| # | Thema | Status | Wo |
|---|---|---|---|
| 1 | Security-Check deb822-Fix | ✅ implementiert (`apt_sources.py` + Tests) | `additional/python/` |
| 2 | **Error-UX:** Script-Fehler ≠ „keine Root-Rechte" — rc-Unterscheidung + stderr sichtbar machen | 🔶 dieser Session (Phase E) | `lib/layouts/security_check/overview.dart` |
| 3 | Nutzbarkeitsreste Phase 3: tote Settings, Hub-Default-Nav, fi-Locale registrieren | 🔶 dieser Session | `main.dart:281-285`, settings |
| 4 | Version-Gate/CI | ✅ | `tool/check-versions.sh`, `build.yml` |
| 5 | Baseline-Handoff (Screenshots/Design/Roadmap) | 🔶 dieser Session | `docs/handoff/` |

**Definition of Done V0.8.0:** Gates grün (analyze/test/format/python-unittest), `build-deb.sh`, Install per `install.sh --purge` (Passwort: Basti), Security-Check läuft mit echtem Passwort fehlerfrei durch (journal-Evidence), Tag `v0.8.0` + GitHub-Release mit deb-Asset, PR #24 geschlossen (Verweis auf dieses Dokument).

## V0.8.X — „Zorin optimal" (nach 0.8.0, kurze Zyklen)

1. **Zorin-Erkennung & Akzent:** `get_environment.py` prüfen (Zorin als Distro + Desktop GNOME/Xfwm-Varianten), Zorin-Palette in `main.dart`-Distro-Set sicherstellen, `features.csv` Z.18 (Timeshift auf Zorin „?") auflösen.
2. **deb822-Vollabdeckung:** `apt_sources.py` überall verwenden, wo `.list`/`.sources` gelesen werden (Updater, Uninstaller-Quellen, Autoupdates) — Prüfen + vereinheitlichen.
3. **Updater-Stand reparieren:** config kennt `newest-linux-assistant-version: 0.6.2` (Upstream-Feed?) — Fork-eigene Release-Erkennung (GitHub-Releases des Forks) statt Upstream-Verwirrung.
4. **Tool-/Plugin-Registry (Issue #27) als Architekturbasis:** HubTool-Muster aus E1–E4 formalisieren (Interface: id, Titel, Icon, Screen-Builder, Capabilities) — V0.9-Module registrieren sich nur noch. Grundlage für alles Folgende.
5. **`la-helper` privilegierter Helper (Issue #28):** ein abgesicherter, polkit-gated Helper statt N einzelner pkexec-Scripte; Actions bleiben feingranular (bestehende Policy-Struktur beibehalten).
6. **D-Bus SystemdService (Issue #29):** Systemd-Unit-Status/-Start/-Stop ohne Shell-Umwege; Basis für Docker-Watcher & Backup-Status in V0.9.
7. **l10n-`_tr()`-Pattern (Issue #25) + MintYColors-Dashboard-Migration (Issue #10/#26):** Schulden aus E1–E4 (hardcoded deutsche Strings in tools/*) in ARBs überführen; Dashboard-Widgets auf ThemeExtension umstellen.
8. **Golden-Tests (Issue #30):** visuelle Regression für Kern-Screens (dark+light) — schützt das Design-System.

## V0.9 — „Wiring an Use-Cases" (Hub-Modul-Slots über die Registry)

Bastis Ziel: interaktives Admin-Dashboard, in dem seine realen Workflows leben. Reihenfolge nach Nutzen/Abhängigkeit:

| Prio | Modul | Beschreibung / Anbindung | Hängt ab von |
|---|---|---|---|
| P1 | **System Monitor (ausbauen)** | E3 existiert (Prozesstabelle, CPU/RAM/Thermal-Tiles) → zu persistentem Dashboard ausbauen: Warnschwellen, History (Ringpuffer → Datei), Autostart-Option | nur E3-Verfeinerung |
| P1 | **Backup-System (Restic-Status)** | Restic-Snapshots/Timers/letzte Fehler lesend anzeigen (Bastis reale Restic-Lücke: 0 erfolgreiche Snapshots!) — Status-Kachel + Detail-Screen; Aktionen (snapshot now) via la-helper | #28, #29 |
| P2 | **Docker Watcher** | Container-Liste (docker ps --format json), Status/Badges, Logs-Tail, Start/Stop über la-helper | #28 |
| P2 | **Tokentelemetrie** | Bastis token-calc-Dashboard (20-Workspace) liefert Verbrauchsdaten → Modul liest dessen Export/SQLite und zeigt Tiles/Sparklines (HermesStatTile/Sparkline vorhanden!) | Datenvertrag mit token-calc |
| P3 | **Hermes Gateway Manager** | Status/Start/Stop/Restart des Hermes-Gateways (systemd --user), letzte Logs, API-Key-Rotation-Reminder | #29 |
| P3 | **Kanban Watcher (hermes kanban wrap)** | Watch auf Kanban-Board-Dateien (mtime/queue-Tiefen), Benachrichtigungen bei Blockern, Verlinkung ins Board | FileSystem-Watch |

**Architektur-Regel für V0.9:** jedes Modul = Registry-Eintrag + eigener Service (Dart, isoliert testbar wie `SystemMonitorService`) + optional la-helper-Action. Kein Modul schreibt direkt Shell-Befehle in Widgets.

## Was aus PR #24 / offenen Issues aufgeht

- **PR #24 (Implementierungsplan v0.8.5):** ersetzt durch dieses Dokument — schließen mit Verweis. Inhaltlich aufgegangen in V0.8.0/V0.8.X.
- **Issue #25 (l10n `_tr`)** → V0.8.X.7 · **#26/#10 (MintYColors-Migration)** → V0.8.X.7 · **#27 (Tool-Registry)** → V0.8.X.4 · **#28 (la-helper)** → V0.8.X.5 · **#29 (D-Bus Systemd)** → V0.8.X.6 · **#30 (Goldens)** → V0.8.X.8.

## Nicht-Ziele / bewusst draußen

- Kein Upstream-PR (44 Commits Distanz, Upstream dormat bei 0.6.2) — fork-only, deb ist der einzige gepflegte Paketweg (rpm/flatpak/arch → `packaging/unmaintained/`).
- Keine Neuentwicklung eines Widget-Frameworks: HermesTokens + MintYColors zusammenführen/institutionalisieren stattdessen (Entscheidung in V0.8.X.7 treffen).
