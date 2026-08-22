import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/services/system_monitor_service.dart';

const procStatA = '''
cpu  1000 0 500 8000 200 0 100 0 0 0
cpu0 500 0 250 4000 100 0 50 0 0 0
cpu1 500 0 250 4000 100 0 50 0 0 0
intr 12345 0 0
''';

const procStatB = '''
cpu  1050 0 550 8900 220 0 110 0 0 0
cpu0 525 0 275 4450 110 0 55 0 0 0
cpu1 525 0 275 4450 110 0 55 0 0 0
intr 12399 0 0
''';

const memInfoFixture = '''
MemTotal:       16384000 kB
MemFree:         4096000 kB
MemAvailable:    8192000 kB
Buffers:          512000 kB
SwapTotal:       2097152 kB
SwapFree:        1048576 kB
''';

const netDevFixture = '''
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:    1000      10    0    0    0     0          0         0     1000      10    0    0    0     0       0          0
  eth0: 125000000   1000    0    0    0     0          0         0 50000000    2000    0    0    0     0       0          0
  wlan0:  100000     100    0    0    0     0          0         0    50000      80    0    0    0     0       0          0
''';

const psFixture = '''
    PID %CPU %MEM COMMAND
      1  0.0  0.1 systemd
    423 25.4  3.2 firefox
    900  1.2  0.8 code --unity-launch
''';

void main() {
  group('parseProcStat', () {
    test('reads the aggregate plus one line per core, then stops', () {
      final cpus = SystemMonitorService.parseProcStat(procStatA);
      expect(cpus.map((c) => c.name), ['cpu', 'cpu0', 'cpu1']);
      expect(cpus[0].total, 9800);
      expect(cpus[0].idle, 8200);
      expect(cpus[0].busy, 1600);
    });
  });

  group('cpuUsageDelta', () {
    test('computes the busy percentage between two reads', () {
      final a = SystemMonitorService.parseProcStat(procStatA);
      final b = SystemMonitorService.parseProcStat(procStatB);
      // delta busy 160 of delta total 1080:
      expect(SystemMonitorService.cpuUsageDelta(a[0], b[0]),
          closeTo(14.81, 0.01));
      expect(SystemMonitorService.cpuUsageDelta(a[1], b[1]),
          closeTo(10.68, 0.01));
    });

    test('zero or negative deltas report 0 instead of crashing', () {
      const sample = CpuTimes(name: 'cpu', idle: 100, total: 200);
      expect(SystemMonitorService.cpuUsageDelta(sample, sample), 0);
    });
  });

  group('parseMemInfo', () {
    test('reads totals and derives usage', () {
      final mem = SystemMonitorService.parseMemInfo(memInfoFixture);
      expect(mem.totalKb, 16384000);
      expect(mem.availableKb, 8192000);
      expect(mem.usedRatio, 0.5);
      expect(mem.swapTotalKb, 2097152);
      expect(mem.swapUsedKb, 1048576);
      expect(mem.hasSwap, isTrue);
    });

    test('missing keys fall back to 0', () {
      final mem = SystemMonitorService.parseMemInfo('MemTotal: 1024 kB\n');
      expect(mem.totalKb, 1024);
      expect(mem.hasSwap, isFalse);
    });
  });

  group('parseNetDev', () {
    test('reads rx/tx per interface and skips loopback', () {
      final net = SystemMonitorService.parseNetDev(netDevFixture);
      expect(net.map((i) => i.name), ['eth0', 'wlan0']);
      expect(net[0].rxBytes, 125000000);
      expect(net[0].txBytes, 50000000);
    });
  });

  group('ratePerSecond', () {
    test('divides the delta by the elapsed time', () {
      expect(
        SystemMonitorService.ratePerSecond(
            1000, 3000, const Duration(seconds: 2)),
        1000,
      );
    });

    test('a counter reset reports 0, not a negative rate', () {
      expect(
        SystemMonitorService.ratePerSecond(
            5000, 100, const Duration(seconds: 1)),
        0,
      );
    });

    test('zero elapsed time reports 0', () {
      expect(SystemMonitorService.ratePerSecond(0, 100, Duration.zero), 0);
    });
  });

  group('parseThermal', () {
    test('millidegrees become degrees', () {
      expect(SystemMonitorService.parseThermal('52000\n'), 52.0);
    });

    test('garbage becomes 0', () {
      expect(SystemMonitorService.parseThermal('not-a-number'), 0);
    });
  });

  group('parseNvidiaSmi', () {
    test('strips units from the csv fields', () {
      final gpu = SystemMonitorService.parseNvidiaSmi(
          '34 %, 2105 MiB, 8192 MiB, 61\n');
      expect(gpu, isNotNull);
      expect(gpu!.utilizationPercent, 34);
      expect(gpu.memoryUsedMb, 2105);
      expect(gpu.memoryTotalMb, 8192);
      expect(gpu.temperatureC, 61);
    });

    test('empty output yields null', () {
      expect(SystemMonitorService.parseNvidiaSmi('\n'), isNull);
    });
  });

  group('parsePs', () {
    test('skips the header and parses rows', () {
      final processes = SystemMonitorService.parsePs(psFixture);
      expect(processes, hasLength(3));
      expect(processes[1].pid, 423);
      expect(processes[1].cpuPercent, 25.4);
      expect(processes[1].name, 'firefox');
      // comm with arguments keeps its spaces:
      expect(processes[2].name, 'code --unity-launch');
    });
  });

  group('RingBuffer', () {
    test('evicts the oldest value beyond capacity', () {
      final buffer = RingBuffer(3);
      buffer.add(1);
      buffer.add(2);
      buffer.add(3);
      buffer.add(4);
      expect(buffer.values, [2.0, 3.0, 4.0]);
    });

    test('values is unmodifiable', () {
      final buffer = RingBuffer(2)..add(1);
      expect(() => buffer.values.add(2), throwsUnsupportedError);
    });
  });

  group('buildKillArguments', () {
    test('defaults to SIGTERM, force uses SIGKILL', () {
      expect(SystemMonitorService.buildKillArguments(423), ['-TERM', '423']);
      expect(SystemMonitorService.buildKillArguments(423, force: true),
          ['-KILL', '423']);
    });
  });

  group('formatting', () {
    test('formatRate', () {
      expect(SystemMonitorService.formatRate(500), '500 B/s');
      expect(SystemMonitorService.formatRate(2048), '2.0 K/s');
      expect(SystemMonitorService.formatRate(5242880), '5.0 M/s');
    });

    test('gib formats KiB as GiB', () {
      expect(SystemMonitorService.gib(16384000), '15.6 G');
      expect(SystemMonitorService.gib(1048576), '1.0 G');
    });
  });
}
