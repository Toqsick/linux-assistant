import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

/// The base surface of the hub.
///
/// Hermes expresses elevation with a 1px border and a tint rather than with a
/// drop shadow — its stylesheet sets `box-shadow: none` in 23 places. Keeping
/// that here is what makes a screen full of these read as one system instead of
/// a pile of Material cards.
class HermesCard extends StatelessWidget {
  const HermesCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HermesTokens.space4),
    this.onTap,
    this.spineColor,
    this.background,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// When set, draws the 2px accent spine along the left edge. Used to mark an
  /// active or noteworthy card.
  final Color? spineColor;

  final Color? background;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final radius = BorderRadius.circular(HermesTokens.radiusMd);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        hoverColor: t.hoverBg,
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background ?? t.surface,
        borderRadius: radius,
        // Uniform on purpose: Flutter rejects a rounded border whose sides
        // differ in color, so the accent spine is painted as an overlay below
        // rather than as a thicker left side.
        border: Border.all(color: t.border, width: HermesTokens.borderWidth),
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: content,
          ),
          if (spineColor != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: HermesTokens.spineWidth,
              child: IgnorePointer(
                child: ColoredBox(color: spineColor!),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small uppercase label above a group of cards.
class HermesSectionHeader extends StatelessWidget {
  const HermesSectionHeader({
    super.key,
    required this.text,
    this.trailing,
  });

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: HermesTokens.space3,
        top: HermesTokens.space2,
      ),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: t.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08 * 11,
            ),
          ),
          const SizedBox(width: HermesTokens.space3),
          Expanded(child: Divider(color: t.borderSubtle, height: 1)),
          if (trailing != null) ...[
            const SizedBox(width: HermesTokens.space3),
            trailing!,
          ],
        ],
      ),
    );
  }
}
