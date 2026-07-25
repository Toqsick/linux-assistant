import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/mint_y.dart';

/// The pairs that carry text and therefore have to clear WCAG AA (4.5:1).
///
/// Gold is a light hue, and the shipped Hermes light values for accent text,
/// success, warning and info all land below 4.5 on cream. This locks in the
/// darkened replacements so a future palette edit cannot quietly undo them.
List<List<Object>> _textPairs(HermesTokens t) => [
      ["text on bg", t.text, t.bg],
      ["text on surface", t.text, t.surface],
      ["text on sidebar", t.text, t.sidebar],
      ["text on surfaceSubtle", t.text, t.surfaceSubtle],
      ["strong on bg", t.strong, t.bg],
      ["muted on bg", t.muted, t.bg],
      ["muted on surface", t.muted, t.surface],
      ["accentText on bg", t.accentText, t.bg],
      ["accentText on accentBg", t.accentText, t.accentBg],
      ["accentText on accentBgStrong", t.accentText, t.accentBgStrong],
      ["onAccent on accent", t.onAccent, t.accent],
      ["error on bg", t.error, t.bg],
      ["success on bg", t.success, t.bg],
      ["warning on bg", t.warning, t.bg],
      ["info on bg", t.info, t.bg],
      ["codeText on codeBg", t.codeText, t.codeBg],
    ];

void main() {
  group("contrast", () {
    test("known ratios are computed correctly", () {
      expect(
        HermesTokens.contrastRatio(
            const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.01),
      );
      expect(
        HermesTokens.contrastRatio(
            const Color(0xFF808080), const Color(0xFF808080)),
        closeTo(1.0, 0.001),
      );
    });

    test("light palette text pairs meet WCAG AA", () {
      for (final pair in _textPairs(HermesTokens.light)) {
        final ratio =
            HermesTokens.contrastRatio(pair[1] as Color, pair[2] as Color);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: "light: ${pair[0]} is only "
                "${ratio.toStringAsFixed(2)}:1");
      }
    });

    test("dark palette text pairs meet WCAG AA", () {
      for (final pair in _textPairs(HermesTokens.dark)) {
        final ratio =
            HermesTokens.contrastRatio(pair[1] as Color, pair[2] as Color);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: "dark: ${pair[0]} is only "
                "${ratio.toStringAsFixed(2)}:1");
      }
    });
  });

  group("accessibleOn", () {
    test("leaves an already-compliant color untouched", () {
      const black = Color(0xFF000000);
      expect(
        HermesTokens.accessibleOn(black, const Color(0xFFFFFFFF)),
        black,
      );
    });

    test("darkens a light hue on a light background until it passes", () {
      // Raw gold on cream is about 3.2:1 and needs several steps down.
      const gold = Color(0xFFFFD700);
      const cream = Color(0xFFFEFCF7);
      final fixed = HermesTokens.accessibleOn(gold, cream);

      expect(HermesTokens.contrastRatio(fixed, cream),
          greaterThanOrEqualTo(4.5));
      expect(HermesTokens.relativeLuminance(fixed),
          lessThan(HermesTokens.relativeLuminance(gold)));
    });

    test("lightens a dark hue on a dark background until it passes", () {
      const navy = Color(0xFF1A237E);
      const black = Color(0xFF0D0D1A);
      final fixed = HermesTokens.accessibleOn(navy, black);

      expect(HermesTokens.contrastRatio(fixed, black),
          greaterThanOrEqualTo(4.5));
      expect(HermesTokens.relativeLuminance(fixed),
          greaterThan(HermesTokens.relativeLuminance(navy)));
    });
  });

  group("withAccent", () {
    // Distribution accents the app may substitute for the Hermes gold.
    const distroAccents = <String, Color>{
      "ubuntu": Color(0xFFE95420),
      "fedora": Color(0xFF51A2DA),
      "mint": Color(0xFF35A854),
      "debian": Color(0xFFD0074E),
      "manjaro": Color(0xFF35BFA4),
    };

    test("keeps accent text readable on both tints in light mode", () {
      distroAccents.forEach((name, accent) {
        final t = HermesTokens.light.withAccent(accent);
        expect(HermesTokens.contrastRatio(t.accentText, t.accentBg),
            greaterThanOrEqualTo(4.5),
            reason: "$name accentText on accentBg");
        expect(HermesTokens.contrastRatio(t.accentText, t.accentBgStrong),
            greaterThanOrEqualTo(4.5),
            reason: "$name accentText on accentBgStrong");
      });
    });

    test("keeps button ink readable on the accent fill", () {
      distroAccents.forEach((name, accent) {
        for (final base in [HermesTokens.light, HermesTokens.dark]) {
          final t = base.withAccent(accent);
          expect(HermesTokens.contrastRatio(t.onAccent, t.accent),
              greaterThanOrEqualTo(4.5),
              reason: "$name onAccent on accent");
        }
      });
    });
  });

  group("theme wiring", () {
    test("both themes expose a ColorScheme built from the tokens", () {
      final light = MintY.theme();
      expect(light.colorScheme.primary, HermesTokens.light.accent);
      expect(light.colorScheme.onPrimary, HermesTokens.light.onAccent);
      expect(light.colorScheme.surface, HermesTokens.light.bg);
      expect(light.brightness, Brightness.light);

      final dark = MintY.themeDark();
      expect(dark.colorScheme.primary, HermesTokens.dark.accent);
      expect(dark.colorScheme.surface, HermesTokens.dark.bg);
      expect(dark.brightness, Brightness.dark);
    });

    test("both themes carry the token extension", () {
      expect(MintY.theme().extension<HermesTokens>(), HermesTokens.light);
      expect(MintY.themeDark().extension<HermesTokens>(), HermesTokens.dark);
    });

    test("an accent override reaches the ColorScheme", () {
      const ubuntu = Color(0xFFE95420);
      final theme = MintY.theme(accent: ubuntu);
      expect(theme.colorScheme.primary, ubuntu);
    });

    test("body text styles inherit their color from the theme", () {
      // The styles must not hardcode black, or dark mode renders unreadable.
      expect(MintY.paragraph.color, isNull);
      expect(MintY.heading1.color, isNull);
      expect(MintY.themeDark().textTheme.bodyMedium!.color,
          HermesTokens.dark.text);
      expect(MintY.theme().textTheme.bodyMedium!.color,
          HermesTokens.light.text);
    });

    test("colorfulBackground tracks later color changes", () {
      final original = MintY.currentColor;
      addTearDown(() => MintY.currentColor = original);

      MintY.currentColor = const Color(0xFF123456);
      final gradient =
          MintY.colorfulBackground.gradient as LinearGradient;
      expect(gradient.colors.first, const Color(0xFF123456));
    });
  });
}
