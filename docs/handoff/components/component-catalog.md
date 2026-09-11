# Komponenten-Katalog — wiederverwendbare Widgets

Stand: 2026-09-10, Zweig `hardening/0.8.0`. Verwendungsorte per Grep über `lib/` (Definitionsdatei jeweils ausgenommen). Screenshot-Bezüge: `screenshots/v0.7.1/<name>.png`.

Überblick: **2 Familien + Misc.** Hermes (9 Widgets, hub-seitig, token-basiert) · MintY-Legacy (15 Widgets in `mint_y.dart`, Greeter/after_installation/Dialoge) · Misc (8 Einzelwidgets meist Launcher-/Health-Spezifisch).

---

## A. Hermes-Familie (`lib/widgets/hermes/`, 7 Dateien / 9 Klassen)

| Widget | Zweck | Props (Signatur) | Def | Aktive Verwendung | Screenshot | Migrationsstatus |
|---|---|---|---|---|---|---|
| `HermesCard` | Basiskarte: 1px-Border, kein Schatten, optional 2px-Spine links, optional tappbar | `child`, `padding` (default space4), `onTap`, `spineColor`, `background`, `width`, `height` | hermes_card.dart:10-82 | dashboard_section, storage_section, security_check/overview, security_check/security_finding | `00-start_dark_01.png`, `02-speicher_dark.png` | **hermes-reif** — Referenz-Implementation des Elevation-Prinzips |
| `HermesSectionHeader` | Uppercase-Metadaten-Label mit Divider + optionalem `trailing` | `text`, `trailing?` | hermes_card.dart:85-124 | system_monitor, storage_section, dashboard_section | `00-start_dark_01.png` | **hermes-reif**; Achtung: hub_shell.dart:436-454 (`_sectionLabel`) ist eine funktional identische Kopie ohne Divider → konsolidieren |
| `HermesBadge` | Pill-Badge mit Ton-Formel (fg solid / bg 10 % / border 28 %) | `text`, `tone` (HermesTone), `icon?`, `dense` | hermes_badge.dart:55-107 (Tone-Enum :5, Resolver :25-52) | dashboard_section, storage_section, security_check/overview, security_finding, system_monitor | `00-start_dark_01.png`, `03-gesundheit_dark.png` | **hermes-reif** — zentraler Baustein, `hermesToneColors()` auch von StatTile/HaloDot genutzt |
| `HermesNavItem` | Sidebar-Zeile: muted → hover → accentBg + 2px-Spine aktiv; Rail-Modus | `icon`, `label`, `selected`, `onTap`, `trailing?`, `collapsed` | hermes_nav_item.dart:8-114 | nur hub_shell.dart:375-381 (Sektionen), :388-394 (Werkzeuge), :401-410 (Settings) | `00-start_dark_01.png` (Sidebar) | **hermes-reif** — Single-Use ist ok (Shell ist der eine Ort) |
| `HermesStatTile` | Dashboard-Tile: 11px-Label, 28px-Wert, optional visual/footer/badge | `label`, `icon`, `value?`, `unit?`, `tone`, `badge?`, `visual?`, `footer?`, `onTap?` | hermes_stat_tile.dart:10-111 | dashboard_section, system_monitor | `00-start_dark_01.png`, `00b-dashboard_light.png` | **hermes-reif** |
| `HermesMetaRow` | Kompakte `label — value`-Zeile für Tile-Footer (12px, tabellarische Ziffern, Opacity-De-Emphasis) | `label`, `value`, `valueTone?` | hermes_stat_tile.dart:115-158 | dashboard_section, storage_section, system_monitor | `00-start_dark_01.png` | **hermes-reif** |
| `HermesSparkline` | Mini-Liniendiagramm (CustomPainter, ≤60 Punkte, keine Achsen — Bewusst-Entscheidung :6-8) | `values` (alt→neu), `color?`, `height` (=36), `maxValue` (=1.0) | hermes_sparkline.dart:9-41 | dashboard_section, system_monitor | `00b-dashboard_light.png` | **hermes-reif** — bewusst ohne fl_chart |
| `HermesHaloDot` | 7px-Statuspunkt mit 3px-Halo (CSS `box-shadow`-Äquivalent) | `tone`, `size` (=7), `haloWidth` (=3) | hermes_halo_dot.dart:9-48 | nur system_monitor | `03-gesundheit_dark.png` (Systemmonitor ist kein v0.7.1-Shot) | **hermes-reif** (gering genutzt, aber korrekt gebaut) |
| `HermesCopyCommand` | Monospace-Befehlszeile mit Copy-Button — Remediation ohne Ausführung (Doc :8-10) | `command`, `caption?` | hermes_copy_command.dart:11-100 | security_check/security_finding | `04b-sicherheit_nach-scan_dark.png` (Kontext) | **hermes-reif** |

