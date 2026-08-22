# Milestone v0.7.2 – „Admin-Hub"

> Typ: Feature-Release (Minor-Inhalt, Patch-Nummer) · Stand: 2026-08-22
> Vorgänger: v0.7.1 (visuelle Baseline) · Spec: `docs/design/feature-spec-admin-hub.md`
> Nacharbeiten-Detail: `docs/design/admin-hub-followups.md`
>
> Hinweis: GitHub-Milestones sind in diesem Repo nicht verfügbar (Issues
> deaktiviert). Dieses Dokument ist der Milestone – versioniert, reviewbar,
> im gleichen Prozess wie Spec und Followups.

---

## 1. Zielbild

Das Dashboard wird vom Status-Viewer zum **Admin-Hub**: die vier häufigsten
Administrations-Werkzeuge sitzen direkt in der Sidebar – ohne Kontextwechsel
zu Terminal oder externen Apps. Alle Werkzeuge laufen im Hub-Frame (kein
Navigator-Wachstum), behalten ihren Zustand über Bereichswechsel
(IndexedStack) und kosten im Hintergrund keine Ressourcen (Stats-Gating,
Ticker-basiertes Sampling).

```
Sidebar v0.7.2
┌──────────────────┐
│ ⊞  Dashboard     │
│ 🔍 Suche         │
│ ☰  Speicher      │
│ ♥  Linux-Gesundh.│
│ 🛡  Sicherheit   │
│ ── WERKZEUGE ──  │
│ 🌐 Browser       │  → externer Launch (Brave → Fallback-Kette)
│ 📝 Quick Notes   │  → Markdown-Notizen, Autosave, XDG-konform
│ 📁 Dateimanager  │  → eingebettet, Systempfad-Schutz
│ 📊 Systemmonitor │  → 1-s-Live, Per-Core, Prozess-Verwaltung
│ ⚙  Einstellungen │
└──────────────────┘
```

---

## 2. Scope – was in v0.7.2 drin ist

### 2.1 Bereits gemergt (Stand main)

| PR | Inhalt | Merge |
|---|---|---|
| #12 | Admin-Hub Feature-Spec (Grundlage, Scope-Grenzen, Design-Tokens) | `c255389` |
| #13 | **E1** Browser-Launcher-Service: Fallback-Kette `brave` → `brave-browser` → `xdg-open`, deaktiviertes Nav-Item wenn nicht gefunden, Tests | `653abe3` |
| #14 | Werkzeuge-Sektion in der Sidebar (Label-Stil wie „EINGEBUNDENE DATENTRÄGER"), Browser-Verkabelung mit Snackbar-Feedback, `_tr()`-Übergangs-l10n | `8ed53f7` |
| #15 | **E2** Quick Notes: `NotesService` (atomare Writes tmp+rename, XDG-Speicherort `~/.local/share/linux-assistant/notes/`), Master-Detail-Screen, Autosave 500 ms debounced, Delete mit Confirm, 12 Tests | `047e816` |
| #17 | Screen-Tool-Architektur: `HubTool` neben `HubSection`, `_screenTool`-Overlay, `Map<Object, Widget>` + IndexedStack (Zustand bleibt), Stats-Gating für Tool-Screens | `1ad3d73` |
| #18 | **E4** Dateimanager: `FileBrowserService` (dart:io, `followLinks: false`, Protected-Policy `/proc` `/sys` `/dev`), Breadcrumb + Schnellzugriff, Delete-Confirm mit vollem Pfad, 15 Tests | `dd4f4bd` |
| #19 | **E3** Systemmonitor: reine Parser (`/proc/stat`, `meminfo`, `net/dev`, Thermal, `ps`, `nvidia-smi`), 1-s-Sampling via Ticker (stoppt off-screen via TickerMode), Ringpuffer-Sparklines, sortierbare Prozess-Tabelle mit SIGTERM/SIGKILL-Confirm, 18 Tests | `336bc9a` |
| #21 | Test-Suite-Fixes: cpuUsageDelta-Erwartung (31.43 %/10.68 %, verifiziert), modeString 9-Char-Semantik, Golden-Test ohne deklarierte Dependency entfernt | `66db135` |
| #20 | Nacharbeiten-Checkliste (Verifikation, l10n-Snippets, Golden-Reaktivierung, Branch-Cleanup) | `fd454c0` |

