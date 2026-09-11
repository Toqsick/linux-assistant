# Farben — Token-System des Linux Assistant

Stand: 2026-09-10, Zweig `hardening/0.8.0` (nach Rebase auf origin/main). Alle Zeilenbezüge auf `lib/`.

Die App hat **zwei konkurrierende Farbsysteme**:

1. `HermesTokens` (`lib/layouts/hermes_tokens.dart`) — **aktiv**, als ThemeExtension registriert (`mint_y.dart:226`), treibt ColorScheme + alle Hermes-Widgets.
2. `MintYColors` (`lib/layouts/mint_y_tokens.dart`) — **definiert, aber noch nicht verdrahtet** (s. u. „MintYColors vs. HermesTokens").

Daneben existiert globaler Mutable-State `MintY.currentColor` / `MintY.secondaryColor` (`mint_y.dart:12-14`), der pro Build in `MyApp.setMainColor()` gesetzt wird (`main.dart:166-229`).

---

## 1. HermesTokens — aktives Palette (ThemeExtension)

Definition: `hermes_tokens.dart:20-95` (Felder), Light `:98-132`, Dark `:135-162`.
Zugriff: `HermesTokens.of(context)` (`:169-173`, mit Brightness-Fallback für Bare-`MaterialApp`/Tests).
Akzent-Austausch: `withAccent()` (`:266-292`) — berechnet Tints (8 %/15 %), `accentText` und `onAccent` über `accessibleOn()` (`:232-258`, WCAG-2.2-Kontrast-Schleife) neu.

### Light („warm gold on cream")

| Token | Hex | Rolle | Beleg |
|---|---|---|---|
| `bg` | `#FEFCF7` | App-/Scaffold-Hintergrund | hermes_tokens.dart:99 |
| `sidebar` | `#FAF7F0` | Sidebar + Top-Bar | hermes_tokens.dart:100 |
| `surface` | `#F3EEE3` | Kartenfläche | hermes_tokens.dart:101 |
| `surfaceSubtle` | `#F7F4EC` | Inputs, sekundäre Flächen | hermes_tokens.dart:102 |
| `surfaceSubtleHover` | `#EFEADF` | Hover auf subtiler Fläche | hermes_tokens.dart:103 |
| `border` | `#E0D8C8` | 1px-Hairline | hermes_tokens.dart:104 |
| `borderMuted` | `#D0C6B2` | ruhigere Kante (2px-Spine-Kontext) | hermes_tokens.dart:105 |
| `borderSubtle` | `#EAE4D8` | Divider | hermes_tokens.dart:106 |
| `text` | `#1A1610` | Body-Text | hermes_tokens.dart:107 |
| `strong` | `#0F0D08` | Headlines / Werte | hermes_tokens.dart:108 |
| `muted` | `#5C5344` | Metadaten | hermes_tokens.dart:109 |
| `accent` | `#B8860B` | Gold-Akzent | hermes_tokens.dart:110 |
| `accentHover` | `#996F08` | Akzent Hover | hermes_tokens.dart:111 |
| `accentText` | `#7F5C08` | Akzent als Text (AA-abgesenkt vs. Hermes-`#8B6508`, Kommentar :112-114) | hermes_tokens.dart:114 |
| `accentBg` | `#F8F2E4` | Akzent-Tint 8 %, vorgeblendet (Kommentar :115-117) | hermes_tokens.dart:117 |
| `accentBgStrong` | `#F1E7CE` | Akzent-Tint 15 %, vorgeblendet | hermes_tokens.dart:118 |
| `onAccent` | `#1A1610` | Tinte auf Akzentfläche (dunkel statt weiß, Begründung :46-51) | hermes_tokens.dart:119 |
| `error` | `#C62828` | Fehler | hermes_tokens.dart:120 |
| `success` | `#2E7D32` | Erfolg (für Text abgedunkelt, Kommentar :121-124) | hermes_tokens.dart:124 |
| `warning` | `#B45309` | Warnung | hermes_tokens.dart:125 |
| `info` | `#05748F` | Info | hermes_tokens.dart:126 |
| `hoverBg` | `#0D000000` (schwarz 5 %) | Hover-Fläche | hermes_tokens.dart:127 |
| `inputBg` | `#08000000` (schwarz 3 %) | Input-Fläche | hermes_tokens.dart:128 |
| `focusRing` | `#59B8860B` (Gold 35 %) | Fokusring | hermes_tokens.dart:129 |
| `codeBg` | `#F5F0E5` | Code-/Terminal-Fläche | hermes_tokens.dart:130 |
| `codeText` | `#8B4513` | Code-Text | hermes_tokens.dart:131 |

### Dark („gold on navy-black")

| Token | Hex | Rolle | Beleg |
|---|---|---|---|
| `bg` | `#0D0D1A` | App-Hintergrund | hermes_tokens.dart:136 |
| `sidebar` | `#141425` | Sidebar + Top-Bar | hermes_tokens.dart:137 |
| `surface` | `#1A1A2E` | Kartenfläche | hermes_tokens.dart:138 |
| `surfaceSubtle` | `#16162A` | subtile Fläche | hermes_tokens.dart:139 |
| `surfaceSubtleHover` | `#1F1F35` | Hover | hermes_tokens.dart:140 |
| `border` | `#2A2A45` | Hairline | hermes_tokens.dart:141 |
| `borderMuted` | `#3A3A58` | ruhige Kante | hermes_tokens.dart:142 |
| `borderSubtle` | `#20203A` | Divider | hermes_tokens.dart:143 |
| `text` | `#FFF8DC` | Body-Text (warmes Weiß) | hermes_tokens.dart:144 |
| `strong` | `#FFFFFF` | Headlines | hermes_tokens.dart:145 |
| `muted` | `#C0C0C0` | Metadaten | hermes_tokens.dart:146 |
| `accent` | `#FFD700` | Gold (heller als Light) | hermes_tokens.dart:147 |
| `accentHover` | `#FFBF00` | Hover | hermes_tokens.dart:148 |
| `accentText` | `#FFD700` | Akzent-Text | hermes_tokens.dart:149 |
| `accentBg` | `#201D18` | Tint 8 % (entspr.) | hermes_tokens.dart:150 |
| `accentBgStrong` | `#322D1D` | Tint 15 % (entspr.) | hermes_tokens.dart:151 |
| `onAccent` | `#0D0D1A` | dunkle Tinte auf Gold | hermes_tokens.dart:152 |
| `error` | `#EF5350` | Fehler (heller als Light, Kommentar :53) | hermes_tokens.dart:153 |
| `success` | `#4CAF50` | Erfolg | hermes_tokens.dart:154 |
| `warning` | `#FFA726` | Warnung | hermes_tokens.dart:155 |
| `info` | `#4DD0E1` | Info | hermes_tokens.dart:156 |
| `hoverBg` | `#0FFFFFFF` (weiß 6 %) | Hover | hermes_tokens.dart:157 |
| `inputBg` | `#0AFFFFFF` (weiß 4 %) | Input | hermes_tokens.dart:158 |
| `focusRing` | `#59FFD700` | Fokusring | hermes_tokens.dart:159 |
| `codeBg` | `#1A1A2E` | Code-Fläche | hermes_tokens.dart:160 |
| `codeText` | `#F0C27F` | Code-Text | hermes_tokens.dart:161 |

Semantische Ton-Formel (Badge/Dot): Vordergrund solid, Hintergrund `base @ 10 %`, Border `base @ 28 %` — zentrale Stelle `hermesToneColors()`, `widgets/hermes/hermes_badge.dart:25-52`.

Verdrahtung in Material: `MintY._buildTheme()` mappt die Tokens auf `ColorScheme` (`mint_y.dart:163-194`), TextTheme, Card/Input/Selection-Themes (`mint_y.dart:216-278`). Registriert als Extension in `mint_y.dart:226`.

---

## 2. Distro-Akzent-Paletten (`MyApp.setMainColor`, main.dart:166-229)

Standard ist die Hermes-Gold-Palette; Distro-Farben sind **opt-in** über `use_distro_colors` (`main.dart:169-174`, Config-Key via `ThemeController`, theme_controller.dart:22). Explizite `main_color`/`secondary_color`-Config-Entries schlagen alles (`_applyConfiguredColorOverrides`, main.dart:231-241; HEX-Parser über `HexColor`).

| Distro (DISTROS-Case) | Primary | Secondary | Beleg |
|---|---|---|---|
| Default (kein Match) | — | `#2AB9A4` | main.dart:176 |
| Debian | `RGB(208,7,78)` = `#D0074E` | `RGB(75,5,35)` = `#4B0523` | main.dart:179-180 |
| Linux Mint / LMDE | `RGB(53,168,84)` = `#35A854` | `RGB(35,130,70)` = `#238246` | main.dart:184-185 |
| MX Linux | `RGB(34,34,34)` = `#222222` | `RGB(70,80,95)` = `#46505F` | main.dart:188-189 |
| Pop!_OS | `RGB(72,185,199)` = `#48B9C7` | `RGB(15,80,100)` = `#0F5064` | main.dart:192-193 |
| Zorin OS | `RGB(21,166,240)` = `#15A6F0` | `RGB(10,85,180)` = `#0A55B4` | main.dart:196-197 |
| KDE Neon | `RGB(35,104,150)` = `#236896` | `RGB(24,160,135)` = `#18A087` | main.dart:200-201 |
| openSUSE | `RGB(115,186,37)` = `#73BA25` | `RGB(15,95,75)` = `#0F5F4B` | main.dart:204-205 |
| Ubuntu | `RGB(233,84,32)` = `#E95420` | `RGB(122,42,82)` = `#7A2A52` | main.dart:208-209 |
| Fedora | `RGB(81,162,218)` = `#51A2DA` | `RGB(41,65,114)` = `#294172` | main.dart:212-213 |
| Arch | `RGB(15,148,210)` = `#0F94D2` | `RGB(28,40,51)` = `#1C2833` | main.dart:216-217 |
| Manjaro | `RGB(53,191,164)` = `#35BFA4` | `RGB(26,40,37)` = `#1A2825` | main.dart:220-221 |
| EndeavourOS | `RGB(127,63,191)` = `#7F3FBF` | `RGB(127,127,255)` = `#7F7FFF` | main.dart:224-225 |

Wirksam werden diese Farben über `MintY.theme()/themeDark(accent: …)` (`main.dart:286-287`), wo `withAccent()` die abgeleiteten Tints AA-safe neu rechnet.

Legacy-Namenspalette `MintY.colors(String)` (11 Namen, `mint_y.dart:19-46`) und `MintY.green`-MaterialColor (`:49-63`) sind Altlasten aus der Upstream-Ära — noch referenziert durch `currentColorTheme` (`:17`), aber im Theme-Pfad ohne Funktion.

---

## 3. MintYColors vs. HermesTokens (PR #9, `mint_y_tokens.dart` — NEU von origin/main)

**Was MintYColors abdeckt** (`mint_y_tokens.dart:24-116`): 14 Tokens — `accent`, `accentSecondary`, `canvas`, `surface`, `surfaceRaised`, `textPrimary`, `textDim`, `statusSuccess/Warning/Danger`, `chartCpu/Ram/Disk/Track`. Factories: `MintYColors.dark(MintYAccent)` (`:76-94`), `.light()` (`:98-116`), mit eigenem, „grauem" Dark-Set (`canvas #1F1F1F`, `surface #2D2D2D`) — **nicht** dem Navy-Set der HermesTokens.

Dazu im selben File (noch nicht überall genutzt):
- `MintYAccent`-Enum, 11 Distro-Paare (`:186-222`) — ersetzt die String-Keys von `MintY.colors()`. Werte weichen für einige Distros von `main.dart` ab (s. u.).
- `MintYRadius` (`:225-240`), `MintYSpacing` (`:244-249`), `MintYText` (`:252-269`), `MintYThresholds` (`:272-278`) — die dort „verifizierten" Magic Numbers sind hier erstmals benannt (Radius/Spacing: siehe `shapes-spacing.md`).

**Verhältnis zu HermesTokens:**

| Aspekt | Befund |
|---|---|
| Registrierung | **Nicht registriert.** Einzige `extensions:`-Zeile im Code ist `mint_y.dart:226` und übergibt nur HermesTokens. `MintYColors.dark()/light()` werden nur im Doc-Kommentar (`mint_y_tokens.dart:20`) aufgerufen. |
| Aktive Nutzung | Nur `MintYText.mono` ist verdrahtet (`tools/quick_notes.dart:298,301`). `MintYColors`-Farben, `MintYAccent`, `MintYRadius`, `MintYSpacing`, `MintYThresholds`: **0 Verwendungen** in `lib/` (Grep 2026-09-10). |
| Doppelung | Ja, teilweise: `accent` ≙ `HermesTokens.accent` (aber ohne Tint-Ableitung), `canvas/surface` ≙ `bg/surface` mit **abweichenden Grau-Werten**, Status-Farben ≙ `error/success/warning`. Es fehlt das ganze Border/Text/Akzent-Tint-Set der HermesTokens — MintYColors allein wäre kein vollständiger Ersatz. |
| Wert-Konflikte | `MintYAccent.mint` = `#6DB443` (aus `MintY.green`, mint_y.dart:50) ≠ `main.dart` Mint/LMDE `#35A854`; `zorin` `#15A6CF` ≠ main.dart `#15A6F0`; `manjaro` `#35BF5C` ≠ main.dart `#35BFA4`. Trotz Kommentar „verifiziert aus main.dart" (`:185`) stimmen die Paare nicht überein — vor Aktivierung klären, welche Quelle gilt. |
| Bekannte Schwäche (dokumentiert) | `textDim`-AA-Hinweis im Code (`:60-62`). |
| Migration | Migration-Guide existiert: `docs/design/theme-extension-migration.md`. Empfehlung: MintYColors **nicht** parallel aktivieren, sondern entweder auf HermesTokens zusammenführen oder die Divergenzen (s. o.) vor dem ersten `extensions:`-Eintrag auflösen. |

---

## 4. Hardcode-Sünden (verifiziert per Grep, 2026-09-10)

### `Colors.red` (falsche semantische Farbe — Hermes hätte `t.error`/`statusDanger`)

| Stelle | Kontext |
|---|---|
| `layouts/uninstaller/uninstaller_question.dart:22` | 128px-Warn-Icon |
| `layouts/uninstaller/uninstaller_question.dart:58` | Uninstall-Button (`color:`-Prop) |
| `layouts/disk_cleaner/clean_disk.dart:132` | Progress-Balken > 89 % |
| `layouts/disk_cleaner/cleaner_select_disk.dart:45` | Mini-Progress > 89 % |
| `widgets/disk_space.dart:48` | Balken-Fill > 89 % |
| `widgets/disk_space.dart:61` | „Aufräumen"-Icon > 89 % |
| `widgets/memory_status.dart:55` | CPU-Balken bei Load ≥ 1.0 |

### `Colors.white`

| Stelle | Kontext | Bewertung |
|---|---|---|
| `layouts/main_screen/main_search.dart:289, 375, 391, 824, 854, 884` | Icons nur wenn `widget.colorfulBackground` (auf Akzent-Gradient) | **halb-legitim** — entspricht der Begründung der `*White`-Styles (`mint_y.dart:84-87`); der Gradient selbst ist das eigentliche Problem |
| `layouts/settings/settings_widgets.dart:158` | Save-Icon auf `MintY.currentColor`-Button | legitim auf Akzent, aber hartkodiert statt `onAccent` |
| `layouts/security_check/overview.dart:30` | `MintYButtonNavigate(color: Colors.white)` | Unsinn: weißer Button-Background → weißer Text |
| `layouts/run_command_queue.dart:199, 212` | Text/Icon auf progressivem UI | prüfen |
| `widgets/single_bar_chart.dart:61` | fl_chart-Tooltip-Text | Chart-intern |
| `mint_y.dart:76` (`_white`) | Quelle aller `*White`-TextStyles | intentional (Gradient-Hintergrund) |

### Sonstige

| Stelle | Wert | Kontext |
|---|---|---|
| `layouts/main_screen/main_search.dart:177` | `Colors.grey` | Such-Placeholder-Icon |
| `layouts/after_installation/flatpak_check.dart:38` | `Colors.grey` | Icon |
| `widgets/disk_space.dart:49` | `ARGB(255,141,141,141)` | Balken-Fill normal (≈ `chartDisk #8D8D8D` aus MintYColors!) |
| `widgets/disk_space.dart` / `widgets/memory_status.dart` / `widgets/single_bar_chart.dart` | weitere ARGB-Literale: `#D3D3D3`/`#494949`/`#575757` (single_bar_chart.dart:18,19,34), CPU-Blau `#4699DD` (memory_status.dart:54), RAM-Lila `#C177F3` (:66), Swap-Orange `#DF9D3A` (:75) | exakt die Werte, die `MintYColors.chart*` (`mint_y_tokens.dart:89-92`) kodifizieren würde — Chart-Farben sind also schon „im Kopf" migriert, nur nicht im Code |
| `widgets/success_message.dart:16` | `Colors.green` | Icon |
| `widgets/warning_message.dart:21` | `Colors.orange` | Icon |
| `layouts/run_command_queue.dart:213` | `fontFamily: "Courier"` | Typo-Sünde (siehe typography.md) |

**Muster:** Fast alle Hartkodierungen liegen in den Legacy-Screens (Launcher `main_search`, Disk-Cleaner, Uninstaller, Greeter/after_installation, Health-Widgets). Der komplette Hub (`hub/`, `widgets/hermes/`, `tools/`) ist frei von `Colors.*`-Hardcodes — Grep bestätigt die Trennung Hermes=sauber, Legacy=rot.

Screenshots: Light/Dark-Gegenstücke je Sektion unter `screenshots/v0.7.1/` (z. B. `00-start_dark_01.png` vs. `00b-dashboard_light.png`, Settings `05-einstellungen_light.png`).
