# Roadmap: Admin-Hub Kernmodule (M1, M3, M6, M7)

> Ergänzt `feature-spec-admin-hub.md` (E1–E4) und `milestone-v0.7.2.md`.
> Scope dieses Dokuments: Systemd-Diensteverwaltung, Journal-Log-Viewer,
> Paket-Updates, Berechtigungsmodell. Container, Firewall und Monitoring-v2
> folgen in einem separaten Dokument (v1.0-Planung).
>
> **Zielversion: v0.8.5** — mit diesem Release sind die Kernmodule
> feature-complete. Phasen: v0.7.2 (Gate) → v0.8.0 (Ops-Kern) → v0.8.5 (Pflege & Ziel).

## Zielbild

Der Hub wird vom Monitoring- und Convenience-Werkzeug zur vollwertigen
Admin-Oberfläche: Dienste verwalten, Logs lesen, Updates kontrollieren —
mit einem Berechtigungsmodell, das Enforcement ins System (polkit) verlegt
statt in die UI.

Leitprinzipien (unverändert):

- **CLI-first:** jedes Feature wrappt ein reales CLI-/D-Bus-Backend, kein
  internes Nachbauen von Systemlogik
- **Read-only zuerst:** jede Schreibaktion braucht eine deklarierte
  polkit-Action und einen Confirm-Dialog
- **Parser-testbar:** statische Parser + Fixtures wie bei E3/E4, kein
  Mocking von Prozessen im Test
- **Screen-Tool-Pattern:** Registrierung über Tool-Deskriptor
  (`conditions`, `order`, `needsRoot`), nicht über hartcodierte Enums

## Architektur-Matrix

| Modul | Backend / Datenquelle | Privileg / polkit-Action | Aufwand | Phase | Baut auf |
|---|---|---|---|---|---|
| M7 Berechtigungsmodell | Unix-Gruppen + polkit-JS-Rules, `CheckAuthorization` im Client | `/etc/polkit-1/rules.d/50-linux-assistant.rules` + eigene Actions `org.linux-assistant.*` | 3–4 d | v0.8.0 (zuerst) | `org.linux-assistant.operations.policy` |
| M1 Systemd-Dienste | `org.freedesktop.systemd1` D-Bus (`ListUnits`, `StartUnit`, `EnableUnitFiles`, …), Fallback `systemctl --output=json` | System-Actions `org.freedesktop.systemd1.manage-units` / `.manage-unit-files` — kein eigener Helper nötig | 3–4 d | v0.8.0 | M7, Screen-Tool-Pattern |
| M3 Journal-Viewer | `journalctl -o json` (`-b`, `-p`, `-u`, `--since`, `-f`), `coredumpctl` | Gruppe `systemd-journal` (kein polkit); Membership-Check + Fix-Flow | 2–3 d | v0.8.0 | Run-Command-Infrastruktur |
| M6 Paket-Updates | unattended-upgrades Drop-ins in `/etc/apt/apt.conf.d/`, Status aus `/var/log/unattended-upgrades/`, Pending via `pkcon get-updates`; Flatpak via systemd-User-Timer | `org.linux-assistant.updates.*` (eigene Actions via M7-Helper) | 2 d | v0.8.5 | M7, `additional/python/setup_automatic_updates_debian.py` |

Kritischer Pfad: **M7 vor M1/M6** — alle Schreibaktionen laufen über den
konsolidierten polkit-Helper. M3 ist unabhängig und parallelisierbar.

---

## M7 — Berechtigungsmodell (Fundament)

### Konzept

Auf einem Desktop-System ist RBAC kein App-internes Rollenmodell, sondern
Unix-Gruppen + polkit-Regeln. Drei Rollen:

| Rolle | Gruppe | Rechte |
|---|---|---|
| Viewer | `la-viewer` | Read-only: Monitoring, Logs (soweit Gruppenrechte reichen), Status. Keine polkit-Freigaben |
| Operator | `la-operator` | + Services starten/stoppen/neustarten, Updates anstoßen |
| Admin | `la-admin` | + Enable/Disable/Mask, Update-Konfiguration, Helper-Aktionen |

### polkit-Regeln

```javascript
// /etc/polkit-1/rules.d/50-linux-assistant.rules
polkit.addRule(function(action, subject) {
    // Operator: Unit-Lifecycle, aber keine Unit-Dateien
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (subject.isInGroup("la-operator") || subject.isInGroup("la-admin"))) {
        return polkit.Result.YES;
    }
    // Admin: eigene Helper-Aktionen, mit Auth-Caching pro Session
    if (action.id.indexOf("org.linux-assistant.") === 0 &&
        subject.isInGroup("la-admin")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
    }
});
```

### Enforcement-Prinzip

- Rechteprüfung ausschließlich in polkit/Helper. Die App fragt über
  `org.freedesktop.PolicyKit1.CheckAuthorization` ab und gated damit nur
  die UI (ausgegraute Aktionen, Rollen-Badge in der Top-Bar).
- Begründung: Webmins CVE-Historie (ACL-Bypass in mehreren Modulen,
  <2.653) zeigt, dass dezentrale, modul-eigene Rechteprüfung scheitert.
