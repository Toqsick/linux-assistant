# Migration: MintY (statisch) → MintYColors (ThemeExtension)

> Branch: `feature/theme-extension` · Neue Datei: `lib/layouts/mint_y_tokens.dart`
> **Fokus dieser Etappe:** Dashboard (linux_health, memory_status, disk_space)
> und Systemfunktionen/Einstellungen (settings/*). Hermes ist explizit
> ausgenommen (separater Backlog-Branch).

---

## Warum?

| Alt (`mint_y.dart`) | Neu (`mint_y_tokens.dart`) |
|---|---|
| `MintY.currentColor` – global, mutable, kein Rebuild bei Wechsel | `Theme.of(context).extension<MintYColors>()` – reaktiv, testbar |
| String-Keys: `getColorByName("Green")` | Enum: `MintYAccent.mint` (Compile-Zeit-Sicherheit) |
| Light-Theme ohne canvas/card-Tokens | Symmetrische `MintYColors.light()` / `.dark()` |
| Magic Numbers (89 %, 100 %) | `MintYThresholds.diskUsageWarningPercent` etc. |
| `#9D9D9D` Text-Dim (< WCAG AA auf #2D2D2D) | `#B5B5B5` im Dark-Set (Kontrast-Fix eingebaut) |
| `Courier` hart | Font-Fallback-Stack in `MintYText.mono` |

---

## Schritt-für-Schritt

### 1. Theme registrieren (main.dart)

```dart
MintYAccent accent = switch (Linux.currentenvironment.distribution) {
  DISTROS.DEBIAN => MintYAccent.debian,
  DISTROS.LMDE => MintYAccent.lmde,
  DISTROS.OPENSUSE => MintYAccent.opensuse,
  DISTROS.KDENEON => MintYAccent.kdeNeon,
  DISTROS.ZORIN => MintYAccent.zorin,
  DISTROS.UBUNTU => MintYAccent.ubuntu,
  _ => MintYAccent.mint,
};

MaterialApp(
  theme: MintY.theme().copyWith(extensions: [MintYColors.light(accent)]),
  darkTheme: MintY.themeDark().copyWith(extensions: [MintYColors.dark(accent)]),
);
```

Damit funktioniert Akzentwechsel über `Theme.of` sofort –
`setMainColor()` kann nach vollständiger Migration entfernt werden.

### 2. Komfort-Helper (optional, empfiehlt sich)

```dart
extension MintYContext on BuildContext {
  MintYColors get mintY => Theme.of(this).extension<MintYColors>()!;
}
// Nutzung: context.mintY.accent
```

### 3. Dashboard migrieren (Priorität 1)

**`lib/widgets/memory_status.dart`**
```dart
// vorher
fillColor: cpuLoad < 1 ? const Color.fromARGB(255, 70, 153, 221) : Colors.red,
// nachher
final colors = context.mintY;
fillColor: cpuLoad < MintYThresholds.cpuLoadCritical
    ? colors.chartCpu
    : colors.statusDanger,
```

**`lib/widgets/disk_space.dart`**
```dart
// vorher
device.usedPercent > 89 ? Colors.red : const Color.fromARGB(255, 141, 141, 141)
// nachher
device.usedPercent > MintYThresholds.diskUsageWarningPercent
    ? context.mintY.statusDanger
    : context.mintY.chartDisk
```

**`lib/widgets/single_bar_chart.dart`** – Default-Werte `backgroundColor` /
`fillColor` nicht mehr als `const` hartcodieren, sondern im `build` aus
`context.mintY.chartTrack` beziehen (Defaults bleiben als Parameter-Override).

### 4. Systemfunktionen & Einstellungen migrieren (Priorität 2)

- `lib/layouts/settings/settings_start.dart` – Hero-Icon (64px):
  `color: MintY.currentColor` → `color: context.mintY.accent`
- `lib/layouts/settings/environment_selection.dart` – hier den
  **Akzent-Override** anbinden: Auswahl eines `MintYAccent` → Theme neu
  aufbauen (kein Neustart mehr nötig). Das ist der UX-Kern dieser Etappe.
- `lib/layouts/settings/settings_widgets.dart` – `MintYButton(color: ...)`
  Aufrufe auf `context.mintY.accent` umstellen.
- `lib/layouts/run_command_queue.dart` – Terminal-Text: `TextStyle(color:
  Colors.white, fontFamily: "Courier")` → `MintYText.mono.copyWith(color:
  context.mintY.textPrimary)`.

### 5. Übergangsstrategie (wichtig!)

`MintY` bleibt während der Migration bestehen – als **Delegator**, nicht als
Duplikat:

```dart
// mint_y.dart (Übergang)
@Deprecated('Use Theme.of(context).extension<MintYColors>() instead')
static Color get currentColor => _legacyAccent;
```

Reihenfolge pro PR klein halten:
1. PR A: `mint_y_tokens.dart` + Theme-Registrierung (kein Screen-Umbau)
2. PR B: Dashboard-Widgets (memory_status, disk_space, single_bar_chart)
3. PR C: Settings & Systemfunktionen
4. PR D: Restliche Layouts + `MintY.currentColor` entfernen

### 6. Tests

```dart
testWidgets('Dashboard nutzt ThemeExtension-Akzent', (tester) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(extensions: [MintYColors.dark(MintYAccent.zorin)]),
    home: const MemoryStatus(),
  ));
  final colors = tester
      .widget<MaterialApp>(find.byType(MaterialApp))
      .theme!.extension<MintYColors>()!;
  expect(colors.accent, const Color(0xff15a6cf));
});
```

Golden Tests: je ein Golden für `MintYAccent.mint`, `.debian`, `.zorin`
im Dark-Theme reicht als Baseline.

---

## Explizit NICHT in dieser Etappe

- ❌ Hermes-Widgets (hermes_tokens.dart, lib/widgets/hermes/*) → Backlog-Branch
- ❌ Motion-Spec, Glassmorphism-Preset
- ❌ Spacing-Raster-Umstellung (10 → 8/12) – separate Diskussion

## Abhakliste

- [ ] `mint_y_tokens.dart` gemerged (PR A)
- [ ] Theme-Registrierung in main.dart (PR A)
- [ ] Dashboard-Widgets migriert (PR B)
- [ ] Settings inkl. Live-Akzentwechsel (PR C)
- [ ] Golden Tests Baseline (PR C)
- [ ] Deprecated `MintY.currentColor` entfernt (PR D)
