# Design-System-Workflow & Roadmap
## Linux Assistant (Mint-Y / Hermes) – Erweiterung, Verbesserung, UI/UX-Vorschläge

---

## Teil 1: Der Workflow (End-to-End)

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  1. AUDIT   │ → │  2. TOKENS  │ → │ 3. KOMPON.  │ → │  4. DOKU    │ → │ 5. QUALITÄT │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
       ↑                                                                  │
       └──────────────────  6. RELEASE & FEEDBACK-LOOP  ←─────────────────┘
```

### Phase 1 – Design-Audit (1–2 Tage)
1. **Inventarisierung:** Alle `Color(...)`, `fontSize`, `BorderRadius`, `SizedBox`, `EdgeInsets` im Code per Regex/Code-Search erfassen.
2. **Inkonsistenzen finden:** Hartcodierte Farben vs. `MintY.currentColor` markieren. Bekannte Fälle: `Colors.grey` in security_check/overview.dart, `#D3D3D3`-Track in single_bar_chart.
3. **Komponenten-Katalog:** Jede wiederverwendete Widget-Klasse in eine Tabelle (Name, Datei, Props, Zustände).
4. **Screenshot-Baseline:** Goldens/Screenshots aller Layouts als visuelle Referenz sichern.

### Phase 2 – Token-Konsolidierung (2–3 Tage)
1. **Single Source of Truth:** Neue Datei `lib/layouts/design_tokens.dart` (oder `hermes_tokens.dart` ausbauen) mit allen Werten aus `linux-assistant-design-system.md`.
2. **ThemeExtension statt statischer Klasse:** `MintY` ist aktuell eine statische Klasse mit mutablem `currentColor`. Migration zu `ThemeExtension<MintYColors>` → Hot-Switch ohne Rebuild, testbar, kein globaler State.
3. **Semantic Tokens einführen:** Nicht `Color(0xff6db443)` direkt, sondern `tokens.accent`, `tokens.surfaceRaised`, `tokens.statusDanger`. Dadurch wird Distro-Theming trivial.
4. **Token-Export automatisieren:** Generator-Skript (Python/Dart), das aus der Token-Datei CSS-Variablen + JSON + Dart-Konstanten erzeugt → Web-Doku und App nie out-of-sync.

### Phase 3 – Komponenten-Härtung (3–5 Tage)
1. **MintYButton API vereinheitlichen:** Varianten-Enum (`primary|secondary|ghost|danger`) statt frei setzbarem `color`.
2. **Zustände definieren:** Für jede Komponente: default / hover / focus / disabled / loading / selected / error.
3. **SingleBarChart & MemoryStatus:** Schwellwerte (89 %, 100 %) als Parameter statt Magic Numbers.
4. **Hermes-Widgets als offizielles Set:** `HermesCard`, `HermesStatTile`, `HermesSparkline`, `HermesBadge` dokumentieren und mit Mint-Y-Tokens verdrahten.
5. **Storybook-Äquivalent:** Flutter Widgetbook einführen → jede Komponente isoliert in allen Zuständen & beiden Themes.

### Phase 4 – Dokumentation (laufend)
1. Die mitgelieferte HTML-Datei (`linux-assistant-ui-templates.html`) als Living Styleguide ins Repo (`docs/design/`) und in CI rendern (GitHub Pages).
2. Pro Komponente: Screenshot, Props-Tabelle, Do/Don't, Code-Snippet.
3. **ADR** (Architecture Decision Record) für Token-Architektur anlegen.

### Phase 5 – Qualitätssicherung (laufend, CI)
1. **Golden Tests:** `flutter_test` Goldens für alle Screens in Light/Dark + 3 Distro-Akzenten.
2. **Kontrast-Lint:** Skript, das alle Text-/Hintergrund-Paare gegen WCAG AA (4.5:1) prüft. Achtung: `#9D9D9D` auf `#2D2D2D` erreicht nur ~3.3:1 → für Body-Text zu schwach.
3. **Custom Lint-Regel:** Verbiete `Color(0x…)` außerhalb der Token-Datei (custom_lint Plugin).
4. **Visual Regression:** Screenshots pro PR diffen (GitHub Actions + golden_toolkit).

### Phase 6 – Release & Feedback-Loop
1. Design-Version ans Repo-Changelog koppeln (`version`-Datei existiert bereits).
2. Feedback-Layout der App (`lib/layouts/feedback/`) um optionalen UI-Report erweitern (Screenshot + Theme-Infos).
3. Pro Release: 1 Verbesserung aus der Roadmap (Teil 2) umsetzen.

---

## Teil 2: Was noch erweiterbar / verbesserbar ist

### 🔴 Technische Schulden (priorisiert)
| # | Befund | Problem | Lösung |
|---|--------|---------|--------|
| 1 | `MintY.currentColor` ist global mutable | Nicht testbar, kein Rebuild bei Wechsel | ThemeExtension + Provider/Riverpod |
| 2 | Light Theme ist zweitklassig | `canvasColor`/`cardColor` nur im Dark-Theme gesetzt; Light nutzt Defaults | Symmetrische Token-Sets für beide Themes |
| 3 | Magic Numbers (89 %, 100 %, 32/24/20 px) | Schwer konsistent zu ändern | Konstanten in Token-Datei |
| 4 | Farben per String-Key (`getColorByName("Green")`) | Typos crashen zur Laufzeit | Enum `MintYAccent { green, aqua, … }` |
| 5 | `Courier` als Monospace | Nicht auf jedem Linux vorhanden | Font-Fallback-Stack: `JetBrains Mono → DejaVu Sans Mono → monospace` |
| 6 | Fenster 1280×720 hart in C++ | Keine Mindestgröße, kein Resize-Verhalten | `gtk_window_set_default_size` + Min-Size + responsives Layout |

