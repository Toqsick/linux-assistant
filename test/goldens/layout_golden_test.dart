// Golden-Test-Baseline für das Linux Assistant Design System.
//
// Generiert die visuelle Referenz (Phase 1, Schritt 4 des Design-Workflows).
// Ausführen:
//   flutter test test/goldens/layout_golden_test.dart --update-goldens
//
// Danach liegen die PNGs unter test/goldens/goldens/ und dienen als
// Screenshot-Baseline für Visual-Regression (Phase 5).
//
// Hinweise:
// - Fenstergröße 1280x720 entspricht gtk_window_set_default_size.
// - Fonts: Flutter-Tests nutzen sonst die Ahem-Placeholder-Font.
//   golden_toolkit lädt echte Fonts via loadAppFonts().
// - Layouts mit System-Abhängigkeiten (Linux.currentenvironment, Prozesse,
//   Disk-Daten) brauchen Mocks – siehe Abschnitt "Layouts" unten und
//   docs/design/screenshot-baseline.md.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:linux_assistant/layouts/mint_y.dart';
import 'package:linux_assistant/layouts/mint_y_tokens.dart';
import 'package:linux_assistant/widgets/success_message.dart';
import 'package:linux_assistant/widgets/warning_message.dart';
import 'package:linux_assistant/widgets/single_bar_chart.dart';

/// Die drei Referenz-Akzente für die Baseline (Default, Abweichler, Fork-Fokus).
const accentVariants = {
  'mint': MintYAccent.mint,
  'debian': MintYAccent.debian,
  'zorin': MintYAccent.zorin,
};

/// Baut eine Test-App im App-Fensterformat 1280x720 mit ThemeExtension.
Widget buildTestApp({
  required Widget home,
  required MintYAccent accent,
  Brightness brightness = Brightness.dark,
}) {
  final colors = brightness == Brightness.dark
      ? MintYColors.dark(accent)
      : MintYColors.light(accent);
  final base = brightness == Brightness.dark ? MintY.themeDark() : MintY.theme();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: base.copyWith(extensions: [colors]),
    home: home,
  );
}

void main() {
  setUpAll(() async {
    await loadAppFonts(); // golden_toolkit: echte Fonts statt Ahem
  });

  group('Baseline: Core-Komponenten (dark, 3 Akzente)', () {
    for (final entry in accentVariants.entries) {
      testGoldens('MintYButton – ${entry.key}', (tester) async {
        await tester.pumpWidgetBuilder(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MintYButton(
                text: Text('Primär',
                    style: MintY.heading4White),
                color: entry.value.colors.primary,
                onPressed: () {},
              ),
              const SizedBox(height: 8),
              MintYButton(
                text: Text('Deaktiviert', style: MintY.heading4White),
                color: entry.value.colors.primary,
                onPressed: null,
              ),
            ],
          ),
          wrapper: (child) => buildTestApp(home: Scaffold(body: Center(child: child)), accent: entry.value),
          surfaceSize: const Size(400, 200),
        );
        await screenMatchesGolden(tester, 'button.dark.${entry.key}');
      });

      testGoldens('Messages – ${entry.key}', (tester) async {
        await tester.pumpWidgetBuilder(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SuccessMessage(text: 'Firewall ist aktiv.'),
              WarningMessage(text: 'Updates deaktiviert.'),
            ],
          ),
          wrapper: (child) => buildTestApp(home: Scaffold(body: Center(child: child)), accent: entry.value),
          surfaceSize: const Size(500, 200),
        );
        await screenMatchesGolden(tester, 'messages.dark.${entry.key}');
      });

      testGoldens('SingleBarChart – ${entry.key}', (tester) async {
        await tester.pumpWidgetBuilder(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleBarChart(value: 0.4, text: 'CPU', tooltip: '40 %'),
              SizedBox(width: 16),
              SingleBarChart(value: 0.95, text: 'Disk', tooltip: '95 %'),
            ],
          ),
          wrapper: (child) => buildTestApp(home: Scaffold(body: Center(child: child)), accent: entry.value),
          surfaceSize: const Size(400, 250),
        );
        await screenMatchesGolden(tester, 'barchart.dark.${entry.key}');
      });
    }
  });

  group('Baseline: MintYPage-Gerüst (1280x720)', () {
    testGoldens('MintYPage – dark mint', (tester) async {
      await tester.pumpWidgetBuilder(
        MintYPage(
          title: 'Baseline',
          contentElements: const [
            Text('Content-Element 1'),
            SizedBox(height: 16),
            Text('Content-Element 2'),
          ],
          bottom: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MintYButton(
                text: Text('Weiter', style: MintY.heading4White),
                color: MintYAccent.mint.colors.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),
        wrapper: (child) => buildTestApp(home: child, accent: MintYAccent.mint),
        surfaceSize: const Size(1280, 720),
      );
      await screenMatchesGolden(tester, 'page.dark.mint');
    });
  });

  group('Baseline: Light-Theme (Kontrast-Referenz)', () {
    testGoldens('MintYButton – light mint', (tester) async {
      await tester.pumpWidgetBuilder(
        MintYButton(
          text: const Text('Primär'),
          color: MintYAccent.mint.colors.primary,
          onPressed: () {},
        ),
        wrapper: (child) => buildTestApp(
            home: Scaffold(body: Center(child: child)),
            accent: MintYAccent.mint,
            brightness: Brightness.light),
        surfaceSize: const Size(400, 200),
      );
      await screenMatchesGolden(tester, 'button.light.mint');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Layouts mit System-Abhängigkeiten
  //
  // Diese Screens lesen echte Systemdaten (Linux.currentenvironment,
  // Prozesse, Disk-Auslastung). Für reproduzierbare Goldens müssen die
  // Datenquellen gemockt werden. Empfohlenes Vorgehen:
  //
  // 1. Service-Interfaces einführen (z. B. SystemInfoProvider)
  // 2. Im Test: Fake-Implementierung mit festen Werten injizieren
  // 3. Dann hier je Layout ein Golden ergänzen:
  //
  // testGoldens('greeter/introduction – dark mint', ...);
  // testGoldens('main_screen/main_search – dark mint', ...);
  // testGoldens('disk_cleaner/cleaner_select_disk – dark mint', ...);
  // testGoldens('security_check/overview – dark mint', ...);
  // testGoldens('linux_health/overview – dark mint', ...);
  // testGoldens('power_mode – dark mint', ...);
  // testGoldens('settings/settings_start – dark mint', ...);
  //
  // Bis dahin: manuelle Screenshots als Zwischen-Baseline,
  // siehe docs/design/screenshot-baseline.md Abschnitt 3.
  // ─────────────────────────────────────────────────────────────
}
