# Typografie — TextStyles des Linux Assistant

Stand: 2026-09-10, Zweig `hardening/0.8.0`. Zeilenbezüge auf `lib/`.

**Keine eigenen Fonts gebundelt:** der `fonts:`-Block in `pubspec.yaml` ist vollständig auskommentiert (`pubspec.yaml:97-110`). Alles läuft über System-Fonts; `fontFamily`-Angaben sind daher Best-Effort mit Fallback-Verhalten des Betriebssystems.

---

## 1. MintY-TextStyles (aktiv, `lib/layouts/mint_y.dart`)

Konstanten auf der Klasse `MintY`:

| Style | Size | Weight | Besonderheit | Beleg |
|---|---|---|---|---|
| `heading1` / `heading1White` | 32 | w500 | `decoration: none` | mint_y.dart:88-91 / :78-82 |
| `heading2` / `heading2White` | 24 | w400 | | mint_y.dart:99-102 / :93-97 |
| `heading3` / `heading3White` | 20 | w400 | | mint_y.dart:110-113 / :104-108 |
| `heading4` / `heading4White` | **17** | w400 | | mint_y.dart:121-124 / :115-119 |
| `paragraph` | 15 | w400 | | mint_y.dart:126-129 |
| `paragraphWhite` | 15 | **w300** | | mint_y.dart:131-136 |

Design-Regel (Code-Kommentar `mint_y.dart:84-87`): die **nicht**-White-Styles tragen keine `color` und erben vom ambienten `DefaultTextStyle` — dadurch sind sie in beiden Themes lesbar. Die `*White`-Varianten halten Weiß explizit, weil sie auf dem Akzent-Gradient (`MintY.colorfulBackground`, `mint_y.dart:67-74`) sitzen, wo Weiß immer korrekt ist.

## 2. Material-TextTheme-Mapping (`mint_y.dart:198-214`)

Alle 15 Slots laufen auf nur 5 Styles; Farben werden zentral via `base.apply(bodyColor: t.text, displayColor: t.strong)` aufgebracht (`mint_y.dart:227-230`):

| Material-Slot | MintY-Style |
|---|---|
| `displayLarge`, `displayMedium` | `heading1` |
| `displaySmall`, `headlineLarge` | `heading2` |
| `headlineMedium`, `titleLarge` | `heading3` |
| `headlineSmall`, `titleMedium` | `heading4` |
| `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall` | `paragraph` |

Konsequenz: Alles unterhalb der Headlines ist 15px — es gibt **kein** Material-natives „small/caption". Die Hermes-Widgets lösen das mit Inline-Styles (s. u.).

## 3. Monospace

| Token | Wert | Nutzung |
|---|---|---|
| `HermesTokens.fontMono` = `'monospace'` (`hermes_tokens.dart:199`) | generischer Alias | `widgets/hermes/hermes_copy_command.dart:80` (12.5px auf `codeBg`/`codeText`), `layouts/security_check/security_finding.dart:123`, `layouts/tools/file_manager.dart:120, 435` |
| `MintYText.mono` (`mint_y_tokens.dart:264-268`) | `'JetBrains Mono'` + Fallback `['DejaVu Sans Mono', 'Courier', 'monospace']`, 14px | `layouts/tools/quick_notes.dart:298, 301` |
| Legacy-Literal | `fontFamily: "Courier"` direkt | `layouts/run_command_queue.dart:213` |

Drei konkurrierende Monospace-Strategien. Da keine Fonts gebundelt sind, hängt `MintYText.mono` davon ab, dass JetBrains Mono systemweit installiert ist; die Hermes-Seite ist mit `'monospace'` portabler. Empfehlung: auf `HermesTokens.fontMono` (ggf. mit Fallback-Liste wie in `MintYText.mono`) konsolidieren.

## 4. Inline-`TextStyle(` außerhalb mint_y.dart / mint_y_tokens.dart

Grep „TextStyle(" in `lib/` (ohne mint_y.dart, mint_y_tokens.dart, Kommentare): **68 Treffer**. Die überwiegende Mehrheit nutzt bereits `HermesTokens`-Farben (`t.muted`, `t.strong`, `t.accent`, …) — sie sind also token-konform, aber nicht zentralisiert. Vollständige Liste nach Datei:

| Datei | Zeilen |
|---|---|
| `layouts/hub/dashboard_section.dart` | 101, 144, 191, 332, 337, 362, 398, 409 |
| `layouts/hub/storage_section.dart` | 47, 100 |
| `layouts/hub/hub_shell.dart` | 446 (WERKZEUGE-Label 11px/1.2-Spacing), 471 (Logo „LA"), 495 (Brand-Name), 504 (Version), 533 (Top-Bar-Titel) |
| `layouts/tools/system_monitor.dart` | 84, 89, 94, 98, 181, 335, 339, 405, 409, 467, 490, **508** (`FontFeature.tabularFigures`-Konstante), 539 |
| `layouts/tools/quick_notes.dart` | 110, 114, 119, 175, 191, 220, 247, 271 |
| `layouts/tools/file_manager.dart` | 99, 110, 117, 128, 247, 282, 306, 336, 357, 359, 365, 403, 416, 424, 432 |
| `layouts/security_check/security_finding.dart` | 74, 95, 121 |
| `layouts/security_check/overview.dart` | 136 |
| `widgets/hermes/*` ( legitim — Widget-eigene Skala) | hermes_badge.dart:96, hermes_card.dart:107, hermes_copy_command.dart:56, 78, hermes_stat_tile.dart:60, 81, 93, 139, 148, hermes_nav_item.dart:64 |
| `widgets/single_bar_chart.dart` | 21 (Default `const TextStyle()`), 60 (Tooltip) |
| `layouts/run_command_queue.dart` | 211 |

Die nicht-Hermes-Inline-Styles wiederholen faktisch eine **inoffizielle kleine Größen-Skala**: 11px (Metadaten, w600 uppercase + letterSpacing 0.08·11 bzw. 1.2), 12px (Support-Text), 13px (Body-ähnlich), 28px (Stat-Werte) — s. `hermes_stat_tile.dart:8-9` (Kommentar zur Hermes-Skala) als Idealtyp. Die Token-Datei definiert dafür **keine** Typo-Tokens; `MintYText` (`mint_y_tokens.dart:252-269`) deckt nur heading1-4 + mono ab und weicht dabei von `mint_y.dart` ab (`MintYText.heading4` = 16px vs. `MintY.heading4` = 17px). Vor Übernahme von `MintYText` angleichen.

## 5. Offen

- Ob `MintYText` (16er-heading4) gegen `MintY.heading4` (17px) ausgetauscht oder angeglichen wird — Entscheidung steht aus (Roadmap `docs/design/design-workflow-roadmap.md`).
- Ob JetBrains Mono gebundelt werden soll (nötig, sobald `MintYText.mono` flächig genutzt wird — sonst Darstellungs-Drift zwischen Rechnern).
