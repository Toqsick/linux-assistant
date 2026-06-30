
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
    // P2: force LC_ALL=C so uptime output is always in English regardless of system locale
    var cmdResult =
        await CommandHelper.run("/usr/bin/uptime", env: {"LC_ALL": "C"});

    if (!cmdResult.success) {
      // P1: throw the actual error message, not the stdout output
      throw Exception(cmdResult.error);
    }

    var values = cmdResult.output.replaceAll(RegExp(r" +"), " ").split(" ");
    if (values[2].contains(":")) {
      var arr = values[2].split(":");
      int hourValue = int.parse(arr[0]);
      int minuteValue = int.parse(arr[1].replaceAll(",", ""));
      return hourValue == 0 ? Uptime("m", minuteValue) : Uptime("h", hourValue);
    } else {
      // The new uptime output could be: 1 day,  1:23
      if (cmdResult.output.contains("min")) {
        return Uptime("m", int.parse(values[2]));
      }
      if (cmdResult.output.contains("day")) {
        return Uptime("d", int.parse(values[2]));
      }
      if (cmdResult.output.contains("hour")) {
        return Uptime("h", int.parse(values[2]));
      }
      return Uptime("m", int.parse(values[2]));
    }
  }

  static Future<int> getCpuThreadCount() async {
    var cmdResult = await CommandHelper.run("/usr/bin/nproc");
    if (!cmdResult.success) {
      // P1: log error and return safe fallback instead of crashing on int.parse
      print("Error: ${cmdResult.error}");
      return 1;
    }
    // P1: tryParse with fallback to prevent FormatException on unexpected output
    return int.tryParse(cmdResult.output.trim()) ?? 1;
  }

  /// Returns the average load of the CPU of the last minute
  /// Values are between 0 and 1
  static Future<double> getCpuAverageLoad() async {
    var cmdResult =
        await CommandHelper.runWithArguments("/usr/bin/cat", ["/proc/loadavg"]);
    if (!cmdResult.success) {
      print("Error: ${cmdResult.error}");
      return 0.0;
    }
    // P1: tryParse with fallback
    final load = double.tryParse(cmdResult.output.split(" ")[0]) ?? 0.0;
    final cpuCount = await getCpuThreadCount();
    return load / cpuCount;
  }
}
