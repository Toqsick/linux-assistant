# Implementierungsplan: Admin-Hub v0.8.5

> Vollständiger Umsetzungsplan auf PR-Ebene. Baut auf
> `feature-spec-admin-hub.md`, `milestone-v0.7.2.md` und
> `roadmap-admin-hub-kernmodule.md` auf.
> **Zielversion: v0.8.5** — Phasen: v0.7.2 (Gate) → v0.8.0 → v0.8.2 → v0.8.5.

## 0. Rahmenbedingungen

### Arbeitsweise

- Ein PR pro Arbeitspaket, Branch-Konvention `feature/m<x>-<name>` bzw. `fix/…`, `docs/…`
- Issues sind deaktiviert → Tracking über dieses Dokument + Draft-PRs
- Jeder PR enthält: Scope-Tabelle (Dateien), Verifikations-Block, l10n-Keys, Doku-Update

### Definition of Done (global, pro PR)

- [ ] `flutter analyze` sauber, `flutter test` grün (CI-Gate)
- [ ] Statische Parser + Fixture-Tests (E3/E4-Standard), kein Prozess-Mocking
- [ ] l10n: echte `.arb`-Keys (de/en), kein `_tr()`-Pattern
- [ ] polkit-Action dokumentiert (falls Schreibzugriff), `needsRoot` im Tool-Deskriptor
- [ ] Destructive Actions: Confirm-Dialog mit vollem Ziel (E4-Muster)
- [ ] Manueller Check auf Zorin OS 18 vor Merge

### Aufwands-Konvention

`d` = Entwicklertag bei voller Konzentration. Summen enthalten Tests.

---

## 1. Phase P0 — v0.7.2 schließen (blockierend, ~3,5 d)

Kein neues Modul vor Abschluss — sonst erbt jedes den `_tr()`-Hack und
unverifizierte Basis.

| PR | Inhalt | Aufwand | Abhängigkeiten |
|---|---|---|---|
| P0-1 | l10n-Migration: `.arb`-Keys (de/en) für Hub/Werkzeuge, `flutter gen-l10n`, `_tr()` entfernen | 1 d | — |
| P0-2 | Verifikation Epic-PRs #12–#21: `flutter analyze`/`test` + manuelle Checks pro Tool, Ergebnis in `admin-hub-followups.md` abhaken | 0,5 d | — |
| P0-3 | PR #10 abschließen: Dashboard-Widgets auf `MintYColors`, Mutations-Hack in `single_bar_chart.dart` entfernen | 1 d | — |
| P0-4 | `golden_toolkit` als dev-Dependency, Baselines für QuickNotes/FileManager/SystemMonitor generieren | 0,5 d | P0-1 |
| P0-5 | Release v0.7.2: `version`-Bump, Tag, Packaging (deb/rpm/Flatpak), Install-Test Zorin OS 18, Branch-Cleanup | 0,5 d | P0-1…P0-4 |

**Exit-Kriterium:** v0.7.2 getaggt, installierbar, Tests + Goldens grün, ≤5 aktive Branches.

---

## 2. Phase P1 — v0.8.0 „Ops-Kern" (~9 d)

### 2.1 M7 — Berechtigungsmodell (Fundament, zuerst)

| PR | Inhalt | Dateien | Aufwand |
|---|---|---|---|
| M7-1 | Privilegierter Helper: ein Binary-Skript `la-helper`, JSON-lines-Protokoll (v1), Exit-Codes (0/2/3/4), alle bestehenden `pkexec`-Calls darauf umgestellt | `additional/helper/la_helper.py`, `lib/services/privileged_helper.dart`, Tests | 2 d |
| M7-2 | polkit-Paketierung: `50-linux-assistant.rules`, `.policy` um `org.linux-assistant.helper.*`/`updates.*`/`ufw.*` erweitern, Einbau in deb/rpm/PKGBUILD/Flatpak | `additional/polkit/`, Packaging-Skripte | 0,5 d |
| M7-3 | `AuthorizationService`: `CheckAuthorization`-Wrapper, Rollen-Cache (`la-viewer`/`la-operator`/`la-admin`), `ValueListenable<AuthState>`, Rollen-Badge + UI-Gating in Hub-Shell | `lib/services/authorization_service.dart`, `hub_shell.dart`, Tests mit Fake-Authority | 1 d |