- Bestehende verstreute `pkexec`-Calls werden in einen einzigen
  privilegierten Helper konsolidiert; eine polkit-Action pro Operation.

### Dateien

| Datei | Inhalt |
|---|---|
| `lib/services/authorization_service.dart` | `CheckAuthorization`-Wrapper, Rollen-Cache, `ValueListenable<AuthState>` |
| `additional/polkit/50-linux-assistant.rules` | Regel-Datei (per Package installiert) |
| `org.linux-assistant.operations.policy` | um Actions `updates.*`, `helper.*` erweitern |
| `test/authorization_service_test.dart` | Fake-Authority: Rollen-Matrix, UI-Gating-Entscheidungen |

### Akzeptanzkriterien

- [ ] Aktion ohne Gruppenmitgliedschaft → polkit-Dialog bzw. sauberes Deny, kein Crash
- [ ] UI zeigt Rollen-Zustand ohne Neustart (Gruppenänderung → Re-Check)
- [ ] `grep -rn pkexec lib/ additional/` liefert nur noch den Helper-Pfad (CI-Gate)

---

## M1 — Systemd-Diensteverwaltung

### Backend

D-Bus statt systemctl-Parsing: keine Forks pro Aktion, polkit-Integration
systemseitig vorhanden, Echtzeit-Events via `UnitNew`/`JobRemoved`-Signals.

```bash
busctl call org.freedesktop.systemd1 /org/freedesktop/systemd1 \
  org.freedesktop.systemd1.Manager ListUnits
busctl introspect org.freedesktop.systemd1 /org/freedesktop/systemd1
```

### Scope v1

- Unit-Liste (Typ-, State-, Failed-Filter, Suche)
- Start / Stop / Restart (Operator), Enable / Disable / Mask (Admin)
- Unit-Details: Properties, `ExecStart`, Abhängigkeiten
- Boot-Tab: `systemd-analyze blame` + `critical-chain` (read-only)

### Non-Goals (v1)

- Kein Unit-File-Editor, kein `systemctl edit` (v2)
- Keine User-Units (`--user`) — separater PR, eigener Session-Bus

### Dateien

| Datei | Inhalt |
|---|---|
| `lib/services/systemd_service.dart` | D-Bus-Client, statische Parser für systemctl-Fallback, Fixture-testbar |
| `lib/layouts/tools/service_manager.dart` | Screen: Tabelle + Filter + Aktions-Bar, Confirm-Dialoge mit Unit-Name |
| `test/systemd_service_test.dart` | Fixtures: ListUnits-Payloads, Failed-States, polkit-Deny-Pfad |

### Akzeptanzkriterien

- [ ] Failed-Units sind <2 s nach Screen-Öffnen sichtbar
- [ ] Start/Stop triggert polkit-Dialog für Nicht-Operatoren
- [ ] Screen verlassen → keine laufenden D-Bus-Signal-Subscriptions (TickerMode-Prinzip aus E3)

---

## M3 — Journal-Log-Viewer

### Backend

```bash
journalctl -b -p 3 -o json --no-pager        # strukturierte Einträge
journalctl -f -o json                        # Follow-Mode (Stream)
journalctl --list-boots --no-pager           # Boot-Selektor
coredumpctl list --no-pager                  # Crash-Tab
```

JSON-Output ist stabil parsebar — statische Parser + Fixtures wie bei E3.

### Privileg-Detail

System-Journal erfordert Gruppe `systemd-journal`. Kein polkit-Pfad —
stattdessen: Membership-Check beim Screen-Start, sonst Inline-Banner mit
Fix-Aktion (`pkexec usermod -aG systemd-journal $USER`, erfordert Re-Login
→ klar kommunizieren).

### Scope v1

- Filter: Priority (0–7), Unit, Boot, Zeitfenster (`--since`)
- Volltextsuche client-seitig über geladenem Fenster
- Follow-Mode mit Pause (Pattern aus Systemmonitor)
- Export der gefilterten Sicht als `.log`

### Non-Goals (v1)

- Kein `journald`-Config-Editor (`SystemMaxUse` etc. → Disk-Cleaner-Modul)
- Kein Remote-Journal (`systemd-journal-remote`)

### Dateien

| Datei | Inhalt |
|---|---|
| `lib/services/journal_service.dart` | Prozess-Streaming, JSON-Parser, RingBuffer (Speicher-Deckelung) |
| `lib/layouts/tools/log_viewer.dart` | Screen: Filter-Bar, Tabelle, Follow-Toggle |
| `test/journal_service_test.dart` | JSON-Fixtures, Prioritäts-Mapping, Stream-Abbruch |

---

## M6 — Paket-Updates & Automatisierung

### Backend

Zwei Dateien trennen: `20auto-upgrades` steuert **ob/wann**,
`50unattended-upgrades` **was/wie** (Origins, Reboot, Blacklist).
Nie die Paket-Datei editieren — eigenes Drop-in, überlebt Paket-Updates
und ist diffbar:

```bash
# /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";

# Drop-in statt 50er-Edit:
# /etc/apt/apt.conf.d/52unattended-upgrades-local
Unattended-Upgrade::Allowed-Origins { "${distro_id}:${distro_codename}-security"; };
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Package-Blacklist { "linux-image*"; };
```

