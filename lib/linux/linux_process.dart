import 'package:linux_assistant/services/linux.dart';

class ProcessStat {
  final String metricValue;
  final String processName;

  const ProcessStat(this.metricValue, this.processName);
}

abstract class LinuxProcess {
  static Future<List<ProcessStat>> _getTopProcesses(
      String metric, int count) async {
    var cmdResult = await Linux.runCommandWithCustomArguments(
        "/usr/bin/ps", ["-eo", "$metric,args", "--sort=-$metric"]);

    return parsePsOutput(cmdResult, count);
  }

  /// Pure parser for `ps -eo <metric>,args` output, split out so it can be
  /// tested without shelling out.
  ///
  /// Lines that carry a metric but no command are skipped rather than throwing;
  /// `ps` emits those for kernel threads on some systems.
  static List<ProcessStat> parsePsOutput(String cmdResult, int count) {
    var processes = List<ProcessStat>.empty(growable: true);
    for (var line in cmdResult.split("\n").skip(1).take(count)) {
      var values = line.split(" ");
      values.removeWhere((x) => x == "");
      if (values.length < 2) {
        continue;
      }
      processes.add(ProcessStat(values[0], values[1].split("/").last));
    }

    return processes;
  }

  static Future<int> processCount() async {
    var cmdResult =
        await Linux.runCommandWithCustomArguments("/usr/bin/ps", ["-e"]);

    return cmdResult.split("\n").skip(1).length;
  }

  static Future<List<ProcessStat>> topProcessesByCpu(int count) async =>
      await _getTopProcesses("pcpu", count);

  static Future<List<ProcessStat>> topProcessesByMemory(int count) async =>
      await _getTopProcesses("pmem", count);

  static Future<int> zombieCount() async {
    var cmdResult = await Linux.runCommandWithCustomArguments(
        "/usr/bin/ps", ["-eo", "stat"]);

    return cmdResult.split("\n").where((x) => x.trim() == "Z").length;
  }
}
