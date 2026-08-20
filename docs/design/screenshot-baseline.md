# Screenshot-Baseline (Phase 1, Schritt 4)
## Visuelle Referenz für alle Layouts sichern

> Status: Setup-Anleitung + fertige Golden-Test-Datei
> (`test/goldens/layout_golden_test.dart`, Teil dieses PRs).
> Stand: Es gibt **keine** bestehenden Golden-Tests im Repo (geprüft:
> `matchesGoldenFile`/`golden_toolkit` – 0 Treffer). Der Fork hat bereits
> `test/hermes_tokens_test.dart` und `test/hermes_widgets_test.dart` –
> gute Basis, aber keine Bild-Baselines.

---

## 1. Warum Golden Tests statt manueller Screenshots?

| Kriterium | Manuelle Screenshots | Golden Tests |
|---|---|---|
| Reproduzierbar | ❌ (abhängig von System, Theme, Fonts) | ✅ identisch bei jedem Lauf |
| CI-fähig | ❌ | ✅ Visual Regression pro PR |
| Theme-Varianten | Aufwand × N Themes | ✅ Matrix (3 Akzente × dark/light) |
| Aufwand initial | gering | mittel (Mocks für System-Daten) |

**Empfehlung:** Goldens als Haupt-Baseline + einmalig manuelle Screenshots
der echten App als Referenz für „sieht auf echtem System richtig aus".

---

## 2. Setup (einmalig, ~10 min)

```bash
# 1. Dependency ergänzen (pubspec.yaml, dev_dependencies):
#    golden_toolkit: ^0.15.0
flutter pub add --dev golden_toolkit

# 2. Test-Datei liegt unter:
#    test/goldens/layout_golden_test.dart

# 3. Baseline generieren:
flutter test test/goldens/layout_golden_test.dart --update-goldens

# 4. Ergebnis prüfen:
ls test/goldens/goldens/
#   button.dark.mint.png      barchart.dark.mint.png
#   button.dark.debian.png    messages.dark.mint.png  …
```

### Was die mitgelieferte Test-Datei abdeckt

| Gruppe | Goldens | Zweck |
|---|---|---|
| Core-Komponenten × 3 Akzente (mint/debian/zorin) | `button.dark.*`, `messages.dark.*`, `barchart.dark.*` | Token-Korrektheit pro Distro-Akzent, Dark Theme |
| MintYPage-Gerüst | `page.dark.mint` (1280×720) | Layout-Grundgerüst in App-Fenstergröße |
| Light-Theme | `button.light.mint` | Kontrast-Referenz (Light war zweitklassig) |

**Warum mint/debian/zorin:** Mint = Default, Debian = stärkste Abweichung
(`#D0074E`/`#4B0523`), Zorin = Roadmap-Erweiterung.

---

## 3. Layouts mit System-Abhängigkeiten (der knifflige Teil)

Diese Screens lesen echte Systemdaten und brauchen Mocks für stabile Goldens:

| Layout | System-Abhängigkeit | Mock-Strategie |
|---|---|---|
| `greeter/introduction` | Config (`runIntroduction`) | ConfigHandler mit Memory-Backend |
| `main_screen/main_search` | Such-Index, DiskSpace, SystemStatus | Fake-Index + Fake-Diskdaten |
| `disk_cleaner/*` | `Linux.getDiskspace()` | Fake: 3 Disks (40 %, 91 %, 65 %) |
| `security_check/overview` | Update-Check, Home-Rechte, Quellen | Fake: je 1× ok/warn |
| `linux_health/overview` | Prozesse, Laufzeit | Fake-Prozessliste (5 Einträge) |
| `power_mode` | aktuelles Power-Profil | Fake: „balanced" aktiv |
| `settings/*` | ConfigHandler | Memory-Backend |

**Empfohlenes Muster:** Service-Interface einführen und im Test injizieren:

```dart
abstract class SystemInfoProvider {
  Future<List<DiskInfo>> getDisks();
  Future<double> getCpuLoad();
}

class FakeSystemInfoProvider implements SystemInfoProvider {
  @override
  Future<List<DiskInfo>> getDisks() async => [
        DiskInfo(mountpoint: '/', usedPercent: 91),   // triggert Rot
        DiskInfo(mountpoint: '/home', usedPercent: 40),
      ];
  @override
  Future<double> getCpuLoad() async => 0.42;
}
```

Das ist zugleich die Vorbereitung für PR B/C (Dashboard/Settings-Migration) –
wer die Provider einführt, kann die Widgets danach sauber auf Tokens umstellen.

### Zwischenlösung bis dahin: manuelle Screenshots

```bash
# App starten und pro Layout einen Screenshot sichern:
flutter run -d linux
# GNOME/Zorin: Screenshot-Tool oder:
import -window "linux_assistant" screenshots/main_search.png
```

Ablage: `docs/design/baseline/<layout>.png` + kurze Notiz
(Distro, Theme, Auflösung) pro Bild.

---

## 4. CI-Anbindung (Phase 5 vorgreifen)

```yaml
# .github/workflows/golden-tests.yml (Skelett)
name: Golden Tests
on: [pull_request]
jobs:
  goldens:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      # Achtung: Goldens sind plattform-/font-sensitiv.
      # Lokal generierte PNGs (Zorin) ≠ CI (ubuntu-latest).
      # → Baseline entweder in CI generieren und committen,
      #   oder golden_toolkit mit festen Fonts nutzen.
      - run: flutter test test/goldens/layout_golden_test.dart
```

⚠️ **Plattform-Falle:** Golden-PNGs sind font- und OS-sensitiv. Entweder die
Baseline **in der CI** erzeugen (`--update-goldens` dort laufen lassen und als
Artefakt committen) oder konsequent `loadAppFonts()` + gleiche Flutter-Version
pinnen (`.github` + `pubspec.lock`).

---

## 5. Definition of Done für Schritt 4

- [ ] `golden_toolkit` in `pubspec.yaml` (dev_dependencies)
- [ ] `test/goldens/layout_golden_test.dart` abgelegt (dieser PR)
- [ ] Erste Baseline generiert (Core + MintYPage, 8 Goldens)
- [ ] PNGs committed unter `test/goldens/goldens/`
- [ ] Manuelle Screenshots der 7 System-Layouts unter `docs/design/baseline/`
- [ ] CI-Job (kann mit Phase 5 zusammen kommen)
- [ ] Folge-Ticket: Service-Provider + Layout-Goldens für System-Screens
