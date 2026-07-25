import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';
import 'package:linux_assistant/widgets/hermes/hermes_card.dart';

/// A dashboard tile: small label, large value, optional visual and footer.
///
/// The type hierarchy follows the Hermes scale — 11px uppercase metadata,
/// oversized value, 12px supporting rows — so tiles stay scannable at a glance.
class HermesStatTile extends StatelessWidget {
  const HermesStatTile({
    super.key,
    required this.label,
    required this.icon,
    this.value,
    this.unit,
    this.tone = HermesTone.accent,
    this.badge,
    this.visual,
    this.footer,
    this.onTap,
  });

  final String label;
  final IconData icon;

  /// The headline number. Null renders a placeholder dash while loading.
  final String? value;
  final String? unit;
  final HermesTone tone;
  final Widget? badge;

  /// Sparkline, bar or any other compact graphic under the value.
  final Widget? visual;

  /// Rows below the visual, e.g. top processes.
  final Widget? footer;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final colors = hermesToneColors(t, tone);

    return HermesCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.fg),
              const SizedBox(width: HermesTokens.space2),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08 * 11,
                  ),
                ),
              ),
              if (badge != null) badge!,
            ],
          ),
          const SizedBox(height: HermesTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value ?? "—",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.strong,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
              ],
            ],
          ),
          if (visual != null) ...[
            const SizedBox(height: HermesTokens.space3),
            visual!,
          ],
          if (footer != null) ...[
            const SizedBox(height: HermesTokens.space3),
            Divider(color: t.borderSubtle, height: 1),
            const SizedBox(height: HermesTokens.space2),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// A compact `label — value` line for tile footers.
class HermesMetaRow extends StatelessWidget {
  const HermesMetaRow({
    super.key,
    required this.label,
    required this.value,
    this.valueTone,
  });

  final String label;
  final String value;
  final Color? valueTone;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              // Opacity, not a different hue, is how Hermes de-emphasizes.
              style: TextStyle(
                color: t.muted.withValues(alpha: HermesTokens.opacityStrong),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: HermesTokens.space2),
          Text(
            value,
            style: TextStyle(
              color: valueTone ?? t.text,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
