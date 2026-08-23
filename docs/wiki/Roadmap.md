# Roadmap

Stand: 2026-08-22. Tracking-Dokumente leben unter `docs/design/` (Issues
sind im Repo deaktiviert).

## Jetzt: v0.7.2 „Admin-Hub“ (Release-Gate)

Milestone: `docs/design/milestone-v0.7.2.md`. Die Features sind gemergt
(#12–#21); bis zum Tag fehlen:

1. CI grün (`flutter test` 128/0) + manuelle Verifikation der Werkzeuge
2. l10n: `.arb`-Keys eintragen, `_tr()` ablösen (Snippets:
   `admin-hub-followups.md` §2)
3. Version-Bump, Tag, Packaging, Install-Smoke-Test

## Als Nächstes: v0.7.3 (Kandidaten)

| Thema | Quelle | Aufwand |
|---|---|---|
| Golden-Baselines (Setup + neue Screens) | followups §3 | ½–1 Tag |
| PR B abschließen: Dashboard-Widgets auf `MintYColors` (inkl. `single_bar_chart.dart`-Mutations-Hack **ersetzen**) | Tracker #10, Audit §2.1 | 1–2 Tage |
| `main.dart`-Fallback `Colors.blue` → Mint; `#7F7FFF` zuordnen | Audit F1/F2 | 15 min |
| Analyzer-Backlog abbauen (189 Findings), dann `flutter analyze` in CI | Commit `1e90957` | laufend |

## Danach: PR C/D (Design-Audit-Fixliste)

Priorisiert nach `design-audit-inconsistencies.md` §3:

- `secondaryHeaderColor` → `chartTrack` (cleaner-Screens)
- `Colors.grey` Info-Box (security_check) → `surfaceRaised`
- `Colors.black54` (power_mode) → `inactive`-Token
- `Colors.red`-Reste → `statusDanger`
- Terminal-Farben + Courier (run_command_queue) → Tokens
- Settings-State-String → echte Routen (PR C, größer)
- Fokus-Ringe / A11y-Zustände (Komponenten-Härtung, Phase 3)
- Widgetbook für Kern-Komponenten (Phase 3, Schritt 5)

## Werkzeug-v2 (nicht terminiert, Spec-Kandidaten)

| Tool | v2-Ideen |
|---|---|
| Quick Notes | Markdown-Preview, Sync-Provider (`NotesService` ist Interface) |
| Dateimanager | Copy/Move/Rename, rekursive Größen on-demand, Drag&Drop, Tabs |
| Systemmonitor | AMD/Intel-GPU, Per-Interface-Sparklines, Prozess-Details |
| Browser | Eigener Fenster-Host statt externem Launch (Playbook §4) |

## Backlog (Hermes-Layer)

`hermes-backlog.md`-Kriterien beachten: Weiterentwicklung der
Hermes-Widgets (Audits, Varianten, Doku im Komponenten-Katalog) erst nach
Reaktivierung.

## Prinzip

Reihenfolge bleibt: **Verifizieren → Härten → Erweitern.** Erst grüne
Suite + verifizierte v0.7.2, dann Token-Migration, dann neue Features.
