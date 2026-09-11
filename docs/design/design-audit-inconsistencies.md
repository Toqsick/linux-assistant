# Design-Audit: Inkonsistenzen
## Hartcodierte Farben vs. Token-Nutzung (Phase 1, Schritt 2)

> Methode: Abgleich aller Farb-Vorkommen gegen die Token-Quellen
> (`MintY.currentColor`, `MintY.secondaryColor`, `Theme.of(context)`).
> Legende: 🔴 Verstoß · 🟡 Grauzone/begründbar · 🟢 konform

---

## 1. Übersicht: Wer nutzt was?

### 🟢 Token-konform (33 Dateien via `Theme.of(context)` + `MintY.currentColor`)

Voll konform: `hardware_info`, `updater`, `success_message`, `warning_message`,
`greeter/start_screen`, `greeter/start_after_installation`, `linux_health/overview`,
`feedback_form`, `feedback_send`, `shutdown_dialog`, `settings_widgets`,
`power_mode` (Typo), `environment_selection`, `recommendation_card`,
`appearance_settings`, `after_installation/*` (inkl. `colorScheme.error` – vorbildlich!),
`main_search` (cardColor/canvasColor), `clean_disk` (Typo), `settings_start` (Typo),
`action_entry_card` (focusColor für Selection), `icon_loader`, `system_icon`,
`basic_entries`, `recommendations`, `updater`, `grub_config`, `feedback/*`,
`security_check/overview` (Buttons), `run_command_queue` (Checkbox via MaterialStateColor)

### 🔴/🟡 Dateien mit hartcodierten Farben

