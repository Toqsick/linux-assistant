# docs/handoff/ — Handoff-Ordner Linux Assistant v0.7.1 → v0.8.0

Erstellt 2026-09-10 im Rahmen des SDD-Plans (`00-PLAN.md`). Ziel: ein externer Lesender kann Design, Komponenten und Panel-Struktur der App übernehmen, ohne den Code zuerst lesen zu müssen. Jede Design-Aussage ist mit `file:line` auf `lib/` belegt (Stand Zweig `hardening/0.8.0`).

## Inhalt

| Pfad | Status | Inhalt |
|---|---|---|
| `00-PLAN.md` | ✅ | Master-Plan: Phasen 0/A–F, Entscheidungen, Constraints |
| `screenshots/v0.7.1/` (+ `README.md` Inventar) | ✅ | 14 verifizierte Baseline-Shots der installierten v0.7.1 (beide Themes, Bug-Evidence Security) |
| `screenshots/v0.8.0/` | ⏳ geplant (Phase E.7) | Before/After der V0.8.0-Umsetzung; Lücken aus v0.7.1 (Werkzeuge, Launcher standalone, Security light) nachholen |
| `design/colors.md` | ✅ | HermesTokens Light/Dark komplett mit Hex + Rolle, Distro-Paletten (main.dart), MintYColors-Bewertung, Hardcode-Sünden-Liste |
| `design/typography.md` | ✅ | MintY-Styles + TextTheme-Mapping, Monospace-Strategien (3 konkurrierende), 68 Inline-TextStyle-Stellen, pubspec-Font-Befund |
| `design/shapes-spacing.md` | ✅ | Struktur-Tokens (Radius/Space/Border/Spine/Opacity), Elevation-Prinzip, Magic-Number-Inventar |
| `components/component-catalog.md` | ✅ | 32 Widgets (9 Hermes, 15 MintY-Legacy, 8 Misc) mit Props, Verwendung, Screenshot, Migrationsstatus |
| `panels/hub-shell.md` | ✅ | Hub-Architektur: Sidebar/Top-Bar/IndexedStack, Werkzeuge + HubTool-Registrierung, Hotkey-Flow, ASCII-Skizze |
| `analysis/findings.md` | ⏳ folgt (Phase C) | UI/UX-Analyse mit Schweregraden + Evidence |
| `roadmap.md` | ⏳ folgt (Phase D) | Konsolidierte Roadmap V0.8.0/V0.8.X/V0.9 (ersetzt PR #24) |

## Abgrenzung: was es schon gibt (nicht dupliziert)

Die folgenden Bestände auf `main` (origin) decken Strategie/Specs ab; dieser Handoff-Ordner dokumentiert den **Ist-Zustand im Code** mit Zeilenbelegen. Bei Konflikt gilt der Code.

### `docs/design/` (12 Dateien)

| Datei | 1-Zeiler |
|---|---|
| `linux-assistant-design-system.md` | Grundlagen-Doku „Mint-Y / Hermes" — Designphilosophie und Systemüberblick (Handoff-Detail: `design/*.md` hier) |
| `design-audit-inventory.md` | Audit: Inventarisierung aller Design-Werte im Code (Phase 1) |
| `design-audit-inconsistencies.md` | Audit: hartcodierte Farben vs. Token-Nutzung |
| `design-audit-component-catalog.md` | Audit: Katalog aller wiederverwendbaren Widget-Klassen (Vorgänger dieses `components/component-catalog.md` — hier aktualisiert auf 0.8.0-Stand inkl. Hermes-Familie) |
| `screenshot-baseline.md` | Planung der Screenshot-Basis (Phase 1, Schritt 4) |
| `visual-baseline-analysis.md` | Manuelle visuelle Analyse der Fork-v0.7.1-Shots |
| `design-workflow-roadmap.md` | Design-System-Workflow + Erweiterungs-/Verbesserungsvorschläge |
| `feature-spec-admin-hub.md` | Feature-Spec Admin-Hub (Sidebar-Links, Brave, Quick Notes, Dateimanager, Systemmonitor) — **Implementierungsstand jetzt in `panels/hub-shell.md`** |
| `admin-hub-followups.md` | Nacharbeiten zum Admin-Hub-Epic (#12–#19) |
| `milestone-v0.7.2.md` | Milestone-Doku v0.7.2 (Gate, DoD, Changelog-Vorlage) |
| `theme-extension-migration.md` | Migrations-Guide MintY (statisch) → MintYColors (ThemeExtension) — **Pflichtlektüre vor Aktivierung von MintYColors, siehe `design/colors.md` §3** |
| `linux-assistant-ui-templates.html` | HTML-Template-Sammlung der UI-Muster |

### `docs/wiki/` (9 Seiten)

| Seite | 1-Zeiler |
|---|---|
| `Home.md` | Einstieg: Fork mit Admin-Hub |
| `Getting-Started.md` | Build/Voraussetzungen |
| `Architecture.md` | Schichten-Überblick der Codebasis |
| `Design-System.md` | Kompaktverweis auf `docs/design/linux-assistant-design-system.md` + Audits |
| `Admin-Hub.md` | Nutzer-/Spec-Sicht der Werkzeuge (Spec-Verweis auf feature-spec-admin-hub.md) |
| `Testing.md` | Test-Suite-Überblick (`test/`) |
| `Contributing.md` | Workflow-Regeln |
| `Release-Process.md` | Release-Prozess, Verweis auf aktuelles Milestone-Doc |
| `Roadmap.md` | Roadmap-Stand 2026-08-22 mit Verweisen nach `docs/design/` (konsolidiert wird Phase D) |

## Lesereihenfolge für die Übernahme

1. `00-PLAN.md` (warum, was, Constraints) → 2. `panels/hub-shell.md` (App versteht man über den Hub) → 3. `design/colors.md` (die zwei Token-Systeme!) → 4. `design/typography.md` + `design/shapes-spacing.md` → 5. `components/component-catalog.md` (was man baut/weglässt) → 6. Screenshots nach Bedarf.
