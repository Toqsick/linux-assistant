import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

/// Semantic role of a badge or status dot.
enum HermesTone { neutral, accent, success, warning, error, info }

/// The three colors a tone resolves to.
@immutable
class HermesToneColors {
  const HermesToneColors({
    required this.fg,
    required this.bg,
    required this.border,
  });

  final Color fg;
  final Color bg;
  final Color border;
}

/// Resolves a tone to its foreground, tinted background and border.
///
/// This is the one place the Hermes tint formula lives: background at ~10%,
/// border at ~28%, solid color as text.
HermesToneColors hermesToneColors(HermesTokens t, HermesTone tone) {
  Color base;
  switch (tone) {
    case HermesTone.neutral:
      return HermesToneColors(
          fg: t.muted, bg: t.surfaceSubtle, border: t.border);
    case HermesTone.accent:
      return HermesToneColors(
          fg: t.accentText, bg: t.accentBg, border: t.accentBgStrong);
    case HermesTone.success:
      base = t.success;
      break;
    case HermesTone.warning:
      base = t.warning;
      break;
    case HermesTone.error:
      base = t.error;
      break;
    case HermesTone.info:
      base = t.info;
      break;
  }
  return HermesToneColors(
    fg: base,
    bg: Color.alphaBlend(base.withValues(alpha: 0.10), t.bg),
    border: Color.alphaBlend(base.withValues(alpha: 0.28), t.bg),
  );
}

/// A pill: tinted background, hairline border, solid semantic text.
class HermesBadge extends StatelessWidget {
  const HermesBadge({
    super.key,
    required this.text,
    this.tone = HermesTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String text;
  final HermesTone tone;
  final IconData? icon;

  /// Tighter padding, for badges sitting inside a table row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final colors = hermesToneColors(t, tone);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 10,
        vertical: dense ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border.all(
            color: colors.border, width: HermesTokens.borderWidth),
        borderRadius: BorderRadius.circular(HermesTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 12, color: colors.fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: colors.fg,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04 * 11,
            ),
          ),
        ],
      ),
    );
  }
}
