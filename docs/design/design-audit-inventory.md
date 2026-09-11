# Design-Audit: Inventarisierung
## Alle Design-Werte im Code (Phase 1 des Workflows)

> Methode: GitHub Code-Search über `Color(0x`, `fromARGB`, `Colors.`, `fontSize`,
> `BorderRadius.circular`, `Radius.circular`, `EdgeInsets.all/only/symmetric`,
> `SizedBox(height/width:`. Basis: Jean28518/linux-assistant (Upstream, indexiert)
> + Toqsick-Fork (Hermes-Layer). Stand: 2026-08-20.

---

## 1. Farben

### 1.1 Hex-Farben `Color(0x…)`

| Wert | Datei | Kontext |
|---|---|---|
| `#6DB443` | mint_y.dart | `currentColor` Default + case "Green" |
| `#92B372` | mint_y.dart | Green-Variante (auskommentiert) |
| `#2AB9A4` | mint_y.dart / main.dart | `secondaryColor` Default + case "Teal" |
| `#6CABCD` | mint_y.dart | case "Aqua" |
| `#5B73C4` | mint_y.dart | case "Blue" |
| `#AA876A` | mint_y.dart | case "Brown" |
| `#9D9D9D` | mint_y.dart | case "Grey" |
| `#DB9D61` | mint_y.dart | case "Orange" |
| `#C76199` | mint_y.dart | case "Pink" |
| `#8C6EC9` | mint_y.dart | case "Purple" |
| `#C15B58` | mint_y.dart | case "Red" |
| `#C8AC69` | mint_y.dart | case "Sand" |

### 1.2 ARGB-Farben `Color.fromARGB(…)`

| Wert | Hex | Datei | Kontext |
|---|---|---|---|
| (255, 208, 7, 78) | `#D0074E` | main.dart | Debian Primary |
| (255, 75, 5, 35) | `#4B0523` | main.dart | Debian Secondary (nachgetragen, Audit-Befund) |
| (255, 53, 168, 84) | `#35A854` | main.dart | LMDE Primary |
| (255, 35, 130, 70) | `#238246` | main.dart | LMDE Secondary |
| (255, 115, 186, 37) | `#73BA25` | main.dart | openSUSE Primary |
| (255, 15, 95, 75) | `#0F5F4B` | main.dart | openSUSE Secondary |
| (255, 35, 104, 150) | `#236896` | main.dart | KDE Neon Primary |
| (255, 24, 160, 135) | `#18A087` | main.dart | KDE Neon Secondary |
| (255, 127, 127, 255) | `#7F7FFF` | main.dart | ⚠️ Unbekannte Distro-Secondary (vor `default`) |
| (255, 31, 31, 31) | `#1F1F1F` | mint_y.dart | canvasColor Dark |
| (255, 45, 45, 45) | `#2D2D2D` | mint_y.dart | cardColor Dark |
| (255, 255, 255, 255) | `#FFFFFF` | mint_y.dart | `_white` |
| (255, 70, 153, 221) | `#4699DD` | memory_status.dart | CPU-Balken |
| (255, 193, 119, 243) | `#C177F3` | memory_status.dart | RAM-Balken |
| (255, 141, 141, 141) | `#8D8D8D` | disk_space.dart | Disk-Balken normal |
| (255, 211, 211, 211) | `#D3D3D3` | single_bar_chart.dart | Bar-Track Default (Light) |
| (255, 87, 87, 87) | `#575757` | single_bar_chart.dart | ⚠️ Bar-Track Dark (undokumentierter Hack) |
| (255, 73, 73, 73) | `#494949` | single_bar_chart.dart | Bar-Fill Default |
| (0, 0, 0, 0) | transparent | action_entry_card.dart | ListTile unselected |

### 1.3 Benannte Farben `Colors.…`

