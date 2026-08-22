import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:linux_assistant/linux/linux_filesystem.dart';

/// Raw jiffies of one `/proc/stat` cpu line (aggregate or single core).
class CpuTimes {
  const CpuTimes({required this.name, required this.idle, required this.total});

  final String name;

  /// idle + iowait.
  final int idle;

  /// Sum of all time fields.
  final int total;

  int get busy => total - idle;
}

/// `/proc/meminfo`, the fields the monitor displays. Values in KiB.
class MemInfo {
  const MemInfo({
    required this.totalKb,
    required this.availableKb,
    required this.swapTotalKb,
    required this.swapFreeKb,
  });

  final int totalKb;
  final int availableKb;
  final int swapTotalKb;
  final int swapFreeKb;

  int get usedKb => totalKb - availableKb;
  double get usedRatio => totalKb > 0 ? usedKb / totalKb : 0;
  int get swapUsedKb => swapTotalKb - swapFreeKb;
  bool get hasSwap => swapTotalKb > 0;
}

/// Byte counters of one interface from `/proc/net/dev`.
class NetInterfaceSample {
  const NetInterfaceSample({
    required this.name,
    required this.rxBytes,
    required this.txBytes,
  });

  final String name;
  final int rxBytes;
  final int txBytes;
}

/// One thermal zone, e.g. ("x86_pkg_temp", 52.0).
class ThermalReading {
  const ThermalReading({required this.label, required this.celsius});

  final String label;
  final double celsius;
}

/// Optional NVIDIA reading; null on machines without nvidia-smi.
class GpuSample {
  const GpuSample({
    required this.utilizationPercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
    required this.temperatureC,
  });

  final double utilizationPercent;
  final double memoryUsedMb;
  final double memoryTotalMb;
  final double temperatureC;
}

/// One row of the process table.
class ProcessInfo {
  const ProcessInfo({
    required this.pid,
    required this.cpuPercent,
    required this.memPercent,
    required this.name,
  });

  final int pid;
  final double cpuPercent;
  final double memPercent;
  final String name;
}

/// Immutable view of one sampling cycle.
class MonitorSnapshot {
  const MonitorSnapshot({
    this.cpuPercent,
    this.perCore = const [],
    this.cpuHistory = const [],
    this.memory,
    this.memoryHistory = const [],
    this.netRxPerSec = 0,
    this.netTxPerSec = 0,
    this.netHistory = const [],
    this.thermals = const [],
    this.gpu,
    this.disks = const [],
    this.processes = const [],
    this.hasData = false,
  });

  /// Null until the second sample: CPU percentages are deltas between reads.
  final double? cpuPercent;
  final List<double> perCore;
  final List<double> cpuHistory;

  final MemInfo? memory;
  final List<double> memoryHistory;

  final double netRxPerSec;
  final double netTxPerSec;
  final List<double> netHistory;

  final List<ThermalReading> thermals;
  final GpuSample? gpu;
  final List<DeviceInfo> disks;
  final List<ProcessInfo> processes;
  final bool hasData;
}

/// Fixed-length rolling window for the sparklines (oldest first).
class RingBuffer {
  RingBuffer(this.capacity);

  final int capacity;
  final List<double> _values = [];

  List<double> get values => List.unmodifiable(_values);

  void add(double value) {
    _values.add(value);
    if (_values.length > capacity) {
      _values.removeAt(0);
    }
  }
}

typedef FileReader = Future<String> Function(String path);

/// Data source for the system monitor (Admin-Hub E3,
/// Spec: docs/design/feature-spec-admin-hub.md §5).
///
/// All parsing lives in static pure functions so the unit tests can feed
/// fixtures; the service itself only reads files and forks `ps` (and
/// `nvidia-smi`, optionally and only every fifth sample).
///
/// The screen drives the sampling: it calls [sample] once per second from a
/// `Ticker`, which the hub's `TickerMode` stops automatically when the tool
/// is not on screen – so there is no polling cost in the background.
class SystemMonitorService {
  SystemMonitorService({FileReader? readFile})
      : _readFile = readFile ?? ((path) => File(path).readAsString());

  final FileReader _readFile;

  final ValueNotifier<MonitorSnapshot> snapshot =
      ValueNotifier(const MonitorSnapshot());

  final RingBuffer cpuHistory = RingBuffer(60);
  final RingBuffer memoryHistory = RingBuffer(60);
  final RingBuffer netHistory = RingBuffer(60);

  List<CpuTimes>? _previousCpus;
  Map<String, NetInterfaceSample>? _previousNet;
  DateTime? _previousNetTime;
  int _tickCount = 0;
  bool _gpuChecked = false;
  bool _gpuAvailable = false;

  /// Guards against overlapping samples: on a busy machine `ps` can take
  /// longer than the one-second interval.
  bool _sampling = false;

