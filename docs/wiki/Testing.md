# Testing

## Suite-Überblick (`test/`)

| Datei | Gegenstand | Pattern |
|---|---|---|
| `app_launcher_test.dart` | E1 Browser-Fallback-Kette | Service-Test |
| `notes_service_test.dart` | E2 NotesService | Temp-Dir-Fixtures |
| `file_browser_service_test.dart` | E4 FileBrowserService | Temp-Dir + Symlinks |
| `system_monitor_service_test.dart` | E3 Parser & Helfer | String-Fixtures |
| `system_parsers_test.dart` | SystemStatsService, Parser | Fixtures + Service-Gating |
| `environment_test.dart` | Distro-Fallback, Enum-Roundtrips, Versionsvergleich | Pure Functions |
| `hermes_tokens_test.dart` | Token-Konsistenz | Unit |
| `hermes_widgets_test.dart` | Hermes-Widgets | Widget-Tests |
| `widget_test.dart` | App-Smoke | Widget-Test |

Ausführen: `flutter test` (aktuell: 128 Tests).

## Etablierte Patterns

1. **Services sind injizierbar.** Beispiele: `NotesService.test(directory)`,
   `SystemMonitorService(readFile: …)` (FileReader-Typedef),
   `FileBrowserService` ohne Konstruktor-Zwang. → Tests ohne echtes
   System.
2. **Parser sind reine statische Funktionen.** Sie nehmen Strings (Inhalt
   von `/proc/stat`, `ps`-Output, …) und liefern Modelle. Fixtures leben
   als `const`-Strings im Test. Delta-Berechnungen werden mit
   nachgerechneten Erwartungswerten geprüft (`closeTo`).
3. **Fehler in-band.** `DirListing.error` statt Exception – der Screen
   rendert Berechtigungsprobleme inline.
4. **Destructive Logik hat Guard-Tests:** Protected-Pfade werden abgelehnt
   *bevor* das Dateisystem angefasst wird; Symlink-Delete berührt nie das
   Ziel; Verzeichnis-Delete braucht `recursive`.
5. **Service-Gating ist getestet:** `system_parsers_test.dart` deckt die
   drei Polling-Bedingungen des `SystemStatsService` ab (Subscriber,
   Section, Fenster) inkl. `resetForTesting`.

## Erwartungswerte verifizieren

Lehre aus #21: handgerechnete Erwartungswerte sind ein Fehlervektor. Für
Delta-Mathe gilt: Erwartung **per Rechnung** gegen die Fixture prüfen,
bevor sie in den Test wandert. Beispiel aus `system_monitor_service_test.dart`:

```
aggregate: dBusy 330 / dTotal 1050 = 31.43 %
core:      dBusy  55 / dTotal  515 = 10.68 %
```

## Golden-Tests (Status: zurückgestellt)

Der erste Golden-Test (#11) importierte `golden_toolkit`, ohne dass die
Dependency in `pubspec.yaml` stand – der Loader brach die gesamte Suite.
In #21 entfernt; Reaktivierung lokal:

```bash
flutter pub add --dev golden_toolkit
git add pubspec.yaml pubspec.lock
git show 4e716d7:test/goldens/layout_golden_test.dart > test/goldens/layout_golden_test.dart
# const vor SuccessMessage/WarningMessage/SingleBarChart entfernen
flutter test test/goldens/layout_golden_test.dart --update-goldens
```

Details & Plattform-Falle (Fonts/OS-Sensitivität): `docs/design/screenshot-baseline.md` §4,
Schritte: `docs/design/admin-hub-followups.md` §3. Neue Screens (Quick Notes,
Dateimanager, Systemmonitor) sollen danach Baselines bekommen.

## CI

`.github/workflows/build.yml` (ubuntu-24.04 gepinnt): `flutter test` läuft
**vor** den Packaging-Schritten – ein roter Test failt früh. `flutter analyze`
läuft bewusst nicht (189 pre-existing Findings; siehe Commit `1e90957` -
Wiedereinführung erst nach Backlog-Abbau).