Status-Datenquellen: `/var/log/unattended-upgrades/unattended-upgrades.log`,
Pending via `pkcon get-updates` bzw. `apt list --upgradable`.
Flatpak: systemd-User-Timer für `flatpak update -y`.

### Scope v1

- Status-Kachel: letzter Lauf, fehlgeschlagene Läufe, ausstehende Updates
- Konfiguration: Security-only vs. alle Origins, Reboot-Policy mit
  Zeitfenster, Paket-Blacklist (Editor mit Validierung)
- Aktion „Jetzt aktualisieren" (Operator, via M7-Helper)
- Flatpak-Auto-Update-Toggle (User-Timer anlegen/entfernen)

### Non-Goals (v1)

- Kein Snap-Refresh-Scheduling (Zorin-Priorität gering)
- Kein Update-Mechanismus für den Assistant selbst (bleibt `updater.dart`)

### Dateien

| Datei | Inhalt |
|---|---|
| `lib/services/update_policy_service.dart` | apt.conf.d-Parser/Writer (Drop-in), Log-Status-Parser |
| `lib/layouts/tools/software_updates.dart` | Screen: Status + Policy-Formular + Blacklist-Editor |
| `additional/python/` (Helper-Erweiterung) | privilegierte Writes via M7-Helper, JSON-lines-Protokoll |
| `test/update_policy_service_test.dart` | Roundtrip-Tests: Parse → Edit → Write → Parse |

---

## Phasenplan

| Phase | Inhalt | Gate |
|---|---|---|
| **P0 — v0.7.2 schließen** (blockierend) | l10n-`.arb`-Migration, Verifikation Epic-PRs, PR B (#10), Branch-Cleanup | Kein neues Modul vorher — sonst erbt jedes den `_tr()`-Hack |
| **P1 — v0.8.0 „Ops-Kern"** | M7 → M1 → M3 (M3 parallelisierbar); parallel Tool-Deskriptoren | Install-Test auf Zorin OS 18, polkit-Matrix manuell durchgespielt |
| **P2 — v0.8.5 „Pflege" (Zielversion)** | M6 + Alerting-Anbindung (ausstehende Security-Updates → Dashboard-Badge) | Upgrade-Pfad: bestehende `setup_automatic_updates_debian.py`-Nutzer werden auf Drop-in migriert; Kernmodule feature-complete |

Pro Modul gilt der E3/E4-Standard: statische Parser + Fixture-Tests,
polkit-Action dokumentiert, `needsRoot` im Tool-Deskriptor deklariert,
Golden-Test sobald die Baseline steht (`golden_toolkit`).

## Cross-cutting Anforderungen

- **Tool-Deskriptor einführen** (Vorbild Cockpit `manifest.json`):
  `id`, `icon`, `order`, `conditions` (z. B. `path-exists: journalctl`),
  `needsRoot`, `requiredGroup` — ersetzt die hartcodierte
  `HubTool`-Enum-Verdrahtung und macht M7-Gating deklarativ.
- **Helper-Protokoll:** Python-Helper sprechen versioniertes JSON-lines
  mit definierten Exit-Codes; SHA-256-Manifest der Helper im Package,
  Integritäts-Check beim Start (`hashing.dart` ausbauen).
- **l10n:** keine neuen Screens mit `_tr()` — `.arb`-Keys sind Teil der
  Definition of Done jedes Moduls.
- **Security:** `SECURITY.md` mit Disclosure-Kontakt; CI-Gate für
  `pkexec`-/polkit-Inventar (siehe M7-Akzeptanzkriterien).

## Trade-offs

- **D-Bus (M1):** robust gegen Locale-/Output-Drift, Signals gratis —
  kostet dbus-Dependency und aufwendigere Test-Fakes.
- **polkit statt App-Rollen (M7):** Enforcement im System, Session-Rechte
  wie bei SSH; Mehraufwand: Helper-Konsolidierung vor erstem Write-Feature.
- **Drop-in statt Config-Rewrite (M6):** konfliktfrei bei Paket-Updates;
  User mit handeditierter 50er-Datei brauchen Migrations-Hinweis im UI.
- **Gruppe statt polkit (M3):** journald-Rechte sind dateibasiert, nicht
  aktionsbasiert — der Re-Login-Zwang ist ein UX-Nachteil, den kein
  polkit-Trick weglöst.
- **Versionslinie 0.8.x statt 1.0:** Zielversion v0.8.5 hält die
  Kernmodule in einer Release-Linie; v1.0 bleibt für Container/Firewall/
  Monitoring-v2 und Stabilisierung reserviert.

## Quellen

- polkit Rules & Admin-Identities: ArchWiki polkit, SUSE Security Guide
- Cockpit Privileg-Modell & Manifest-System: cockpit-project.org/guide
- unattended-upgrades: Ubuntu Server Docs „Automatic updates"
- Webmin Security-Historie (ACL-Bypass <2.653): webmin.com/security
- Netdata Privileg-Trennung pro Plugin: netdata collector architecture