  /// One sampling cycle. Safe to call at any rate; overlapping calls are
  /// dropped.
  Future<void> sample() async {
    if (_sampling) return;
    _sampling = true;
    try {
      final results = await Future.wait([
        _readFile('/proc/stat'),
        _readFile('/proc/meminfo'),
        _readFile('/proc/net/dev'),
      ]);
      final cpus = parseProcStat(results[0]);
      final memory = parseMemInfo(results[1]);
      final net = parseNetDev(results[2]);

      double? cpu;
      var perCore = <double>[];
      final previousCpus = _previousCpus;
      if (previousCpus != null &&
          previousCpus.length == cpus.length &&
          cpus.isNotEmpty) {
        cpu = cpuUsageDelta(previousCpus[0], cpus[0]);
        perCore = [
          for (var i = 1; i < cpus.length; i++)
            cpuUsageDelta(previousCpus[i], cpus[i]),
        ];
      }
      _previousCpus = cpus;

      var rxRate = 0.0;
      var txRate = 0.0;
      final now = DateTime.now();
      final previousNet = _previousNet;
      final previousTime = _previousNetTime;
      if (previousNet != null && previousTime != null) {
        final elapsed = now.difference(previousTime);
        for (final iface in net) {
          final before = previousNet[iface.name];
          if (before == null) continue;
          rxRate += ratePerSecond(before.rxBytes, iface.rxBytes, elapsed);
          txRate += ratePerSecond(before.txBytes, iface.txBytes, elapsed);
        }
      }
      _previousNet = {for (final iface in net) iface.name: iface};
      _previousNetTime = now;

      if (cpu != null) cpuHistory.add(cpu);
      memoryHistory.add(memory.usedRatio * 100);
      netHistory.add(rxRate);

      final processes = await _readProcesses();
      final disks = await _readDisks();
      final thermals = await _readThermals();
      final gpu = await _readGpu();
      _tickCount++;

      snapshot.value = MonitorSnapshot(
        cpuPercent: cpu,
        perCore: perCore,
        cpuHistory: cpuHistory.values,
        memory: memory,
        memoryHistory: memoryHistory.values,
        netRxPerSec: rxRate,
        netTxPerSec: txRate,
        netHistory: netHistory.values,
        thermals: thermals,
        gpu: gpu,
        disks: disks,
        processes: processes,
        hasData: true,
      );
    } catch (_) {
      // Keep the last snapshot: a single failed read must not blank the
      // screen.
    } finally {
      _sampling = false;
    }
  }

  /// SIGTERM by default, SIGKILL with [force]. Returns whether the signal
  /// was delivered.
  Future<bool> terminateProcess(int pid, {bool force = false}) async {
    try {
      final result =
          await Process.run('kill', buildKillArguments(pid, force: force));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<ProcessInfo>> _readProcesses() async {
    try {
      final result = await Process.run(
          'ps', ['-eo', 'pid,pcpu,pmem,comm', '--sort=-pcpu']);
      if (result.exitCode == 0) {
        return parsePs(result.stdout.toString());
      }
    } catch (_) {}
    return const [];
  }

  Future<List<DeviceInfo>> _readDisks() async {
    try {
      return await LinuxFilesystem.disks();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ThermalReading>> _readThermals() async {
    final result = <ThermalReading>[];
    try {
      final dir = Directory('/sys/class/thermal');
      if (!await dir.exists()) return result;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory && entity.path.contains('thermal_zone')) {
          try {
            final celsius = parseThermal(await _readFile('${entity.path}/temp'));
            var label = entity.path.split('/').last;
            try {
              label = (await _readFile('${entity.path}/type')).trim();
            } catch (_) {}
            result.add(ThermalReading(label: label, celsius: celsius));
          } catch (_) {
            // A zone that vanishes or is unreadable is skipped, not fatal.
          }
        }
      }
    } catch (_) {}
    result.sort((a, b) => b.celsius.compareTo(a.celsius));
    return result;
  }

  /// NVIDIA only, probed once via `which`. Read every fifth sample – it is
  /// the one fork-exec on the hot path and does not need 1 Hz resolution.
  Future<GpuSample?> _readGpu() async {
    if (!_gpuChecked) {
      _gpuChecked = true;
      try {
        final which = await Process.run('which', ['nvidia-smi']);
        _gpuAvailable = which.exitCode == 0;
      } catch (_) {
        _gpuAvailable = false;
      }
    }
    if (!_gpuAvailable) return null;
    if (_tickCount % 5 != 0) return snapshot.value.gpu;
    try {
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu',
        '--format=csv,noheader',
      ]);
      if (result.exitCode == 0) {
        return parseNvidiaSmi(result.stdout.toString());
      }
    } catch (_) {}
    return snapshot.value.gpu;
  }

  // ---- Pure parsers and helpers (unit-tested with fixtures) ----

