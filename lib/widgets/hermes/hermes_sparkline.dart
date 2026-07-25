import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

/// A minimal line chart for a rolling series.
///
/// Deliberately a [CustomPainter] rather than an fl_chart widget: this draws at
/// most 60 points with no axes, legend, tooltip or hit testing, and a chart
/// library brings a lot of machinery that would go unused on every tile.
class HermesSparkline extends StatelessWidget {
  const HermesSparkline({
    super.key,
    required this.values,
    this.color,
    this.height = 36,
    this.maxValue = 1.0,
  });

  /// Oldest first. Fewer than two points renders as empty space.
  final List<double> values;
  final Color? color;
  final double height;

  /// Upper bound of the value axis; values above it are clamped.
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color ?? t.accent,
          maxValue: maxValue,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.maxValue,
  });

  final List<double> values;
  final Color color;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final dx = size.width / (values.length - 1);

    double yFor(double value) {
      final normalized = (value / safeMax).clamp(0.0, 1.0);
      // Inset by the stroke width so the extremes are not clipped.
      return size.height - 1 - normalized * (size.height - 2);
    }

    final path = Path()..moveTo(0, yFor(values.first));
    for (int i = 1; i < values.length; i++) {
      path.lineTo(dx * i, yFor(values[i]));
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue ||
        !identical(oldDelegate.values, values);
  }
}
