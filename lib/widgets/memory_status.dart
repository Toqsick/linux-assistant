import 'dart:math';

import 'package:flutter/material.dart';
import 'package:linux_assistant/services/system_stats_service.dart';
import 'package:linux_assistant/widgets/hardware_info.dart';
import 'package:linux_assistant/widgets/single_bar_chart.dart';

/// CPU / RAM / Swap bars next to the machine's hardware summary.
///
/// Reads from [SystemStatsService] instead of polling on its own, so having
/// this on screen alongside other tiles no longer multiplies the number of
/// `free` and `ps` calls.
class SystemStatus extends StatefulWidget {
  const SystemStatus({super.key});

  @override
  State<SystemStatus> createState() => _SystemStatusState();
}

class _SystemStatusState extends State<SystemStatus> {
  final SystemStatsService _service = SystemStatsService();

  @override
  void initState() {
    super.initState();
    _service.acquire();
  }

  @override
  void dispose() {
    _service.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SystemStats>(
      valueListenable: _service.stats,
      builder: (context, stats, _) {
        if (!stats.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final double cpuLoad = stats.cpuLoad;
        final List<Widget> widgets = [
          SingleBarChart(
            value: cpuLoad < 0.9 ? cpuLoad + 0.1 : min(cpuLoad, 1),
            fillColor: cpuLoad < 1
                ? const Color.fromARGB(255, 70, 153, 221)
                : Colors.red,
            tooltip: "${(cpuLoad * 100).toStringAsFixed(2)}% (~1 min)",
            text: "CPU",
          ),
          const SizedBox(width: 15),
        ];

        final memory = stats.memory;
        if (memory != null) {
          widgets.add(SingleBarChart(
            value: memory.usedRatio,
            fillColor: const Color.fromARGB(255, 193, 119, 243),
            tooltip:
                "${_formatGb(memory.usedMb)}/${_formatGb(memory.totalMb)}",
            text: "RAM",
          ));
          widgets.add(const SizedBox(width: 15));

          if (memory.hasSwap) {
            widgets.add(SingleBarChart(
              value: memory.swapUsedRatio,
              fillColor: const Color.fromARGB(255, 223, 157, 58),
              tooltip:
                  "${_formatGb(memory.swapUsedMb)}/${_formatGb(memory.swapTotalMb)}",
              text: "Swap",
            ));
            widgets.add(const SizedBox(width: 15));
          }
        }

        widgets.add(const SizedBox(width: 20));
        widgets.add(const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [HardwareInfo()],
        ));

        return Card(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: widgets,
            ),
          ),
        );
      },
    );
  }

  static String _formatGb(int megabytes) =>
      "${(megabytes / 1024).toStringAsFixed(1)}G";
}
