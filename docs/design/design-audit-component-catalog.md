# Design-Audit: Komponenten-Katalog
## Alle wiederverwendbaren Widget-Klassen (Phase 1, Schritt 3)

> Quelle: Code-Search über Konstruktoren (`super.key`), Props und Verwendungsstellen.
> Basis: Upstream Jean28518/linux-assistant + Fork-eigene Hermes-Widgets.
> ✅ = Props verifiziert aus Konstruktor-Fragmenten · ⚠️ = teilweise aus Verwendung rekonstruiert

---

## 1. Core-Komponenten (`lib/layouts/mint_y.dart`)

| Komponente | Props | Zustände | Verwendung |
|---|---|---|---|
| **MintYPage** ✅ | `title: String`, `contentElements: List<Widget>`, `customContentElement: Widget`, `bottom: Widget?` | – (stateless Container) | **19+ Screens** – das Layout-Grundgerüst der App (greeter, updater, grub_config, cleaner, uninstaller, introduction, flatpak_check, …) |
| **MintYButton** ✅ | `text: Widget` (Default `Text("")`), `icon: Widget?`, `color: Color`, `onPressed`, `width: double`, `height: double`, `tooltip: String?` | default, hover (implizit), disabled (via `onPressed: null`) | **24+ Stellen** – primärer Action-Button überall |
| **MintYButtonNavigate** ✅ | `route: Widget`, `color`, `text`, `onPressed` (optional überschreibt Navigation) | wie MintYButton | **14+ Stellen** – Bottom-Bar-Navigation (Zurück/Weiter/„Let's start") |
| **MintYFeature** ✅ | `icon: Widget`, `heading`, `description` | – | feature_overview (Feature-Kachel, width 300, gaps 15/20) |
| **MintYTable** ✅ | `data: List<List<dynamic>>` – erste Zeile = Headings | – | linux_health (Top-Memory-Prozesse) |
| **MintYProgressIndicatorCircle** ⚠️ | – | loading | cleaner_select_disk (Ladezustand) |
| **MintYCardWithAction** ⚠️ | `buttonText`, `customWidgetBetweenButtonAndText`, `customWidgetRightOfButton`(?) | – | cleaner_select_disk (Disk-Auswahl-Karten) |

**Befund Core:** `MintYButton` hat keine Varianten-API – `color` wird frei gesetzt
(`MintY.currentColor`, `Colors.grey`, `Colors.white`). → Roadmap: Varianten-Enum
(`primary|secondary|ghost|danger`). Zwei Klassen (`MintYButton` + `MintYButtonNavigate`)
überlappen funktional → zusammenführen mit optionalem `route`-Param.

---

## 2. Dashboard-Widgets (`lib/widgets/`)

| Komponente | Props | Zustände | Befund |
|---|---|---|---|
| **SingleBarChart** ✅ | `value: double` (0.5), `size: double` (100), `backgroundColor` (#D3D3D3), `fillColor` (#494949), `text: String`, `textStyle: TextStyle`, `tooltip: String`, `customWidgetRightOfBar: Widget?` | normal, dark (⚠️ Mutations-Hack #575757), mit Custom-Widget | Kritisch: final-Feld-Mutation im build (siehe Inkonsistenzen §2.1) |
| **MemoryStatus** ✅ | – (liest Systemdaten selbst) | loading, normal (CPU<100 %), critical (rot) | Magic Numbers → PR #10 |
| **DiskSpace** ✅ | – (liest `Linux.getDiskspace()`) | normal (<89 %), warning (>89 %, rot + Clean-Affordance) | Magic Number 89 → PR #10 |
| **HardwareInfo / InfoLineWithIcon** ✅ | `text: String`, `iconData: IconData`, `textStyle: TextStyle?` | – | Icon 15px in Akzentfarbe, gap 5 |
| **SystemIcon** ✅ | `iconString: String`, `iconSize: double` | loaded (System-Icon via IconLoader), fallback (Material-Icon in Akzent) | Gutes Pattern, Cache in IconLoader |
| **SuccessMessage** ✅ | `text: String` | – | Icon check 32px grün, gap 8, padding 4 |
| **WarningMessage** ✅ | `text: String`, `fixAction: Function?` | mit/ohne Fix-Button | Icon warning 32px orange; Fix-Button = MintYButton |

---

## 3. Main-Screen-Komponenten

| Komponente | Datei | Props | Zustände |
|---|---|---|---|
| **ActionEntryCard** ✅ | main_screen/action_entry_card.dart | `actionEntry: ActionEntry` (name, description, iconWidget, priority), `selected: bool` | default (transparent), selected (`Theme.focusColor`) – Radius 10 |
| **RecommendationCard** ✅ | main_screen/recommendation_card.dart | `entry` (name, description) | – |
| **MainSearch** ✅ | main_screen/main_search.dart | – (StatefulWidget, Such-Index) | empty (Höhe 50/16-Weiche), results, bash-Fallback (`Icons.code`) |

---

## 4. Settings-Komponenten (`lib/layouts/settings/settings_widgets.dart`)

| Komponente | Props | Zustände |
|---|---|---|
| **SettingWidgetOnOff** ✅ | `settingKey: String`, `text`, … | on / off (MintYButton-Paar) |
| **SettingWidgetTextField** ⚠️ | `textEditingController`, `parseFunction: Function?`, Save-Button (Icon 24px weiß) | default, saved |
| **Settings-Dialog (settings_start)** ⚠️ | Dialog-Shell, Hero-Icon 64px | appearance_settings / environment_selection / … (State-String-basiert ⚠️) |

**Befund Settings:** Navigation innerhalb der Settings läuft über einen
`state`-String (`"appearance_settings"`) statt über Routen – fehleranfällig,
nicht deeplinkbar. → Kandidat für PR C (Settings-Migration).

---

## 5. Dialog-/Feedback-Komponenten

| Komponente | Datei | Props | Zustände |
|---|---|---|---|
| **FeedbackDialog** ✅ | feedback/feedback_form.dart | `calledFromHome: bool`, `includeBasicSystemInformation: bool` | form, sending |
| **FeedbackSent** ✅ | feedback/feedback_send.dart | `success: Future<bool>` | sending (Spinner), done, error |
| **ShutdownDialog** ✅ | shutdown/shutdown_dialog.dart | `minutes: int` (mutable Feld ⚠️) | config, countdown |
| **RunCommandQueue** ✅ | layouts/run_command_queue.dart | static `shutdownAfterwards: bool` ⚠️ (global mutable) | running (Terminal-View), done, error (Retry-Button) |
| **CommandTable** ✅ | layouts/run_command_queue.dart | `tableData: List<List<String>>` | – |

---

## 6. Hermes-Layer (Fork, `lib/widgets/hermes/`) – ⏸️ Backlog

| Komponente | Größe | Vermutete Props | Status |
|---|---|---|---|
| HermesCard | 3.4 KB | – | ⏸️ nicht auditiert (Backlog) |
| HermesBadge | 2.9 KB | – | ⏸️ |
| HermesNavItem | 3.3 KB | – | ⏸️ |
| HermesStatTile | 4.6 KB | – | ⏸️ |
| HermesSparkline | 2.9 KB | – | ⏸️ |
| HermesHaloDot | 1.3 KB | – | ⏸️ |
| HermesCopyCommand | 3.2 KB | – | ⏸️ |

→ Audit erst bei Reaktivierung (Kriterien in `hermes-backlog.md`).

---

## 7. Zustands-Matrix (Soll-Zustand)

Aktuell definiert vs. Roadmap-Ziel:

| Komponente | default | hover | focus | disabled | loading | selected | error |
|---|---|---|---|---|---|---|---|
| MintYButton | ✅ | ⚠️ implizit | ❌ | ⚠️ via null | ❌ | – | ❌ |
| ActionEntryCard | ✅ | ❌ | ✅ (focusColor) | ❌ | – | ✅ | ❌ |
| SingleBarChart | ✅ | – | – | – | ❌ | – | ⚠️ (Hack) |
| SuccessMessage | ✅ | – | – | – | – | – | – |
| WarningMessage | ✅ | – | – | – | – | – | ✅ |
| MemoryStatus | ✅ | – | – | – | ✅ | – | ✅ |
| DiskSpace | ✅ | – | – | – | ✅ | – | ✅ |

**Lücken:** Keine definierten Focus-Ringe (A11y), kein Loading-Zustand bei
Buttons, Hover nicht spezifiziert. → Phase 3 (Komponenten-Härtung).

---

## 8. Handlungs-Empfehlungen aus dem Katalog

1. **MintYButton + MintYButtonNavigate mergen** – eine Klasse, optionales `route`
2. **Varianten-Enum** statt freiem `color`-Param (killt `Colors.grey`/`Colors.white`-Verstöße automatisch)
3. **Settings-State-String → echte Routen** (PR C)
4. **Mutable Felder aufräumen:** `ShutdownDialog.minutes`, `RunCommandQueue.shutdownAfterwards` (static!) → State Management
5. **Widgetbook** für die 15 Kern-Komponenten (Phase 3, Schritt 5)
