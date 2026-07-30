
import 'dart:io';

import 'package:linux_assistant/helpers/command_helper.dart';

class Uptime {
  final String unit;
  final int value;

  const Uptime(this.unit, this.value);
}

abstract class LinuxSystem {
  static Future<bool> hasSwap() async {
    var cmdResult =
        await CommandHelper.run("/usr/bin/free", env: {"LC_ALL": "C"});
    if (!cmdResult.success) {
      throw Exception(cmdResult.error);
    }

    return cmdResult.output.toLowerCase().contains("swap");
  }

  /// Might be inaccurate
  static Future<Uptime> uptime() async {
    var cmdResult =
        await CommandHelper.run("/usr/bin/uptime", env: {"LC_ALL": "C"});

    if (!cmdResult.success) {
      throw Exception(cmdResult.output);
    }

    return parseUptime(cmdResult.output);
  }

  /// Pure parser for `uptime` output, split out so it can be tested without
  /// shelling out.
  static Uptime parseUptime(String output) {
    var values = output.replaceAll(RegExp(r" +"), " ").trim().split(" ");
    if (values[2].contains(":")) {
      var arr = values[2].split(":");
      int hourValue = int.parse(arr[0]);
      int minuteValue = int.parse(arr[1].replaceAll(",", ""));
      return hourValue == 0 ? Uptime("m", minuteValue) : Uptime("h", hourValue);
    } else {
      // The new uptime output could be: 1 day,  1:23
      if (output.contains("min")) {
        return Uptime("m", int.parse(values[2]));
      }
      if (output.contains("day")) {
        return Uptime("d", int.parse(values[2]));
      }
      if (output.contains("hour")) {
        return Uptime("h", int.parse(values[2]));
      }
      return Uptime("m", int.parse(values[2]));
    }
  }

  /// Cached: the CPU thread count cannot change while the app is running, and
  /// the polling dashboard would otherwise fork `nproc` on every tick.
  static int? _cachedThreadCount;

  static Future<int> getCpuThreadCount() async {
    final cached = _cachedThreadCount;
    if (cached != null) {
      return cached;
    }
    var cmdResult = await CommandHelper.run("/usr/bin/nproc");
    if (!cmdResult.success) {
      print("Error: ${cmdResult.error}");
    }
    final count = int.parse(cmdResult.output);
    _cachedThreadCount = count;
    return count;
  }

  /// Returns the average load of the CPU of the last minute
  /// Values are between 0 and 1
  ///
  /// Read straight from procfs rather than through `cat`: this runs on every
  /// poll tick, and forking a process to read a virtual file is the kind of
  /// cost that only shows up as battery drain.
  static Future<double> getCpuAverageLoad() async {
    final double load = parseLoadAvg(await File("/proc/loadavg").readAsString());
    int cpuCount = await getCpuThreadCount();
    return load / cpuCount;
  }

  /// The one-minute figure from the first column of `/proc/loadavg`.
  static double parseLoadAvg(String content) =>
      double.parse(content.trim().split(" ")[0]);
}
