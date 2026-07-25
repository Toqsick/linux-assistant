import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

/// A responsive tile grid.
///
/// [MintYGrid] centers fixed-size cards and pads the last row, which suits a
/// launcher's icon wall. Dashboard tiles instead want to stretch to fill the
/// available width, so this computes a column count and lets each cell grow.
class HubGrid extends StatelessWidget {
  const HubGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260,
    this.spacing = HermesTokens.space4,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double available = constraints.maxWidth;
        int columns = (available / minTileWidth).floor();
        columns = columns.clamp(1, 4);

        final double tileWidth =
            (available - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                // Guard against a negative width in very narrow layouts.
                width: tileWidth > 0 ? tileWidth : available,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
