import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Design tokens ported from the Hermes WebUI stylesheet.
///
/// Hermes expresses its whole visual language through CSS custom properties on
/// `:root` (light) and `:root.dark` (dark). This class is the Flutter
/// equivalent: one immutable bundle of colors per brightness, reachable from
/// any widget through `HermesTokens.of(context)`.
///
/// Three rules carry most of the look and are worth keeping in mind when
/// building new widgets against these tokens:
///
///  * Elevation comes from a 1px [border] plus a tint, not from a shadow.
///  * Every tinted chip, badge, active row and secondary button is built from
///    exactly [accentBg] (8%), [accentBgStrong] (15%) and [accentText] (solid).
///  * Metadata is de-emphasized with opacity, not with a different color.
@immutable
class HermesTokens extends ThemeExtension<HermesTokens> {
  // Surfaces.
  final Color bg;
  final Color sidebar;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceSubtleHover;

  // Borders. [border] is the visible hairline, [borderMuted] the quieter one
  // used for the 2px spine on cards.
  final Color border;
  final Color borderMuted;
  final Color borderSubtle;

  // Text. [strong] is for headings, [text] for body, [muted] for metadata.
  final Color text;
  final Color strong;
  final Color muted;

  // Accent triad plus its two tints.
  final Color accent;
  final Color accentHover;
  final Color accentText;
  final Color accentBg;
  final Color accentBgStrong;

  /// Ink to place on top of a solid [accent] fill.
  ///
  /// Gold is a light hue, so white-on-gold fails AA in light mode (3.25:1).
  /// Both brightnesses therefore use a dark ink here rather than the usual
  /// "white text on the brand color".
  final Color onAccent;

  // Semantic colors. These brighten in dark mode rather than staying fixed.
  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  // Interaction.
  final Color hoverBg;
  final Color inputBg;
  final Color focusRing;

  // Code / monospace surfaces.
  final Color codeBg;
  final Color codeText;

  const HermesTokens({
    required this.bg,
    required this.sidebar,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceSubtleHover,
    required this.border,
    required this.borderMuted,
    required this.borderSubtle,
    required this.text,
    required this.strong,
    required this.muted,
    required this.accent,
    required this.accentHover,
    required this.accentText,
    required this.accentBg,
    required this.accentBgStrong,
    required this.onAccent,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.hoverBg,
    required this.inputBg,
    required this.focusRing,
    required this.codeBg,
    required this.codeText,
  });