## B. MintY-Legacy-Familie (`lib/layouts/mint_y.dart`, 15 Widgets)

Zeit-Pfad-Kontext: Greeter → after_installation → Feature-Overview; Hub nutzt sie nur noch für Buttons/Loading/Dialoge.

| Widget | Zweck | Props (Kurzschrift) | Def | Aktive Verwendung | Migrationsstatus |
|---|---|---|---|---|---|
| `MintYPage` | Seiten-Scaffold mit Akzent-Gradient-Header + Titel | `title`, `contentElements`, `customContentElement`, `bottom?` | mint_y.dart:320-389 | greeter (start_screen), after_installation/* (7 Dateien), run_command_queue, flatpak_check, power_mode, updater u. a. | **bleibt-legacy** — Gradient-Header widerspricht Hermes-Look; Hub-Sektionen nutzen stattdessen `HermesSectionHeader`. Ersatz erst sinnvoll, wenn Greeter-Flow redesignen wird |
| `MintYButton` | Standard-ElevatedButton (min 110×40), optional Icon/Tooltip | `text`, `icon?`, `color` (deprecated), `backgroundColor`, `textColor`, `onPressed?`, `width`, `height`, `tooltip?` | mint_y.dart:391-481 | 14 Dateien (ubiquitär: Dialoge, Greeter, Cleaner, Settings) | **bleibt-legacy (vorerst)** — 14 Aufrufstellen, aber Farb-API deprecated (`color`→`backgroundColor`, :395-427). Ein Hermes-Button existiert nicht; erst bauen, dann migrieren. **unklar**, ob er mittelfristig als Thin-Wrapper um den M3-Button weiterlebt |
| `MintYButtonNavigate` | Button + `Navigator.push` auf Widget-Route | `route`, `text`, `color`, `width`, `height`, `onPressed?` | mint_y.dart:483-519 | uninstaller, shutdown_dialog, after_installation, greeter, feature_overview, linux_health, settings_start | **bleibt-legacy** — Push-Navigation ist im Hub bewusst tabu (hub_shell.dart:52-55-Kommentar); im Greeter-Flow weiterhin korrekt |
| `MintYButtonNext` | „Weiter"-Button mit optionaler async-Aktion + LoadingPage-Zwischenschritt | `route`, `onPressed?`, `onPressedFuture?` | mint_y.dart:521-557 | greeter/start_screen, after_installation/* (6 Dateien), run_command_queue | **bleibt-legacy** — Greeter-Flow-Spezifisch (LoadingPage + Next-Metapher) |
| `MintYSelectableCardWithIcon` | Große Auswahl-Karte (400×350) mit Check-Icon bei Auswahl | `icon`, `title`, `text`, `selected`, `onPressed?` | mint_y.dart:559-639 | nur after_installation/office_selection | **bleibt-legacy** — Single-Use im Greeter |
| `MintYSelectableEntryWithIconHorizontal` | Horizontale Auswahl-Zeile mit optionalem Info-Text | `icon`, `title`, `text`, `selected`, `infoText?`, `showInfoTextAtThisSelectionState`, `onPressed?` | mint_y.dart:641-762 | after_installation/* (4 Dateien), settings_start | **bleibt-legacy** — Settings-Start nutzt es als Kachel-Äquivalent; ein Hermes-Gegenstück fehlt (Kandidat für `HermesCard`+Spine) |
| `MintYButtonBigWithIcon` | Große Kachel-Karte (400×300) | `icon`, `title`, `text`, `onPressed?` | mint_y.dart:764-809 | nur after_installation/automatic_configuration_entry | **bleibt-legacy** — Single-Use |
| `MintYCardWithIconAndAction` | Karte Icon + Titel/Text + Action-Button | `icon`, `title`, `text`, `buttonText`, `customWidgetBetweenButtonAndText?`, `onPressed?` | mint_y.dart:811-885 | disk_cleaner/cleaner_select_disk, clean_timeshift, remove_software | **bleibt-legacy** — Cleaner-Screens; `HermesCard(onTap:)` + Badge könnte das ersetzen, Cleaner ist aber ohnehin Roadmap-Kandidat |
| `MintYGrid` | Responsive GridView mit Zentrier-Auffüllung | `children`, `padding` (=10), `ratio` (=350/150), `widgetSize` (=450) | mint_y.dart:887-926 | feature_overview, after_installation/*, settings_start, disk_cleaner/* (8 Dateien) | **bleibt-legacy** — breit verankert im Greeter/Cleaner; Verhalten (Füll-Container) ist ein Hook, kein Bug, aber dokumentieren |
| `MintYFeature` | Icon links, Heading+Beschreibung rechts | `heading`, `description`, `icon` | mint_y.dart:929-969 | greeter/introduction, feature_overview | **bleibt-legacy** — 2 Legacy-Screens |
| `MintYProgressIndicatorCircle` | 80×80 Spinner in `MintY.currentColor` | — (const) | mint_y.dart:971-984 | run_command_queue, after_installation/*, disk_cleaner/*, linux.dart, main_search_loader (10+ Stellen) | **bleibt-legacy** — aber trivial durch M3-`CircularProgressIndicator` mit `color: Theme…primary` ersetzbar; Low-Hanging-Fruit für V0.8.X |
| `MintYTable` | 2D-String-Tabelle, Zeile 1 = Headline-Style | `data` | mint_y.dart:988-1021 | linux_health/overview, run_command_queue | **unklar** — linux_health (Hub-Sektion!) rendert sie noch; für Tabellen im Hermes-Look fehlt ein Gegenstück (Prozesstabelle in health nutzt eigenes Layout). Migration mit V0.9-Health-Rework |
| `MintYLoadingPage` | Ganzseiten-Loading (Spinner + „Loading…") | `text` | mint_y.dart:1024-1052 | greeter, linux_health, updater, security_check, power_mode, main_search_loader, linux.dart | **bleibt-legacy** — App-weiter Loading-Standard; ein Hermes-Loading-State existiert nicht |
| `MintYCheckboxSetting` | Einstellungszeile Text + Checkbox | `text`, `value`, `onChanged` | mint_y.dart:1054-1101 | nur grub_config | **bleibt-legacy** — Single-Use, abseits vom Hauptpfad; Hub-Settings nutzen `settings_widgets.dart` (eigene Familie) |
| `MintYTextSetting` | Einstellungszeile Text + TextField (200px) | `text`, `value`, `textAlign`, `onChanged` | mint_y.dart:1103-1165 | grub_config | **bleibt-legacy** — dito |

**Querverweis:** die Hub-seitigen Settings-Widgets (`SettingWidgetOnOff`, `SettingWidgetText`, … in `layouts/settings/settings_widgets.dart`) sind eine **dritte, eigene** Familie (u. a. White-Hardcode :158) — im Katalog hier nur der Vollständigkeit halber erwähnt; eigene Aufnahme wäre V0.8.X-Aufgabe.

## C. Misc-Widgets

| Widget | Zweck | Props | Def | Verwendung | Screenshot | Migrationsstatus |
|---|---|---|---|---|---|---|
| `DiskSpace` | Horizontale Balkenliste aller Mounts (>89 % → rot + Aufräumen-Sprung) | — (const) | widgets/disk_space.dart:11-114 | nur main_search.dart:138 | `01-suche_dark.png`, `06-suche-fokus_light.png` | **bleibt-legacy** — nur im Launcher; Storage-Sektion hat eigenes, hermes-basiertes Layout (`storage_section.dart`). Werte `>89`/Grau sind hartkodiert (colors.md §4) |
| `SystemStatus` | CPU/RAM(/Swap)-Balken + Hardware-Info, liest `SystemStatsService` (ref-counted, :21-33) | — (const) | widgets/memory_status.dart:13-106 | nur main_search.dart:140 | `01-suche_dark.png` | **bleibt-legacy** — Logik gut (Service-getrieben), Farben hartkodiert; Dashboard nutzt bereits `HermesStatTile`+`HermesSparkline` als modernes Äquivalent |
| `SingleBarChart` | Einzelner fl_chart-Balken mit Label/Tooltip | `value`, `size`, `backgroundColor`, `fillColor`, `text`, `textStyle`, `tooltip`, `customWidgetRightOfBar?` | widgets/single_bar_chart.dart:4-111 | intern von DiskSpace (:42) und SystemStatus (:51,64,73) | `01-suche_dark.png` | **bleibt-legacy** — Hilfswidget der beiden oberen; Dark-Mode-Sonderfall hardcoded (:32-35). fl_chart-Abhängigkeit nur hierfür — bei Migration entkoppeln |
| `SuccessMessage` | Check-Icon + Text | `text` | widgets/success_message.dart:3-32 | linux_health/overview | `03-gesundheit_dark.png` (Kontext) | **kleiner Migrationsschritt**: `Colors.green` (:16) → `HermesTone.success`/`HermesBadge` |
| `WarningMessage` | Warn-Icon + Text + optionaler Fix-Button | `text`, `fixAction?` | widgets/warning_message.dart:5-55 | linux_health/overview | dito | **kleiner Migrationsschritt**: `Colors.orange` (:21) → `HermesTone.warning`; Fix-Button-Konzept ist wertvoll und sollte in den Hermes-Katalog wandern |
| `SystemIcon` | Lädt System-App-Icons (Cache + FutureBuilder), Nouveau-Fallback | `iconString`, `iconSize` (=100), `spinner` (=true) | widgets/system_icon.dart:6-49 | after_installation/*, feature_overview, disk_cleaner/* | — | **bleibt-legacy (Infrastruktur)** — kein Style-Widget, sondern Icon-Loader-Adapter; bleibt, unabhängig vom Theme |
| `ActionEntryCard` | Suchergebnis-Zeile (ListTile) mit Icon-Delay-Loading (200 ms, :79-83) | `actionEntry`, `callback`, `selected` | layouts/main_screen/action_entry_card.dart:9-145 | nur main_search | `06-suche-fokus_light.png` | **bleibt-legacy** — eng an ActionEntry-Modell gekoppelt; Radius-10-Shape (shapes-spacing.md §3) |
| `RecommendationCard` | Zufällige Empfehlung (450×120); erste 5 Starts nach Installation fix (:17-25) | — (const) | layouts/main_screen/recommendation_card.dart:8-67 | nur main_search | `01-suche_dark.png` | **bleibt-legacy** — Launcher-spezifisch; Config-Schreibzugriff im Build (:23) ist unschön, aber funktional |

## D. Fazit / Reihenfolge

1. **Hermes-Familie ist vollständig und hub-fest** — nichts dort ist Legacy.
2. **Kleinste Migrations-Hebel:** SuccessMessage/WarningMessage auf `HermesTone`, MintYProgressIndicatorCircle auf Theme-Color, hub_shell-`_sectionLabel` mit `HermesSectionHeader` verschmelzen.
3. **Große Blöcke bewusst lassen:** Greeter/after_installation-Flow (MintYPage-Gradient-Header, Selectable-Cards) — erst mit Redesign anfassen; dort läuft die App-Funktion gut.
4. **Designentscheidung offen:** MintYButton-Frage (14 Dateien) — Wrapper behalten vs. ersetzen; hängt mit der MintYColors-Frage (colors.md §3) zusammen.