  /// Parses the cpu lines of `/proc/stat`. The first line is the aggregate,
  /// followed by one line per core; parsing stops at the first non-cpu line.
  static List<CpuTimes> parseProcStat(String content) {
    final result = <CpuTimes>[];
    for (final line in content.split('\n')) {
      if (!line.startsWith('cpu')) break;
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 5) continue;
      final values = [for (final p in parts.skip(1)) int.tryParse(p) ?? 0];
      final idle = values[3] + (values.length > 4 ? values[4] : 0);
      final total = values.fold<int>(0, (a, b) => a + b);
      result.add(CpuTimes(name: parts[0], idle: idle, total: total));
    }
    return result;
  }

  /// Busy percentage between two reads of the same cpu line.
  static double cpuUsageDelta(CpuTimes previous, CpuTimes current) {
    final totalDelta = current.total - previous.total;
    if (totalDelta <= 0) return 0;
    final busyDelta = current.busy - previous.busy;
    return (busyDelta / totalDelta * 100).clamp(0.0, 100.0);
  }

  static MemInfo parseMemInfo(String content) {
    int valueOf(String key) {
      for (final line in content.split('\n')) {
        if (line.startsWith(key)) {
          final match = RegExp(r'(\d+)').firstMatch(line.substring(key.length));
          if (match != null) return int.parse(match.group(1)!);
        }
      }
      return 0;
    }

    return MemInfo(
      totalKb: valueOf('MemTotal:'),
      availableKb: valueOf('MemAvailable:'),
      swapTotalKb: valueOf('SwapTotal:'),
      swapFreeKb: valueOf('SwapFree:'),
    );
  }

  /// Parses `/proc/net/dev`. The loopback interface is dropped: its counters
  /// only measure local chatter and drown out the physical interfaces.
  static List<NetInterfaceSample> parseNetDev(String content) {
    final result = <NetInterfaceSample>[];
    for (final line in content.split('\n')) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final name = line.substring(0, colon).trim();
      if (name == 'lo') continue;
      final fields = line.substring(colon + 1).trim().split(RegExp(r'\s+'));
      if (fields.length < 9) continue;
      result.add(NetInterfaceSample(
        name: name,
        rxBytes: int.tryParse(fields[0]) ?? 0,
        txBytes: int.tryParse(fields[8]) ?? 0,
      ));
    }
    return result;
  }

  /// Bytes per second between two counter reads. A negative delta (counter
  /// reset, replugged interface) reports 0 rather than a huge rate.
  static double ratePerSecond(
      int previousBytes, int currentBytes, Duration elapsed) {
    final seconds = elapsed.inMilliseconds / 1000;
    if (seconds <= 0) return 0;
    final delta = currentBytes - previousBytes;
    if (delta < 0) return 0;
    return delta / seconds;
  }

  /// `/sys/class/thermal/thermal_zone*/temp` reports millidegrees Celsius.
  static double parseThermal(String content) {
    final millidegrees = int.tryParse(content.trim()) ?? 0;
    return millidegrees / 1000.0;
  }

  /// Parses one csv line of
  /// `nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader`,
  /// e.g. "34 %, 2105 MiB, 8192 MiB, 61".
  static GpuSample? parseNvidiaSmi(String content) {
    final line = content
        .trim()
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (line.isEmpty) return null;
    final fields = line.split(',');
    if (fields.length < 4) return null;
    double numOf(String field) {
      final match = RegExp(r'[\d.]+').firstMatch(field);
      return match != null ? double.tryParse(match.group(0)!) ?? 0 : 0;
    }

    return GpuSample(
      utilizationPercent: numOf(fields[0]),
      memoryUsedMb: numOf(fields[1]),
      memoryTotalMb: numOf(fields[2]),
      temperatureC: numOf(fields[3]),
    );
  }

  /// Parses `ps -eo pid,pcpu,pmem,comm --sort=-pcpu` output (header line
  /// skipped).
  static List<ProcessInfo> parsePs(String content) {
    final result = <ProcessInfo>[];
    final lines = content.trim().split('\n');
    for (final line in lines.skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 4) continue;
      final pid = int.tryParse(parts[0]);
      if (pid == null) continue;
      result.add(ProcessInfo(
        pid: pid,
        cpuPercent: double.tryParse(parts[1]) ?? 0,
        memPercent: double.tryParse(parts[2]) ?? 0,
        name: parts.sublist(3).join(' '),
      ));
    }
    return result;
  }

  static List<String> buildKillArguments(int pid, {bool force = false}) =>
      [force ? '-KILL' : '-TERM', '$pid'];

  /// 500 → "500 B/s", 2048 → "2.0 K/s", 5242880 → "5.0 M/s".
  static String formatRate(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.round()} B/s';
    const units = ['K/s', 'M/s', 'G/s'];
    var value = bytesPerSecond;
    var unit = -1;
    do {
      value /= 1024;
      unit++;
    } while (value >= 1024 && unit < units.length - 1);
    return '${value.toStringAsFixed(1)} ${units[unit]}';
  }

  /// KiB → "15.6 G", for the RAM badge.
  static String gib(int kib) => '${(kib / 1024 / 1024).toStringAsFixed(1)} G';
}
