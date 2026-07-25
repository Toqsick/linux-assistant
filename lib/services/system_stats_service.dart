import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:linux_assistant/linux/linux_filesystem.dart';
import 'package:linux_assistant/linux/linux_process.dart';
import 'package:linux_assistant/linux/linux_system.dart';
import 'package:linux_assistant/services/linux.dart';

/// Memory figures as reported by `free -m`, in mebibytes.
@immutable
class MemoryInfo {
  final int totalMb;
  final int usedMb;
  final int swapTotalMb;
  final int swapUsedMb;

  const MemoryInfo({
    required this.totalMb,
    required this.usedMb,
    required this.swapTotalMb,
    required this.swapUsedMb,
  });

  double get usedRatio => totalMb > 0 ? usedMb / totalMb : 0;

  bool get hasSwap => swapTotalMb > 0;

  double get swapUsedRatio => swapTotalMb > 0 ? swapUsedMb / swapTotalMb : 0;

  /// Pure parser for `free -m`. Returns null when the output is unusable, so
  /// callers can keep the previous reading instead of showing a broken tile.
  static MemoryInfo? parseFreeOutput(String output) {
    final lines = output.split("\n");
    if (lines.length < 2) {
      return null;
    }

    List<String> columns(String line) =>
        line.split(" ").where((x) => x.isNotEmpty).toList();

    try {
      final mem = columns(lines[1]);
      if (mem.length < 3) {
        return null;
      }
      int swapTotal = 0;
      int swapUsed = 0;
      if (lines.length >= 3) {
        final swap = columns(lines[2]);
        if (swap.length >= 3) {
          swapTotal = int.parse(swap[1]);
          swapUsed = int.parse(swap[2]);
        }
      }
      return MemoryInfo(
        totalMb: int.parse(mem[1]),
        usedMb: int.parse(mem[2]),
        swapTotalMb: swapTotal,
        swapUsedMb: swapUsed,
      );
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }
}

/// One snapshot of the machine's state.
@immutable
class SystemStats {
  /// CPU load over the last minute, normalized by thread count. 0.0 to ~1.0,
  /// but can exceed 1.0 on an overloaded machine.
  final double cpuLoad;
  final MemoryInfo? memory;
  final List<DeviceInfo> disks;
  final int processCount;
  final int zombieCount;
  final List<ProcessStat> topByCpu;
  final List<ProcessStat> topByMemory;
  final Uptime? uptime;

  /// Rolling history for sparklines, oldest first.
  final List<double> cpuHistory;
  final List<double> memoryHistory;

  /// Null until the first successful poll.
  final DateTime? updatedAt;

  /// Set when the last poll threw, so the UI can show stale data honestly
  /// rather than silently freezing.
  final String? error;

  const SystemStats({
    this.cpuLoad = 0,
    this.memory,
    this.disks = const [],
    this.processCount = 0,
    this.zombieCount = 0,
    this.topByCpu = const [],
    this.topByMemory = const [],
    this.uptime,
    this.cpuHistory = const [],
    this.memoryHistory = const [],
    this.updatedAt,
    this.error,
  });

  bool get hasData => updatedAt != null;
}

/// Polls the system once per interval and shares the result with every widget
/// that needs it.
///
/// Each dashboard tile used to own a `Timer.periodic` that called `setState`
/// with an empty body, which re-ran the tile's `Future` and forked `df`, `ps`
/// or `free` again. With eight tiles on screen that is eight process spawns per
/// tick. This service polls once and notifies listeners.
///
/// Polling is reference counted: [acquire] starts it, [release] stops it when
/// the last listener goes away, so a backgrounded hub costs nothing.
class SystemStatsService {
  static final SystemStatsService _instance = SystemStatsService._();

  factory SystemStatsService() => _instance;

  SystemStatsService._();

  static const int historyLength = 60;
  static const Duration defaultInterval = Duration(seconds: 3);

  final ValueNotifier<SystemStats> stats =
      ValueNotifier<SystemStats>(const SystemStats());

  Duration interval = defaultInterval;

  Timer? _timer;
  int _subscribers = 0;

  /// Guards against overlapping polls: on a busy machine `ps` can take longer
  /// than the interval, and stacking runs would make it worse.
  bool _polling = false;

  bool get isRunning => _timer != null;

  @visibleForTesting
  int get subscriberCount => _subscribers;

  /// Registers interest and starts polling if this is the first subscriber.
  void acquire() {
    _subscribers++;
    if (_subscribers == 1) {
      _start();
    }
  }

  /// Drops interest and stops polling once nobody is left.
  void release() {
    if (_subscribers == 0) {
      return;
    }
    _subscribers--;
    if (_subscribers == 0) {
      _stop();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => refresh());
    // Don't make the first tile wait a full interval for content.
    refresh();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Collects a fresh snapshot. Safe to call directly for a manual reload.
  Future<void> refresh() async {
    if (_polling) {
      return;
    }
    _polling = true;
    final previous = stats.value;
    try {
      final results = await Future.wait<Object?>([
        LinuxSystem.getCpuAverageLoad(),
        Linux.runCommand("free -m", hostOnFlatpak: false),
        LinuxFilesystem.disks(),
        LinuxProcess.processCount(),
        LinuxProcess.zombieCount(),
        LinuxProcess.topProcessesByCpu(5),
        LinuxProcess.topProcessesByMemory(5),
        _uptimeOrNull(),
      ]);

      final cpuLoad = results[0] as double;
      final memory = MemoryInfo.parseFreeOutput(results[1] as String);

      stats.value = SystemStats(
        cpuLoad: cpuLoad,
        memory: memory ?? previous.memory,
        disks: results[2] as List<DeviceInfo>,
        processCount: results[3] as int,
        zombieCount: results[4] as int,
        topByCpu: results[5] as List<ProcessStat>,
        topByMemory: results[6] as List<ProcessStat>,
        uptime: results[7] as Uptime? ?? previous.uptime,
        cpuHistory: _appendToHistory(previous.cpuHistory, cpuLoad),
        memoryHistory: _appendToHistory(
          previous.memoryHistory,
          (memory ?? previous.memory)?.usedRatio ?? 0,
        ),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      // Keep the last good snapshot visible and record why it stopped updating.
      stats.value = SystemStats(
        cpuLoad: previous.cpuLoad,
        memory: previous.memory,
        disks: previous.disks,
        processCount: previous.processCount,
        zombieCount: previous.zombieCount,
        topByCpu: previous.topByCpu,
        topByMemory: previous.topByMemory,
        uptime: previous.uptime,
        cpuHistory: previous.cpuHistory,
        memoryHistory: previous.memoryHistory,
        updatedAt: previous.updatedAt,
        error: e.toString(),
      );
    } finally {
      _polling = false;
    }
  }

  /// `uptime` parsing is brittle across distributions, and a single tile is not
  /// worth failing the whole snapshot for.
  Future<Uptime?> _uptimeOrNull() async {
    try {
      return await LinuxSystem.uptime();
    } catch (_) {
      return null;
    }
  }

  static List<double> _appendToHistory(List<double> history, double value) {
    final next = List<double>.from(history)..add(value);
    if (next.length > historyLength) {
      next.removeRange(0, next.length - historyLength);
    }
    return next;
  }

  /// Test seam: drops all state and stops any timer.
  @visibleForTesting
  void resetForTesting({SystemStats? seed}) {
    _stop();
    _subscribers = 0;
    _polling = false;
    stats.value = seed ?? const SystemStats();
  }
}