| Datei | Hartcodiert | Sollte sein | Schwere |
|---|---|---|---|
| `security_check/overview.dart` | `Colors.grey` als Info-Box-Hintergrund (Radius-8-Box) | `colors.surfaceRaised` (#383838) – Grau-Box wirkt auf Dark-Canvas Fremdkörper | 🔴 |
| `single_bar_chart.dart` | Track `#D3D3D3` + Fill `#494949` als const-Defaults | `colors.chartTrack` / `chartFill` | 🟡 (siehe Sonderfall unten) |
| `single_bar_chart.dart` | ⚠️ **Dark-Mode-Mutations-Hack** (Details §2.1) | ThemeExtension | 🔴 |
| `memory_status.dart` | `#4699DD` (CPU), `#C177F3` (RAM), `Colors.red` | `colors.chartCpu/chartRam/statusDanger` | 🔴 → in PR #10 |
| `disk_space.dart` | `#8D8D8D`, `Colors.red` (Balken + Clean-Icon) | `colors.chartDisk/statusDanger` | 🔴 → in PR #10 |
| `clean_disk.dart` / `cleaner_select_disk.dart` | `Colors.red` bei >89 % | `colors.statusDanger` + `MintYThresholds` | 🟡 (Akzent-Teil ist konform via `MintY.currentColor`) |
| `cleaner_select_disk.dart` / `clean_disk.dart` | `Theme.of(context).secondaryHeaderColor` als Balken-Hintergrund | `colors.chartTrack` – `secondaryHeaderColor` ist semantisch falsch (eigentlich für Listen-Header) | 🔴 |
| `power_mode.dart` | `Colors.black54` für inaktive Mode-Buttons | `colors.surfaceRaised` oder dedizierter `colors.inactive` | 🔴 Kontrast-Problem auf Dark |
| `main.dart` | `Colors.blue` als Default-Fallback in `setMainColor()` | `MintYAccent.mint`-Palette | 🔴 Identitätsbruch bei unbekannter Distro |
| `main.dart` | `secondaryColor #7F7FFF` (255,127,127,255) ohne erkennbare Distro | Zuordnung klären | 🟡 unklar |
| `uninstaller_question.dart` | `Colors.red` Icon 128px + Text | `colors.statusDanger` (Pattern ok, Token fehlt) | 🟡 |
| `flathub_permissions.dart` | `Colors.black` Hero-Panel | 🟡 bewusstes Design (Kontrast-Panel) – als `colors.panelHero` dokumentieren | 🟡 |
| `run_command_queue.dart` | `Colors.black` Dialog + `Colors.white` Icon/Text + `Courier` | `MintYText.mono` + `colors.terminalBg/terminalFg` | 🟡 |
| `main_search.dart` | `Colors.grey` Such-Icon | `colors.textDim` | 🟡 |
| `flatpak_check.dart` | `Colors.grey` Skip-Button | `colors.surfaceRaised` + Ghost-Variante | 🟡 |
| `settings_widgets.dart` | `Colors.white` Save-Icon (24px) | `colors.textOnAccent` (weiß auf Akzent ist ok, aber Token fehlt) | 🟡 |
| `action_entry_card.dart` | `Color.fromARGB(0,0,0,0)` | `Colors.transparent` (idiomatisch) | 🟡 Style |
| `security_check/overview.dart` | `Colors.white` Buttons (2×) | `colors.textOnAccent` | 🟡 |

---

## 2. Sonderfunde

### 2.1 🔴 Dark-Mode-Mutations-Hack in `single_bar_chart.dart`

```dart
@override
Widget build(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    if (backgroundColor == const Color.fromARGB(255, 211, 211, 211)) {
      backgroundColor = const Color.fromARGB(255, 87, 87, 87); // #575757
    }
  }
  ...
```

**Probleme:**
1. Ein `final`-Feld wird im `build` **mutiert** – bricht Flutter-Immutability-Konvention
2. Der Vergleich `backgroundColor == const Color(...)` ist fragil: sobald ein Caller
   explizit `#D3D3D3` übergibt (z. B. nach Token-Migration), wird es im Dark Mode
   still überschrieben
3. Dritter Track-Wert `#575757` existiert **nirgendwo** im Design System
   (war bislang undokumentiert!)

**Fix:** Track-Farbe komplett aus `MintYColors.chartTrack` beziehen
(Dark `#3A3A3A` / Light `#D3D3D3`), Mutations-Block entfernen.
→ Muss in PR #10 nachgeschärft werden: Der Copilot-Auftrag sagt „resolve in build",
aber dieser Hack muss *ersetzt*, nicht ergänzt werden.

### 2.2 🔴 Korrektur: Debian Secondary-Farbe

Die Volltext-Suche zeigt: Der Debian-Case setzt **nicht** nur `#D0074E`:

```dart
case DISTROS.DEBIAN:
  MintY.currentColor = const Color.fromARGB(255, 208, 7, 78);   // #D0074E
  MintY.secondaryColor = const Color.fromARGB(255, 75, 5, 35);  // #4B0523
```

→ In `linux-assistant-design-system.md` stand für Debian fälschlich Secondary
`#2AB9A4`. **Korrekt: `#4B0523`.** Der Fix in `lib/layouts/mint_y_tokens.dart`
(`MintYAccent.debian`) ist Teil dieses PRs. ✅

### 2.3 🟡 `#7F7FFF` – verwaiste Secondary

`MintY.secondaryColor = Color.fromARGB(255, 127, 127, 255)` steht vor dem
`default`-Case, gehört zu einem Distro-Case, der aus den Suchfragmenten nicht
eindeutig zuordenbar ist. → Manuell in `main.dart` nachsehen und dem Enum zuordnen.

### 2.4 🟢 Positivbefund: `colorScheme.error`

Die `after_installation/*`-Screens (`browser_selection`, `utilities_selection`,
`communication_software`) nutzen vorbildlich `Theme.of(context).colorScheme.error`
statt `Colors.red`. → Dieses Pattern sollte **überall** der Standard werden
(bzw. `colors.statusDanger`, das auf colorScheme.error mappt).

---

## 3. Priorisierte Fix-Liste

| Prio | Fix | Aufwand | PR-Zuordnung |
|---|---|---|---|
| 🔴 1 | Debian Secondary `#4B0523` in `mint_y_tokens.dart` korrigieren | 5 min | **dieser PR** ✅ |
| 🔴 2 | `single_bar_chart.dart` Mutations-Hack entfernen, `#575757` → Token | 30 min | PR #10 nachschärfen |
| 🔴 3 | `main.dart` Fallback `Colors.blue` → Mint + `#7F7FFF` zuordnen | 15 min | Fix-PR |
| 🔴 4 | `secondaryHeaderColor` → `chartTrack` (2 Dateien) | 10 min | PR C |
| 🔴 5 | `Colors.grey` Info-Box (security_check) → `surfaceRaised` | 5 min | PR C |
| 🔴 6 | `Colors.black54` (power_mode) → `inactive`-Token | 15 min | PR C |
| 🟡 7 | `Colors.red`-Reste (uninstaller, disk_cleaner) → `statusDanger` | 20 min | PR C/D |
| 🟡 8 | Terminal-Farben + Courier (run_command_queue) → Tokens | 15 min | PR C |
| 🟡 9 | Kleinkram: transparent, textOnAccent, grey Icons | 20 min | PR D |
| 🟡 10 | `panelHero`-Token für schwarze Hero-Panels dokumentieren | 10 min | Doku |

## 4. Erkenntnis für den Workflow

Die Token-Konformität der App ist insgesamt **gut** (33 Dateien sauber, ~15 mit
Verstößen, davon nur 6 kritisch). Die kritischsten Stellen sind genau die, die
**Funktionslogik mit Darstellung mischen** (Mutations-Hack, Magic-Thresholds) –
das bestätigt die Roadmap-Priorisierung Dashboard → Settings → Rest.