### 🟡 Architektur-Erweiterungen
- **Theme-Engine 2.0:** Distro-Erkennung + Benutzer-Override (Akzent frei wählbar aus der Mint-Y-Palette).
- **Hermes-Layer ausbauen:** Glassmorphism-Option (Blur + Translucency) als opt-in „Modern"-Preset neben klassischem Mint-Y.
- **Icon-System:** `IconLoader` um SVG-Cache und Named-Icon-Registry erweitern; Akzent-Färbung als Token statt direktem `MintY.currentColor`.
- **Motion-Spec:** Durations (`--motion-fast: 150ms`, `--motion-med: 300ms`), Curves (`easeOutCubic`) als Tokens.
- **Spacing-System:** Von {8,10,16,32} auf 4er/8er-Raster vereinheitlichen (10er-Ausreißer auf 8 oder 12 mappen).
- **i18n & RTL:** TextStyles RTL-sicher machen; `EdgeInsetsDirectional` für bidirektionales Padding.

### 🟢 Neue Bausteine
- **Empty-State-Komponente** (Icon + Text + CTA) – aktuell fehlt sie komplett.
- **Toast/Snackbar-Spec** für Erfolg/Fehler bei Command-Ausführung.
- **Skeleton-Loader** für MemoryStatus/DiskSpace während des Ladens.
- **Command-Palette-V2** (siehe UI/UX unten).
- **Design-Token-JSON** als öffentliche API, damit Community-Themes/Plugins dieselben Tokens nutzen.

---

## Teil 3: UI/UX-Vorschläge

### A. Informationsarchitektur
1. **Dashboard-first statt Search-first:** Health-Dashboard (CPU/RAM/Disk/Updates als HermesStatTiles) als Startscreen; Suche per `Ctrl+K` erreichbar.
2. **Prioritäts-Ampel konsistent nutzen:** Security-Check- und Health-Ergebnisse in drei Spalten (Kritisch / Empfohlen / Optional) statt linearer Liste.
3. **Progressive Disclosure im Greeter:** Einführungstour auf „3 Pflicht-Schritte + Rest aufklappbar" reduzieren.

### B. Interaktion & Feedback
4. **Destructive Actions absichern:** Disk-Cleaner & Uninstaller: Bestätigungs-Dialog mit konkreter Folge („2,4 GB werden gelöscht") + Undo-Hinweis, Button in `--status-danger`.
5. **Lange Operationen:** RunCommandQueue sollte Live-Log + ETA + „Im Hintergrund weiterlaufen lassen" bieten.
6. **Erfolg explizit machen:** Nach abgeschlossener Aktion Success-Zusammenfassung mit Zahlen („42 Pakete aktualisiert, 1,2 GB frei").
7. **Keyboard-First:** Vollständige Tastatur-Navigation (Pfeiltasten durch ActionEntryCards, `Enter` = Run, `Esc` = Back).

### C. Visuelle Politur
8. **Kontrast-Fixes:** `--color-text-dim #9D9D9D` auf `#2D2D2D` ist unter WCAG AA → auf `#B5B5B5` anheben.
9. **Fokus-Ringe:** Sichtbarer Focus-Indicator (2px Accent-Outline) für alle interaktiven Elemente.
10. **Konsistente Radius-Sprache:** Karten 10, Panels 20, Chips 8 – in Doku festnageln und per Lint durchsetzen.
11. **Mikro-Animationen:** HaloDot pulsieren bei laufendem Prozess; Sparkline animiert einzeichnen; Card-Hover mit 150ms-Fade.
12. **Distro-Branding dezent:** Kleines Distro-Badge in der Sidebar („Erkannt: Zorin OS 17") schafft Vertrauen.

### D. Accessibility
13. **Skalierung:** UI-Skalierungs-Option (100/125/150 %) – wichtig für HiDPI und Sehbehinderung.
14. **Screenreader-Labels:** Alle Icon-Buttons mit Semantics-Label; Terminal-Output als `live region`.
15. **Reduzierte Bewegung:** `MediaQuery.disableAnimations` respektieren.
16. **Farbblindheit:** Status nie nur über Farbe codieren → Icon + Text bei Success/Warning/Danger.

### E. Gamification
17. **„System-Health-Score"** (0–100) auf dem Dashboard, mit Verlauf-Sparkline – motiviert zur regelmäßigen Pflege.
18. **Onboarding-Checkliste mit Fortschrittsbalken** im Mint-Y-Green; nach Abschluss Badge „System gewartet ✔".

---

## Anhang: Schnell-Referenz Akzent-Palette

| Green | Aqua | Blue | Teal | Purple | Pink | Red | Orange | Sand | Brown | Grey |
|---|---|---|---|---|---|---|---|---|---|---|
| #6DB443 | #6CABCD | #5B73C4 | #2AB9A4 | #8C6EC9 | #C76199 | #C15B58 | #DB9D61 | #C8AC69 | #AA876A | #9D9D9D |
