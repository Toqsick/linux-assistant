import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';

/// A 7px status dot wrapped in a soft halo.
///
/// Hermes draws this as `box-shadow: 0 0 0 3px <tint>`; here the halo is an
/// outer container, which also keeps the dot's hit area comfortable.
class HermesHaloDot extends StatelessWidget {
  const HermesHaloDot({
    super.key,
    this.tone = HermesTone.accent,
    this.size = 7,
    this.haloWidth = 3,
  });

  final HermesTone tone;
  final double size;
  final double haloWidth;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final colors = hermesToneColors(t, tone);
    final total = size + haloWidth * 2;

    return SizedBox(
      width: total,
      height: total,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.fg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.border,
                spreadRadius: haloWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