  /// Hermes default skin, light. Warm gold on cream.
  static const HermesTokens light = HermesTokens(
    bg: Color(0xFFFEFCF7),
    sidebar: Color(0xFFFAF7F0),
    surface: Color(0xFFF3EEE3),
    surfaceSubtle: Color(0xFFF7F4EC),
    surfaceSubtleHover: Color(0xFFEFEADF),
    border: Color(0xFFE0D8C8),
    borderMuted: Color(0xFFD0C6B2),
    borderSubtle: Color(0xFFEAE4D8),
    text: Color(0xFF1A1610),
    strong: Color(0xFF0F0D08),
    muted: Color(0xFF5C5344),
    accent: Color(0xFFB8860B),
    accentHover: Color(0xFF996F08),
    // Hermes ships #8B6508 here, which lands at 4.31:1 on accentBgStrong.
    // Two shades darker clears AA on every surface in this palette.
    accentText: Color(0xFF7F5C08),
    // accent @ 8% and @ 15% pre-composited over [bg]; Flutter has no
    // color-mix(), and pre-blending keeps these usable as opaque fills.
    accentBg: Color(0xFFF8F2E4),
    accentBgStrong: Color(0xFFF1E7CE),
    onAccent: Color(0xFF1A1610),
    error: Color(0xFFC62828),
    // Hermes' light success/warning/info are tuned for large UI chrome and
    // fail AA as body text on cream (4.12 / 2.56 / 4.02). Darkened here so
    // they stay legible as text; the hues are unchanged.
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB45309),
    info: Color(0xFF05748F),
    hoverBg: Color(0x0D000000),
    inputBg: Color(0x08000000),
    focusRing: Color(0x59B8860B),
    codeBg: Color(0xFFF5F0E5),
    codeText: Color(0xFF8B4513),
  );

  /// Hermes default skin, dark. Gold on navy-black.
  static const HermesTokens dark = HermesTokens(
    bg: Color(0xFF0D0D1A),
    sidebar: Color(0xFF141425),
    surface: Color(0xFF1A1A2E),
    surfaceSubtle: Color(0xFF16162A),
    surfaceSubtleHover: Color(0xFF1F1F35),
    border: Color(0xFF2A2A45),
    borderMuted: Color(0xFF3A3A58),
    borderSubtle: Color(0xFF20203A),
    text: Color(0xFFFFF8DC),
    strong: Color(0xFFFFFFFF),
    muted: Color(0xFFC0C0C0),
    accent: Color(0xFFFFD700),
    accentHover: Color(0xFFFFBF00),
    accentText: Color(0xFFFFD700),
    accentBg: Color(0xFF201D18),
    accentBgStrong: Color(0xFF322D1D),
    onAccent: Color(0xFF0D0D1A),
    error: Color(0xFFEF5350),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFA726),
    info: Color(0xFF4DD0E1),
    hoverBg: Color(0x0FFFFFFF),
    inputBg: Color(0x0AFFFFFF),
    focusRing: Color(0x59FFD700),
    codeBg: Color(0xFF1A1A2E),
    codeText: Color(0xFFF0C27F),
  );

  /// Reads the tokens for the current theme.
  ///
  /// Falls back to the palette matching the ambient brightness so that widgets
  /// still render sensibly inside a bare `MaterialApp` (notably in widget
  /// tests, which do not go through `MintY.theme()`).
  static HermesTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<HermesTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  // --- Structural tokens -----------------------------------------------
  // Not part of the lerped state: these never animate.

  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusPill = 999;

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;

  /// Hairline border width. Hermes uses 1px everywhere and almost no shadows.
  static const double borderWidth = 1;

  /// Width of the accent spine on active nav items and tool cards.
  static const double spineWidth = 2;

  /// Opacity steps used to express hierarchy in metadata rows.
  static const double opacityFaint = 0.42;
  static const double opacityMuted = 0.56;
  static const double opacityStrong = 0.75;

  static const String fontMono = 'monospace';

  // --- Contrast helpers -------------------------------------------------

  /// Relative luminance per WCAG 2.2.
  static double relativeLuminance(Color color) {
    // Color.r/g/b are already normalized to 0..1.
    double channel(double c) {
      return c <= 0.03928
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// Contrast ratio between two opaque colors, from 1.0 to 21.0.
  static double contrastRatio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns [color] stepped toward black or white until it reaches [target]
  /// contrast against [background].
  ///
  /// Mid-brightness brand hues — gold, orange, teal — routinely land around
  /// 3:1 as text and need two or three shade steps before they clear AA. This
  /// walks the lightness axis instead of guessing a shade number.
  static Color accessibleOn(
    Color color,
    Color background, {
    double target = 4.5,
  }) {
    if (contrastRatio(color, background) >= target) {
      return color;
    }

    // Decide direction once: on a light background go darker, on a dark one go
    // lighter. Stepping the wrong way can never reach the target.
    final towardBlack = relativeLuminance(background) > 0.18;
    final hsl = HSLColor.fromColor(color);

    for (int step = 1; step <= 20; step++) {
      final factor = step / 20.0;
      final lightness = towardBlack
          ? hsl.lightness * (1 - factor)
          : hsl.lightness + (1 - hsl.lightness) * factor;
      final candidate =
          hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
      if (contrastRatio(candidate, background) >= target) {
        return candidate;
      }
    }

    return towardBlack ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// Rebuilds the accent family around [newAccent], keeping every derived tone
  /// accessible.
  ///
  /// Used when the user opts into distribution-specific colors: only the accent
  /// is swapped, and the tints, accent text and button ink are recomputed so
  /// the palette cannot silently fall below AA.
  HermesTokens withAccent(Color newAccent) {
    Color tint(double alpha) =>
        Color.alphaBlend(newAccent.withValues(alpha: alpha), bg);

    final newAccentBg = tint(0.08);
    final newAccentBgStrong = tint(0.15);

    return copyWith(
      accent: newAccent,
      accentHover: HSLColor.fromColor(newAccent)
          .withLightness(
              (HSLColor.fromColor(newAccent).lightness * 0.85).clamp(0.0, 1.0))
          .toColor(),
      // Must stay readable on the strongest tint, which is the tightest of the
      // three surfaces it appears on.
      accentText: accessibleOn(newAccent, newAccentBgStrong),
      accentBg: newAccentBg,
      accentBgStrong: newAccentBgStrong,
      onAccent: accessibleOn(
        contrastRatio(const Color(0xFFFFFFFF), newAccent) >=
                contrastRatio(text, newAccent)
            ? const Color(0xFFFFFFFF)
            : text,
        newAccent,
      ),
    );
  }

  @override
  HermesTokens copyWith({
    Color? bg,
    Color? sidebar,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceSubtleHover,
    Color? border,
    Color? borderMuted,
    Color? borderSubtle,
    Color? text,
    Color? strong,
    Color? muted,
    Color? accent,
    Color? accentHover,
    Color? accentText,
    Color? accentBg,
    Color? accentBgStrong,
    Color? onAccent,
    Color? error,
    Color? success,
    Color? warning,
    Color? info,
    Color? hoverBg,
    Color? inputBg,
    Color? focusRing,
    Color? codeBg,
    Color? codeText,
  }) {
    return HermesTokens(
      bg: bg ?? this.bg,
      sidebar: sidebar ?? this.sidebar,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceSubtleHover: surfaceSubtleHover ?? this.surfaceSubtleHover,
      border: border ?? this.border,
      borderMuted: borderMuted ?? this.borderMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      text: text ?? this.text,
      strong: strong ?? this.strong,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentText: accentText ?? this.accentText,
      accentBg: accentBg ?? this.accentBg,
      accentBgStrong: accentBgStrong ?? this.accentBgStrong,
      onAccent: onAccent ?? this.onAccent,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      hoverBg: hoverBg ?? this.hoverBg,
      inputBg: inputBg ?? this.inputBg,
      focusRing: focusRing ?? this.focusRing,
      codeBg: codeBg ?? this.codeBg,
      codeText: codeText ?? this.codeText,
    );
  }

  @override
  HermesTokens lerp(covariant ThemeExtension<HermesTokens>? other, double t) {
    if (other is! HermesTokens) {
      return this;
    }
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return HermesTokens(
      bg: c(bg, other.bg),
      sidebar: c(sidebar, other.sidebar),
      surface: c(surface, other.surface),
      surfaceSubtle: c(surfaceSubtle, other.surfaceSubtle),
      surfaceSubtleHover: c(surfaceSubtleHover, other.surfaceSubtleHover),
      border: c(border, other.border),
      borderMuted: c(borderMuted, other.borderMuted),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      text: c(text, other.text),
      strong: c(strong, other.strong),
      muted: c(muted, other.muted),
      accent: c(accent, other.accent),
      accentHover: c(accentHover, other.accentHover),
      accentText: c(accentText, other.accentText),
      accentBg: c(accentBg, other.accentBg),
      accentBgStrong: c(accentBgStrong, other.accentBgStrong),
      onAccent: c(onAccent, other.onAccent),
      error: c(error, other.error),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      info: c(info, other.info),
      hoverBg: c(hoverBg, other.hoverBg),
      inputBg: c(inputBg, other.inputBg),
      focusRing: c(focusRing, other.focusRing),
      codeBg: c(codeBg, other.codeBg),
      codeText: c(codeText, other.codeText),
    );
  }
}