| Wert | Datei | Kontext |
|---|---|---|
| `Colors.red` | disk_space, memory_status, cleaner_select_disk, clean_disk, uninstaller_question | Disk >89 %, CPU ≥100 %, Uninstaller-Warnung (Icon 128px) |
| `Colors.green` | success_message.dart | Success-Icon 32px |
| `Colors.orange` | warning_message.dart | Warning-Icon 32px |
| `Colors.black` | mint_y.dart (heading1–4), flathub_permissions, run_command_queue | Text Light, Hero-Panels, Terminal-Dialog |
| `Colors.black54` | power_mode.dart | ⚠️ Inaktiver Power-Mode-Button (halbtransparent) |
| `Colors.white` | run_command_queue, security_check/overview, settings_widgets, single_bar_chart | Terminal-Text/Icon 36px, Buttons, Tooltip |
| `Colors.grey` | security_check/overview, flatpak_check, main_search | ⚠️ Info-Box-Hintergrund, Skip-Button, Such-Icon |
| `Colors.blue` | main.dart | ⚠️ Default-Fallback in `setMainColor()` wenn Distro unbekannt |

### 1.4 Befunde (Inkonsistenzen)

| # | Befund | Ort | Empfehlung |
|---|---|---|---|
| F1 | `#7F7FFF` Secondary ohne erkennbare Distro-Zuordnung | main.dart | Prüfen: welcher `case` gehört dazu? Ggf. dokumentieren oder entfernen |
| F2 | `Colors.blue` als Default-Fallback bricht Mint-Y-Identität | main.dart | Fallback → `MintYAccent.mint` |
| F3 | `Colors.grey` als Info-Box-Hintergrund ist hart | security_check/overview.dart | → `colors.surfaceRaised` |
| F4 | `Colors.black54` für inaktive Buttons | power_mode.dart | → `colors.textDim` mit Opacity-Token |
| F5 | Transparent via `Color.fromARGB(0,0,0,0)` | action_entry_card.dart | → `Colors.transparent` (idomatischer) |
| F6 | Uninstaller nutzt `Colors.red` für großflächige Warnung (Icon 128) | uninstaller_question.dart | OK als Destructive-Pattern, aber → `colors.statusDanger` |

---

## 2. Typografie (`fontSize`)

| Wert | Gewicht | Datei | Stil |
|---|---|---|---|
| 32 | w500 | mint_y.dart | heading1 / heading1White |
| 24 | w400 | mint_y.dart | heading2 / heading2White |
| 20 | w400 | mint_y.dart | heading3 / heading3White |
| 16 | w400 | mint_y.dart | heading4 / heading4White (Button-Labels) |

Weitere Schrift-Definitionen:
- `fontFamily: "Courier"` in run_command_queue.dart (Terminal-Output, weiß) ⚠️ kein Fallback
- Keine weiteren `fontSize`-Vorkommen außerhalb mint_y.dart → **gute Konsistenz**, alle Screens nutzen die Heading-Stile oder Theme-TextTheme

---

## 3. Corner Radius

| Wert | Schreibweise | Datei | Kontext |
|---|---|---|---|
| 2 | `BorderRadius.circular(2)` | cleaner_select_disk.dart | Mini-Progressbar (minHeight 5) |
| 7 | `BorderRadius.circular(7)` | clean_disk.dart | Progressbar (minHeight 15) |
| 8 | `BorderRadius.all(Radius.circular(8))` | security_check/overview.dart | Info-Box (grau, padding 8) |
| 10 | `BorderRadius.circular(10.0)` | action_entry_card.dart | ListTile-Card |
| 20 | `BorderRadius.all(Radius.circular(20))` | flathub_permissions.dart | Hero-Panel (schwarz) |

→ **5 Stufen, konsistent.** Inkonsistenz: zwei Schreibweisen (`circular` vs `all(Radius.circular)`), funktional identisch.

---

## 4. Spacing

### 4.1 `EdgeInsets.all(…)`

| Wert | Dateien (Auswahl) | Häufigkeit |
|---|---|---|
| 4 | success_message, warning_message | 2× |
| 8 | security_check/overview (3×), settings_widgets (2×), feature_overview, linux_health/overview, main_search | 8× |
| 10 | disk_space, memory_status | 2× |
| 16 | clean_disk (2×), shutdown_dialog, flathub_permissions, settings_start, feedback_form, run_command_queue, cleaner_select_disk, linux_health/overview | 9× |
| 20 | main_search | 1× |
| 26 | mint_y.dart (colorfulBackground-Panel) | 1× ⚠️ Ausreißer |
| 32 | greeter/start_screen, shutdown_dialog, environment_selection | 3× |
| 40 | mint_y.dart (Card-Container) | 1× ⚠️ Ausreißer |
| 64 | feedback_send.dart (Dialog) | 1× ⚠️ Ausreißer |

### 4.2 `EdgeInsets.symmetric(…)`

