// Theme plumbing tests.
//
// This file previously held the unmodified Flutter counter-app template, which
// asserted on a counter and an add button that this app has never had, and so
// could not pass. It now covers the wiring that the rest of the UI depends on:
// that widgets can reach the design tokens, and that light and dark differ.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/mint_y.dart';

void main() {
  testWidgets("widgets read the tokens through the theme extension",
      (tester) async {
    late HermesTokens seen;

    await tester.pumpWidget(MaterialApp(
      theme: MintY.theme(),
      home: Builder(builder: (context) {
        seen = HermesTokens.of(context);
        return const SizedBox();
      }),
    ));

    expect(seen, HermesTokens.light);
  });

  testWidgets("dark theme delivers the dark tokens", (tester) async {
    late HermesTokens seen;

    await tester.pumpWidget(MaterialApp(
      theme: MintY.themeDark(),
      home: Builder(builder: (context) {
        seen = HermesTokens.of(context);
        return const SizedBox();
      }),
    ));

    expect(seen, HermesTokens.dark);
    expect(seen.bg, isNot(HermesTokens.light.bg));
  });

  testWidgets(
      "falls back to the brightness-matched palette without the extension",
      (tester) async {
    late HermesTokens seen;

    // A bare ThemeData, as used by widget tests that do not build the app.
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Builder(builder: (context) {
        seen = HermesTokens.of(context);
        return const SizedBox();
      }),
    ));

    expect(seen, HermesTokens.dark);
  });

  testWidgets("themeMode switches the palette in place", (tester) async {
    // MaterialApp builds ColoredBoxes of its own, so tag the one under test.
    const probe = Key("palette-probe");

    Widget app(ThemeMode mode) => MaterialApp(
          theme: MintY.theme(),
          darkTheme: MintY.themeDark(),
          themeMode: mode,
          home: Builder(builder: (context) {
            return ColoredBox(
              key: probe,
              color: HermesTokens.of(context).bg,
            );
          }),
        );

    await tester.pumpWidget(app(ThemeMode.light));
    expect(
      tester.widget<ColoredBox>(find.byKey(probe)).color,
      HermesTokens.light.bg,
    );

    await tester.pumpWidget(app(ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ColoredBox>(find.byKey(probe)).color,
      HermesTokens.dark.bg,
    );
  });
}