polkit-Regel (Referenz, wird in M7-2 installiert):

```javascript
// /etc/polkit-1/rules.d/50-linux-assistant.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (subject.isInGroup("la-operator") || subject.isInGroup("la-admin")))
        return polkit.Result.YES;
    if (action.id.indexOf("org.linux-assistant.") === 0 &&
        subject.isInGroup("la-admin"))
        return polkit.Result.AUTH_ADMIN_KEEP;
});
```

**Akzeptanz:** Aktion ohne Gruppe → polkit-Dialog/sauberes Deny; Gruppenänderung ohne
Neustart sichtbar; CI-Gate `grep -rn pkexec lib/ additional/` liefert nur den Helper-Pfad.

### 2.2 Tool-Registry (parallel zu M7)

| PR | Inhalt | Dateien | Aufwand |
|---|---|---|---|
| M7-4 | Deklarative Tool-Deskriptoren (`id`, `icon`, `order`, `conditions`, `needsRoot`, `requiredGroup`, `pollingBudgetMs`) + Conditions-Evaluator; Hub-Shell von `HubTool`-Enum auf Registry umstellen; Bestandstools (E1–E4) migrieren | `lib/services/tool_registry.dart`, `lib/models/tool_descriptor.dart`, `hub_shell.dart`, Tests | 1 d |

Vorbild: Cockpit `manifest.json` — Tools erscheinen nur, wenn `conditions` erfüllt sind
(Generalisierung des E3-nvidia-smi-Patterns).

### 2.3 M1 — Systemd-Diensteverwaltung

| PR | Inhalt | Dateien | Aufwand |
|---|---|---|---|
| M1-1 | `SystemdService`: D-Bus-Client (`org.freedesktop.systemd1`: `ListUnits`, `GetUnit`, `StartUnit`, `StopUnit`, `RestartUnit`, `EnableUnitFiles`, `DisableUnitFiles`, `MaskUnitFiles`, `Reload`), Signal-Subscriptions (`UnitNew`/`JobRemoved`), systemctl-JSON-Fallback, Fixtures | `lib/services/systemd_service.dart`, `test/systemd_service_test.dart` | 1,5 d |
| M1-2 | Service-Manager-Screen: Tabelle (Name/State/Sub/Description), Typ-/State-/Failed-Filter, Suche, Aktions-Bar mit Rollen-Gating, Confirm-Dialoge mit Unit-Name | `lib/layouts/tools/service_manager.dart`, Widget-Tests | 1,5 d |
| M1-3 | Boot-Tab: `systemd-analyze blame` + `critical-chain` Parser + Darstellung | `lib/services/boot_analysis.dart`, Screen-Tab, Fixtures | 0,5 d |

**Akzeptanz:** Failed-Units <2 s sichtbar; polkit-Dialog für Nicht-Operatoren; keine
Signal-Leaks beim Screen-Wechsel (TickerMode-Prinzip).

### 2.4 M3 — Journal-Log-Viewer (parallelisierbar zu M1)

| PR | Inhalt | Dateien | Aufwand |
|---|---|---|---|
| M3-1 | `JournalService`: `journalctl -o json` Streaming, RingBuffer (Speicher-Deckelung, 5k Einträge), Priority-/Unit-/Boot-Filter, Parser-Fixtures | `lib/services/journal_service.dart`, Tests | 1 d |
| M3-2 | Log-Viewer-Screen: Filter-Bar, Tabelle, Volltextsuche, Follow-Mode mit Pause, Export `.log` | `lib/layouts/tools/log_viewer.dart`, Widget-Tests | 1,5 d |
| M3-3 | `coredumpctl`-Tab + `systemd-journal`-Membership-Check mit Inline-Banner und Fix-Flow (`pkexec usermod -aG`, Re-Login-Hinweis) | Service-Erweiterung, Banner-Widget | 0,5 d |

**Non-Goals:** kein journald-Config-Editor, kein Remote-Journal.

### 2.5 Release v0.8.0 (0,5 d)

Version-Bump, Changelog, Packaging, Install-Test Zorin OS 18, polkit-Matrix manuell
durchgespielt (Viewer/Operator/Admin × jede Aktion).