### 2.2 Architektur-Errungenschaften (über Einzelfeatures hinaus)

- **Screen-Tool-Pattern:** Neue Werkzeuge = 4 kleine Edits in `hub_shell.dart`
  (Enum, Icon/Titel, `_onToolTap`, `_contentFor`). Dokumentiert in #17.
- **Kein Idle-Polling:** Shared-Stats (3 s) nur auf Stats-Sections und nur bei
  sichtbarem Fenster; Systemmonitor sampled per Ticker nur on-screen.
  Gemessene Basis aus `d221d0e`: 0.10 forks/s idle statt 4.4 forks/s.
- **Testbarkeit:** Alle Services mit injizierbaren Konstruktoren
  (`NotesService.test`, `FileBrowserService`, `SystemMonitorService` mit
  `FileReader`), alle Parser rein und fixture-getestet.

---

## 3. Offene Arbeiten bis zum Release (Gate)

Alle Punkte aus `docs/design/admin-hub-followups.md` – hier als
Release-kritische Tasks mit Akzeptanzkriterien:

### 3.1 Verifikation (blockierend)

| Task | Akzeptanzkriterium |
|---|---|
| `flutter analyze` auf main | 0 Errors (Warnings: bestehender Backlog, kein neuer) |
| `flutter test` auf main | 128 passed, 0 failed (CI-Run auf `66db135` oder neuer) |
| Manuelle Checks der 4 Werkzeuge | Alle Checkboxen in followups §1 abgehakt |
| Performance-Check | Systemmonitor off-screen → kein 1-s-Polling (TickerMode); Quick Notes/Dateimanager aktiv → Shared-Poll aus |

### 3.2 l10n (blockierend für Release, nicht für main)

| Task | Akzeptanzkriterium |
|---|---|
| `.arb`-Keys eintragen (Snippets in followups §2) | `flutter gen-l10n` läuft, App startet de + en |
| `_tr()` in `hub_shell.dart` ersetzen | Helper gelöscht, `l10n.*` überall |
| Screen-Texte (quick_notes, file_manager, system_monitor) | Keine harten deutschen Strings mehr |

### 3.3 Golden-Baselines (nicht blockierend, kann in v0.7.3)

| Task | Akzeptanzkriterium |
|---|---|
| `golden_toolkit` als dev-Dependency | pubspec + lockfile committed |
| `layout_golden_test.dart` wiederhergestellt + const-Fixes | Suite lädt (Schritte in followups §3) |
| Baselines der 3 neuen Screens | PNGs committed, CI grün |

---

## 4. Non-Goals (bewusst NICHT in v0.7.2)

| Thema | Wo es lebt |
|---|---|
| Dashboard-Token-Migration (`MintYColors` ThemeExtension) | PR B, Tracker #10 |
| Quick Notes: Markdown-Preview, Sync/Cloud | v2-Kandidat (Spec §3) |
| Dateimanager: Copy/Move/Rename, Thumbnails, Drag&Drop, Tabs | v2-Kandidat (Spec §4) |
| Systemmonitor: AMD/Intel-GPU, Per-Interface-Sparklines | v2-Kandidat (Spec §5) |
| Settings-State-String → echte Routen | PR C (Design-Audit-Empfehlung) |
| `flutter analyze`-Backlog (189 pre-existing Findings) | separater Track, siehe `1e90957` |

---

## 5. Definition of Done (Release-Gate)

v0.7.2 darf getaggt werden, wenn:

1. ✅ Alle Epic-PRs gemergt (erledigt: #12–#21)
2. ⬜ CI auf main grün: `flutter test` 128/0, Packaging-Steps laufen
3. ⬜ Manuelle Verifikation der 4 Werkzeuge abgehakt (followups §1)
4. ⬜ l10n abgeschlossen (§3.2) – kein `_tr()` mehr im Tree
5. ⬜ `version`-Datei auf `0.7.2` gebumpst (einzige Source of Truth,
   Packaging liest daraus – siehe `1e90957`)
6. ⬜ Changelog-Eintrag (siehe §6.2)
7. ⬜ .deb baut und auf Zorin OS 18 installiert (`apt install ./…deb`),
   App startet in den Hub, Hotkey (Super+Q) funktioniert

---

## 6. Release-Prozess

### 6.1 Version & Tag

```bash
echo "0.7.2" > version
git add version && git commit -m "release: v0.7.2"
git tag -a v0.7.2 -m "Admin-Hub: Werkzeuge-Sektion (Browser, Quick Notes, Dateimanager, Systemmonitor)"
git push origin main --tags
```

### 6.2 Changelog (Vorlage)

```markdown
## v0.7.2 – Admin-Hub

### Neu
- Werkzeuge-Sektion in der Sidebar mit vier Tools
- Browser-Launch mit Fallback-Kette (Brave → xdg-open), konfigurierbar
- Quick Notes: Markdown-Notizen mit Autosave, lokal unter XDG_DATA_HOME
- Dateimanager: eingebetteter Browser mit Breadcrumb, Schnellzugriff,
  sicherem Löschen (Confirm mit Pfad) und Schreibschutz für /proc, /sys, /dev
- Systemmonitor: 1-s-Live-Ansicht (CPU per Core, RAM/Swap, Disks, Netzwerk,
  Thermals, optional NVIDIA-GPU), sortierbare Prozess-Tabelle mit
  SIGTERM/SIGKILL, pausierbar, pollt nicht im Hintergrund

### Fixes
- Test-Suite: 3 Failures behoben (Erwartungswerte, Golden-Test-Setup)

### Intern
- Screen-Tool-Architektur in der Hub-Shell (IndexedStack, Stats-Gating)
- 45 neue Tests (Notes, FileBrowser, SystemMonitor)
```

### 6.3 Packaging

```bash
bash ./build-deb.sh   # erzeugt linux-assistant_0.7.2_amd64.deb (+ Alias .deb)
bash ./build-rpm.sh   # RPM unter ~/rpmbuild/RPMS/
```

CI baut bei Tag-Push die Artefakte (ubuntu-24.04-gepinnt seit `d221d0e`).
Flatpak bleibt eigenständiger Track (separates Repo).

---

## 7. Risiken & Mitigationen

| Risiko | Eintritt | Mitigation |
|---|---|---|
| l10n bleibt offen → Release mit `_tr()` | mittel | `_tr()` deckt de/en korrekt ab; Release wäre funktional, aber nicht sauber → als blockierend markiert (§5.4) |
| Golden-Baselines fehlen weiter | hoch | bewusst nicht blockierend; manuelle Verifikation + Suite-Tests tragen v0.7.2 |
| `window_manager`-Verhalten auf exotischen WMs (Sway etc.) | niedrig | doppelte Sichtbarkeits-Signale (WindowListener + WidgetsBindingObserver) bereits in `d221d0e` |
| nvidia-smi auf Nicht-NVIDIA-Kisten | keins | `which`-Probe einmalig, Kachel erscheint nur bei Vorhandensein |
| Delete-Unfall im Dateimanager | niedrig | Confirm mit vollem Pfad + Protected-Policy + Symlinks nie folgen |

---

## 8. Schrittfolge (Empfehlung)

1. CI-Run auf `66db135`+ grün bestätigen
2. Manuelle Verifikation (followups §1) abhaken
3. l10n-PR (lokal vorbereitet, Snippets aus followups §2)
4. Version-Bump + Tag (§6.1)
5. Release bauen, installieren, Smoke-Test
6. Danach erst: PR B (#10) und Goldens für v0.7.3 einplanen

---

## Referenzen

- Spec: `docs/design/feature-spec-admin-hub.md`
- Nacharbeiten: `docs/design/admin-hub-followups.md`
- Design-System: `docs/design/linux-assistant-design-system.md`
- Golden-Setup: `docs/design/screenshot-baseline.md`
- Epic-PRs: #12–#21
