# Formen & Abstände — Struktur-Tokens und Abweichungen

Stand: 2026-09-10, Zweig `hardening/0.8.0`. Zeilenbezüge auf `lib/`.

## 1. Struktur-Tokens (`HermesTokens`, hermes_tokens.dart:175-199)

Als `static const` außerhalb der lerpbaren Extension — „never animate" (Kommentar :175-176):

| Token | Wert | Zweck | Beleg |
|---|---|---|---|
| `radiusSm` | 4 | kleine Flächen (Tooltip, Code-Block) | hermes_tokens.dart:178 |
| `radiusMd` | 8 | Karten, Inputs, Nav-Items, Standardradius | hermes_tokens.dart:179 |
| `radiusLg` | 12 | große Panels | hermes_tokens.dart:180 |
| `radiusPill` | 999 | Badges/Pills | hermes_tokens.dart:181 |
| `space1` | 4 | | hermes_tokens.dart:183 |
| `space2` | 8 | | hermes_tokens.dart:184 |
| `space3` | 12 | | hermes_tokens.dart:185 |
| `space4` | 16 | Karten-Padding-Default | hermes_tokens.dart:186 |
| `borderWidth` | 1 | Hairline überall | hermes_tokens.dart:189 |
| `spineWidth` | 2 | Akzent-Rücken aktiver Nav-Items/Karten | hermes_tokens.dart:192 |
| `opacityFaint` | 0.42 | De-Emphasis-Stufe 1 | hermes_tokens.dart:195 |
| `opacityMuted` | 0.56 | De-Emphasis-Stufe 2 | hermes_tokens.dart:196 |
| `opacityStrong` | 0.75 | De-Emphasis-Stufe 3 | hermes_tokens.dart:197 |
| `fontMono` | `'monospace'` | siehe typography.md | hermes_tokens.dart:199 |

Design-Regel zu Opacity: Metadaten werden über **Opacity statt Farbe** entwertet (Doc-Kommentar `hermes_tokens.dart:18`, Praxis `hermes_stat_tile.dart:138-143`).

## 2. Elevation-Prinzip: Border statt Schatten

Hermes-Regel (Doc-Kommentar `hermes_tokens.dart:15`): *„Elevation comes from a 1px border plus a tint, not from a shadow."*

Code-Belege:
- Theme-seitig: `CardThemeData` mit `elevation: 0` und `side: BorderSide(color: t.border, width: HermesTokens.borderWidth)` — `mint_y.dart:236-244`. Jedes Material-`Card` bekommt damit flächige Hairline statt Schatten.
- Widget-seitig: `HermesCard` baut `BoxDecoration` mit 1px-Border; der 2px-Akzent-Spine wird als `Positioned`-Overlay im `Stack` gemalt, weil Flutter unterschiedlich gefärbte Border-Seiten an gerundeten Ecken ablehnt (`widgets/hermes/hermes_card.dart:50-80`, Kommentar :57-59).
- Einzige absichtliche Ausnahme: `HermesHaloDot` nutzt `BoxShadow` mit `spreadRadius` als Halo — CSS-Äquivalent `box-shadow: 0 0 0 3px <tint>` (`widgets/hermes/hermes_halo_dot.dart:5-8, 36-43`). Kein echtes Elevation-Rendering.

## 3. Magic-Number-Abweichungen (Grep, 2026-09-10)

### Radien (Literale außerhalb der Tokens)

| Stelle | Wert | Kontext | Soll-Token |
|---|---|---|---|
| `layouts/main_screen/action_entry_card.dart:47` | 10.0 | ListTile-Shape der Suchergebnisse | — (näheste: `radiusMd`=8) |
| `layouts/hub/hub_shell.dart:466` | 9 | 32px-Brand-Logo „LA" | optisch zwischen Sm/Md |
| `layouts/greeter/flathub_permissions.dart:23` | 20 | Hero-Panel Greeter | — |
| `layouts/disk_cleaner/clean_disk.dart:134` | 7 | Progress-Balken (minHeight 15) | — |
| `layouts/disk_cleaner/cleaner_select_disk.dart:47` | 2 | Mini-Progress (minHeight 5) | — |

Auffällig: Genau diese Werte (2/7/8/10/20) sind in `MintYRadius` (`mint_y_tokens.dart:225-240`) bereits als Tokens benannt (xs/sm/md/lg/xl) — **aber niemand nutzt sie** (0 Referenzen, Grep). Die Token-Datei dokumentiert den Ist-Zustand, ersetzt ihn noch nicht. Die drei Progress-Radii korrelieren mit der Balkenhöhe (2→5px, 7→15px Balken) — das ist eher halbe-MinHeight-Logik als ein Radius-System.

### Spacings & feste Maße (Literale)

| Stelle | Wert | Kontext |
|---|---|---|
| `layouts/hub/hub_shell.dart:71` | 260 | Sidebar-Breite (`_sidebarWidth`) |
| `layouts/hub/hub_shell.dart:72` | 56 | Rail-Breite kollabiert (`_railWidth`) |
| `layouts/hub/hub_shell.dart:75` | 1000 | Collapse-Breakpoint |
| `layouts/hub/hub_shell.dart:519` | 52 | Top-Bar-Höhe |
| `layouts/mint_y.dart:352` | 26 | MintYPage-Header-Padding |
| `layouts/mint_y.dart:288` | 40 | `MintY.showMessage`-Dialog-Padding |
| `layouts/mint_y.dart:380, 978, 1036` | 80 | Bottom-Slot-Höhe / Spinner-Kanten |
| `layouts/main_screen/main_search.dart:128` | 20 | Launcher-Karten-Padding |
| `layouts/run_command_queue.dart:254` | 64 | Footer-Höhe |
| `layouts/feedback/feedback_send.dart:14` | 64 | Feedback-Seiten-Padding |
| `layouts/main_screen/main_search.dart:152-153` | 600 | Launcher-Breite (Fenster > 750px), sonst viewport-abhängig |
| `layouts/settings/appearance_settings.dart:18` | `min(600, width-100)` | Settings-Panels-Breite |
| `layouts/main_screen/recommendation_card.dart:33-34` | 450×120 | Empfehlungskarte |
| `mint_y.dart:599-600 / :787-788 / :892-897` | 400×350 / 400×300 / Grid-Defaults | selectable Karten / Big-Button / `MintYGrid` |

`MintYSpacing` (`mint_y_tokens.dart:244-249`: 8/10/16/32) benennt einen **anderen** (8/10/16/32) Raster-Vorschlag als HermesTokens (4/8/12/16) und trägt selbst das TODO „auf 4er/8er-Raster vereinheitlichen" (`:243`). Ungenutzt; vor Aktivierung müssen sich die beiden Raster auf eines einigen.

## 4. Bewertung

- Hub + Hermes-Widgets: konsistent — ausschließlich `HermesTokens.space*/radius*` (spot-checked in hub_shell.dart, dashboard/storage_section, hermes-Widgets).
- Legacy-Screens (Launcher, Disk-Cleaner, Greeter, after_installation): Magic Numbers, teils funktional begründet (Progress-Höhen), teils historisch (26/40 aus der Upstream-Ära).
- Zwei konkurrierende Token-Sätze (`HermesTokens` vs. ungenutztes `MintYRadius`/`MintYSpacing`) — siehe colors.md §3, Auflösung offen.

Screenshots: Radien/Spacings sichtbar in `screenshots/v0.7.1/00-start_dark_01.png` (Karten), `05-einstellungen_light.png` (Dialog), `02-speicher_dark.png` (Progress-Elemente).