---

## 3. Phase P2 — v0.8.2 „Netz & Pflege" (~5,5 d)

| PR | Modul | Inhalt | Aufwand | Abhängigkeiten |
|---|---|---|---|---|
| M5-1 | M5 Firewall | `UfwService`: Parser für `ufw status numbered`, `ufw app list`, Regel-Modell; read-only Screen | 1 d | M7-4 |
| M5-2 | M5 | Schreibaktionen via Helper (`org.linux-assistant.ufw.*`): allow/deny/limit, Delete nach Rule-Number, Default-Policies, Logging-Level, Confirm-Dialoge | 1,5 d | M5-1, M7-1 |
| M6-1 | M6 Updates | `UpdatePolicyService`: apt.conf.d-Parser/Writer (Drop-in `52unattended-upgrades-local`, nie die 50er-Datei), Status aus `/var/log/unattended-upgrades/`, Pending via `pkcon get-updates` | 1 d | M7-1 |
| M6-2 | M6 | Updates-Screen: Status-Kachel, Security-only-Toggle, Reboot-Policy mit Zeitfenster, Blacklist-Editor, „Jetzt aktualisieren", Flatpak-User-Timer; Migration für `setup_automatic_updates_debian.py`-Nutzer | 1 d | M6-1 |
| M2-1 | M2 Alerting | Alert-Layer: `MintYThresholds` + failed units + SMART → freedesktop-Notification; Watchdog im `SystemStatsService` | 1 d | — |
| — | Release | v0.8.2: Bump, Packaging, Install-Test | 0,5 d | alle P2 |

---

## 4. Phase P3 — v0.8.5 „Workloads" (Zielversion, ~6 d)

| PR | Modul | Inhalt | Aufwand | Abhängigkeiten |
|---|---|---|---|---|
| M4-1 | M4 Container | `ContainerService`: HTTP über Unix-Socket `$XDG_RUNTIME_DIR/podman/podman.sock`, Modelle (Container/Image/Stats), Socket-Aktivierung (`systemctl --user enable --now podman.socket`) mit User-Consent | 1,5 d | M7-4 |
| M4-2 | M4 | Container-Screen: Liste, Stats-Stream, Logs-View, Start/Stop/Restart; read-mostly, Pull/Prune explizit v2 | 1,5 d | M4-1 |
| M4-3 | M4 | Docker-Fallback `/var/run/docker.sock` mit Warn-Banner (docker-Gruppe = root-äquivalent), Descriptor-`conditions` für Socket-Pfade | 0,5 d | M4-2 |
| M2-2 | M2 History | SQLite-Ringbuffer (7 Tage, 60-s-Aggregate), Verlaufs-Charts im Systemmonitor | 1,5 d | — |
| BK-1 | Backup | Snapshot-Management: Liste/Restore/Schedule für Timeshift/Snapper via Helper, baut auf `setup_automatic_snapshots.py` | 2 d | M7-1 |
| — | Release | **v0.8.5**: Bump, Changelog, Packaging, Volltest-Matrix, Wiki-Update | 0,5 d | alle P3 |

**Exit-Kriterium Zielversion:** Admin-Hub feature-complete — Dienste, Logs, Updates,
Firewall, Container, Monitoring mit History, RBAC durchgesetzt.

---

## 5. Cross-cutting Arbeitspakete (laufend)

| Paket | Inhalt | Wann |
|---|---|---|
| CI-1 | Packaging-Matrix im CI (deb/rpm/Flatpak-Build pro PR) | ab P1 |
| CI-2 | Release-Workflow: Tag → Artifacts → Changelog aus `version` | vor v0.8.0 |
| CI-3 | Secret-Scanning + pkexec/polkit-Inventar-Gate | mit M7-1 |
| SEC-1 | `SECURITY.md` mit Disclosure-Kontakt, Audit-Log-Konzept (polkit-Journal + Helper-Log) | mit M7-2 |
| DOC-1 | Wiki-Seiten pro neuem Modul (Muster: `Admin-Hub.md`) | pro Phase |
| REF-1 | `linux.dart` schrittweise entkernen: jede Domäne, die ein Modul anfassen muss, wird in einen Service extrahiert (kein Big Bang) | laufend |

---

## 6. Teststrategie