| Wert | Datei | Kontext |
|---|---|---|
| h:100, v:8 | mint_y.dart | ⚠️ Bottom-Bar-Row (feste 100px Seiten-Polster – nicht responsiv!) |
| h:48, v:32 | flathub_permissions.dart | Hero-Sektion |
| v:4 | mint_y.dart | Text-Zeilenabstand |

### 4.3 `EdgeInsets.only(…)`

| Wert | Datei | Kontext |
|---|---|---|
| bottom:-20, left:12, right:3 | main_search.dart | ⚠️ Negatives Padding (-20) – Hack im Suchfeld-Layout |

### 4.4 `SizedBox(height: …)`

| Wert | Dateien |
|---|---|
| 8 | power_mode |
| 10 | hardware_info, clean_disk, main_search |
| 15 | mint_y.dart (Feature-Card) ⚠️ Ausreißer |
| 16 | security_check/overview (2×), main_search, power_mode |
| 20 | mint_y.dart (Feature-Card) |
| 32 | feedback_send (2×) |
| 50 | main_search ⚠️ Ausreißer |

### 4.5 `SizedBox(width: …)`

| Wert | Dateien |
|---|---|
| 5 | hardware_info, single_bar_chart ⚠️ unter Skala |
| 8 | mint_y.dart (Button Icon↔Label, 2×) |
| 10 | grub_config |
| 16 | main_search (2×), security_check/overview (2×) |
| 32 | power_mode (2×) |

### 4.6 Spacing-Befunde

| # | Befund | Empfehlung |
|---|---|---|
| S1 | Ausreißer: 26, 40, 64 (padding), 15, 50 (height), 5 (width) | Auf Skala {4, 8, 16, 24, 32, 48, 64} mappen oder als dokumentierte Sonderfälle behalten |
| S2 | Feste h:100 in Bottom-Bar | → responsiv: `EdgeInsets.symmetric(horizontal: max(16, (width-1080)/2))` o. ä. |
| S3 | Negatives Padding (-20) in main_search | Layout-Hack, bei Gelegenheit refactoren |
| S4 | Tatsächliche Skala: {4, 8, 10, 16, 20, 32} + Ausreißer | Bestätigt Roadmap: auf 4er/8er-Raster vereinheitlichen |

---

## 5. Icon-Größen (ergänzend erfasst)

| Wert | Datei | Kontext |
|---|---|---|
| 15 | hardware_info.dart | InfoLine-Icons |
| 20 | disk_space.dart | Clean-Icon |
| 24 | settings_widgets.dart | Save-Icon |
| 32 | success/warning_message | Status-Icons |
| 36 | run_command_queue.dart | Terminal-Dialog-Icon |
| 48 | basic_entries, recommendations | Feature-Icons |
| 64 | settings_start.dart | Settings-Hero |
| 128 | uninstaller_question.dart | ⚠️ Destructive-Warnung (Ausreißer, aber bewusstes Pattern) |

---

## 6. Zusammenfassung für Token-Datei

**Bereits in `mint_y_tokens.dart` abgedeckt:** ✅ Farben (Core/Palette/Distro/Status/Charts), Typo (32/24/20/16), Radius (2/7/8/10/20), Basis-Spacing (8/10/16/32), Thresholds

**Neu durch dieses Audit – Ergänzungsbedarf:**

| Token | Wert | Grund |
|---|---|---|
| `--space-0` | 4 | Message-Padding (success/warning) |
| `--space-5` | 48/64 | Dialog-Padding (feedback_send) |
| `--icon-xs` | 15 | InfoLine-Icons |
| `--icon-xxl` | 128 | Destructive-Warnungen |
| `--color-inactive` | black54-Äquivalent | power_mode inaktive Buttons |
| `--color-fallback-accent` | mint statt blue | main.dart Fallback-Fix |
| `--panel-padding-hero` | 26 | mint_y colorfulBackground (dokumentierter Sonderfall) |

**Offene Punkte für Phase 1 (Rest):**
- [ ] `#7F7FFF`-Zuordnung in main.dart klären (F1)
- [ ] Fork-Deltas prüfen: hermes_tokens.dart + hermes-Widgets enthalten evtl. eigene Werte (nicht indexiert, manuell lesen)
- [ ] Screenshot-Baseline aller Layouts (siehe screenshot-baseline.md)
