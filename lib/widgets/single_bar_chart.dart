import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SingleBarChart extends StatelessWidget {
  final double size;
  final double value;
  final Color backgroundColor;
  final Color fillColor;
  final String text;
  final String tooltip;
  final TextStyle textStyle;
  final Widget? customWidgetRightOfBar;

  const SingleBarChart({
    super.key,
    this.value = 0.5,
    this.size = 100,
    this.backgroundColor = const Color.fromARGB(255, 211, 211, 211),
    this.fillColor = const Color.fromARGB(255, 73, 73, 73),
    this.text = "",
    this.textStyle = const TextStyle(),
    this.tooltip = "",
    this.customWidgetRightOfBar,
  });

  @override
  Widget build(BuildContext context) {
    // Resolved per build rather than written back into the widget: the same
    // instance can be rebuilt under a different theme, and a widget that
    // mutates itself keeps the first theme it ever saw.
    Color barBackgroundColor = backgroundColor;
    if (Theme.of(context).brightness == Brightness.dark &&
        backgroundColor == const Color.fromARGB(255, 211, 211, 211)) {
      barBackgroundColor = const Color.fromARGB(255, 87, 87, 87);
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: size,
              child: BarChart(
                BarChartData(
                  maxY: size,
                  minY: 0,
                  alignment: BarChartAlignment.spaceEvenly,
                  barTouchData: BarTouchData(touchTooltipData:
                      BarTouchTooltipData(
                          getTooltipItem: ((group, groupIndex, rod, rodIndex) {
                    if (tooltip == "") {
                      return null;
                    }
                    switch (groupIndex) {
                      case 0:
                        return BarTooltipItem(
                            tooltip,
                            const TextStyle(
                              color: Colors.white,
                            ));
                      default:
                        return null;
                    }
                  }))),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: [generateGroupData(barBackgroundColor)],
                  titlesData: FlTitlesData(show: false),
                ),
              ),
            ),
            if (customWidgetRightOfBar != null) ...[
              const SizedBox(width: 5),
              customWidgetRightOfBar!,
            ],
          ],
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          text,
          style: textStyle,
        ),
      ],
    );
  }

  BarChartGroupData generateGroupData(Color barBackgroundColor) {
    return BarChartGroupData(
      x: 0,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: size,
          color: barBackgroundColor,
          width: 20,
        ),
        BarChartRodData(
          fromY: 2.5,
          toY: value * (size - 5) + 2.5,
          color: fillColor,
          width: 15,
        ),
      ],
    );
  }
}