| Ebene | Umfang | Werkzeug |
|---|---|---|
| Unit | Alle Parser mit Fixtures (`/proc`, journalctl-JSON, ufw, apt.conf.d, ListUnits-Payloads); Helper-Protokoll Roundtrip | `flutter test`, pytest |
| Widget | Screens mit Fake-Services (Muster: `NotesService.test(dir)`), Rollen-Gating mit Fake-Authority | `flutter test` |
| Golden | Neue Screens nach P0-4-Baseline, 3 Akzente (mint/debian/zorin) | golden_toolkit |
| Integration | M1 gegen systemd im Container (`--privileged`, systemd-Image); Helper gegen throwaway-VM/Container | Docker, manuell |
| Manuell | Matrix: Zorin OS 18 (primär), Ubuntu 24.04, Fedora (rpm), Arch (PKGBUILD); polkit-Rollen-Matrix pro Release | Checkliste im Release-PR |

---

## 7. Risiken & Mitigationen

| Risiko | Eintritt | Mitigation |
|---|---|---|
| Dart-D-Bus-Bindings unzureichend (M1) | Mittel | systemctl-JSON-Fallback ist ohnehin geplant; Parser bleiben austauschbar |
| polkit-Verhalten divergiert über Distros (alte pkla-Systeme) | Niedrig | Ziel: moderne Distros mit JS-Rules; Support-Matrix dokumentieren |
| Flutter/GLIBC-Toolchain-Problem (bekannt, README) | Bekannt | SDK-Tarball-Methode; CI pinnt Flutter-Version |
| Scope-Creep bei „komplettem Admin-Hub" | Hoch | Non-Goals pro Modul sind verbindlich; v2-Kandidaten nur ins Backlog-Dokument |
| Single-Maintainer-Kapazität | Hoch | PR-Granularität klein halten; Copilot-Agenten für Boilerplate (Muster aus #1–#6) |
| Rootless-Podman-Socket nicht vorhanden | Mittel | Descriptor-`conditions` (path-exists) + Setup-Anleitung im Screen |

---

## 8. Zeitplan & Kapazität

| Phase | Aufwand | Kalender (1 Dev, ~50 % Kapazität) |
|---|---|---|
| P0 — v0.7.2 | 3,5 d | Woche 1 |
| P1 — v0.8.0 | 9 d | Woche 2–4 |
| P2 — v0.8.2 | 5,5 d | Woche 5–6 |
| P3 — v0.8.5 | 6 d | Woche 7–9 |
| Puffer/Releases | 2 d | Woche 9–10 |

**Gesamt: ~26 Entwicklertage ≈ 9–10 Kalenderwochen bis v0.8.5.**

---

## 9. PR-Sequenz (Abhängigkeitsgraph)

```
P0-1 ──> P0-4 ──> P0-5 (Release v0.7.2)
P0-2 ──┘         P0-3 ──┘

M7-1 ──> M7-2 ──> M7-3 ──┐
M7-4 ────────────────────┼──> M1-1 ──> M1-2 ──> M1-3 ──┐
                         └──> M3-1 ──> M3-2 ──> M3-3 ──┴──> Release v0.8.0

M7-1 ──> M5-1 ──> M5-2 ──┐
M7-1 ──> M6-1 ──> M6-2 ──┼──> Release v0.8.2
         M2-1 ───────────┘

M7-4 ──> M4-1 ──> M4-2 ──> M4-3 ──┐
         M2-2 ────────────────────┼──> Release v0.8.5 (Zielversion)
M7-1 ──> BK-1 ────────────────────┘
```

Parallelisierung: M3 neben M1, M2-1/M2-2 jederzeit, M4-1 sobald M7-4 steht.

## Quellen

- polkit JS-Rules & Admin-Identities: ArchWiki polkit, SUSE Security Guide
- Cockpit: Privileg-Modell, `manifest.json`-Paketystem (cockpit-project.org/guide)
- Webmin Security-Historie: ACL-Bypass <2.653 (webmin.com/security)
- Netdata: Privileg-Trennung pro Plugin (Capabilities statt Root)
- Podman: `podman system service`, rootless Socket (docs.podman.io)
- unattended-upgrades: Ubuntu Server Docs „Automatic updates"
