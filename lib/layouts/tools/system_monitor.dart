import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/hub/hub_grid.dart';
import 'package:linux_assistant/linux/linux_filesystem.dart';
import 'package:linux_assistant/services/system_monitor_service.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';
import 'package:linux_assistant/widgets/hermes/hermes_card.dart';
import 'package:linux_assistant/widgets/hermes/hermes_halo_dot.dart';
import 'package:linux_assistant/widgets/hermes/hermes_sparkline.dart';
import 'package:linux_assistant/widgets/hermes/hermes_stat_tile.dart';

/// System monitor (Admin-Hub E3, Spec: docs/design/feature-spec-admin-hub.md §5).
///
/// The detailed sibling of the dashboard tiles: 1-second refresh, pausable,
/// per-core CPU, network rates, thermals, optional NVIDIA GPU and a sortable
/// process table with a terminate action.
///
/// Sampling is driven by a [Ticker], not a `Timer`: the hub wraps inactive
/// screens in `TickerMode`, so polling stops for free when the tool is not
/// on screen (Performance-Budget der Spec).
class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key, SystemMonitorService? service})
      : _service = service;

  /// Injectable for tests; the default reads the real /proc filesystem.
  final SystemMonitorService? _service;

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage>
    with TickerProviderStateMixin {
  late final SystemMonitorService _service =
      widget._service ?? SystemMonitorService();

  late final Ticker _ticker;
  Duration _lastSample = Duration.zero;
  bool _paused = false;

  String _processFilter = '';
  int _sortColumn = 1; // CPU% by default
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _service.sample(); // don't make the first frame wait a full second
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastSample >= const Duration(seconds: 1)) {
      _lastSample = elapsed;
      _service.sample();
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _ticker.stop();
    } else {
      _lastSample = Duration.zero;
      _ticker.start();
    }
  }

  Future<void> _terminate(ProcessInfo process) async {
    final t = HermesTokens.of(context);
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.sidebar,
        title: Text('Prozess beenden?', style: TextStyle(color: t.strong)),
        content: Text(
          '„${process.name}" (PID ${process.pid}) erhält zuerst die Chance, '
          'sich sauber zu beenden (SIGTERM). Erzwingen sendet SIGKILL und '
          'kann Datenverlust verursachen.',
          style: TextStyle(color: t.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen', style: TextStyle(color: t.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('term'),
            child: Text('Beenden', style: TextStyle(color: t.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('kill'),
            child: const Text('Erzwingen',
                style: TextStyle(color: Color(0xfff44336))), // statusDanger
          ),
        ],
      ),
    );
    if (action == null) return;

    final ok = await _service.terminateProcess(process.pid,
        force: action == 'kill');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok
            ? 'Signal an ${process.name} gesendet.'
            : 'Konnte ${process.name} nicht beenden.'),
      ));
    _service.sample(); // refresh the table immediately
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);

    return Container(
      color: t.bg,
      child: Column(
        children: [
          _controlBar(t),
          Expanded(
            child: ValueListenableBuilder<MonitorSnapshot>(
              valueListenable: _service.snapshot,
              builder: (context, snapshot, _) {
                return ListView(
                  padding: const EdgeInsets.all(HermesTokens.space4),
                  children: [
                    HubGrid(
                      minTileWidth: 240,
                      children: [
                        _cpuTile(t, snapshot),
                        _memoryTile(t, snapshot),
                        if (snapshot.gpu != null) _gpuTile(t, snapshot.gpu!),
                        _diskTile(t, snapshot),
                        _networkTile(t, snapshot),
                        _thermalTile(t, snapshot),
                      ],
                    ),
                    const SizedBox(height: HermesTokens.space4),
                    HermesSectionHeader(text: 'Prozesse'),
                    _processControls(t),
                    const SizedBox(height: HermesTokens.space2),
                    _processTable(t, snapshot),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBar(HermesTokens t) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: HermesTokens.space3),
      decoration: BoxDecoration(
        color: t.sidebar,
        border: Border(
          bottom: BorderSide(color: t.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          HermesHaloDot(
              tone: _paused ? HermesTone.neutral : HermesTone.accent),
          const SizedBox(width: HermesTokens.space2),
          Text(
            _paused ? 'Pausiert' : 'Live · 1 s',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            onPressed: _togglePause,
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18),
            color: t.muted,
            tooltip: _paused ? 'Fortsetzen' : 'Pausieren',
          ),
          IconButton(
            onPressed: () => _service.sample(),
            icon: const Icon(Icons.refresh, size: 18),
            color: t.muted,
            tooltip: 'Jetzt aktualisieren',
          ),
        ],
      ),
    );
  }

  Widget _cpuTile(HermesTokens t, MonitorSnapshot snapshot) {
    final percent = snapshot.cpuPercent;
    return HermesStatTile(
      label: 'CPU',
      icon: Icons.speed,
      value: percent != null ? percent.toStringAsFixed(0) : null,
      unit: '%',
      tone: (percent ?? 0) >= 90 ? HermesTone.error : HermesTone.accent,
      badge: snapshot.perCore.isNotEmpty
          ? HermesBadge(dense: true, text: '${snapshot.perCore.length} Cores')
          : null,
      visual: HermesSparkline(
        values: snapshot.cpuHistory,
        color: (percent ?? 0) >= 90 ? t.error : t.accent,
        maxValue: 100,
      ),
      footer: snapshot.perCore.isEmpty
          ? null
          : Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final core in snapshot.perCore) _coreBar(t, core),
              ],
            ),
    );
  }

  Widget _coreBar(HermesTokens t, double percent) {
    return SizedBox(
      width: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HermesTokens.radiusPill),
        child: LinearProgressIndicator(
          value: (percent / 100).clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: t.surfaceSubtleHover,
          valueColor: AlwaysStoppedAnimation<Color>(
              percent >= 90 ? t.error : t.accent),
        ),
      ),
    );
  }

  Widget _memoryTile(HermesTokens t, MonitorSnapshot snapshot) {
    final memory = snapshot.memory;
    final ratio = memory?.usedRatio ?? 0;
    return HermesStatTile(
      label: 'RAM',
      icon: Icons.developer_board,
      value: memory != null ? (ratio * 100).toStringAsFixed(0) : null,
      unit: '%',
      tone: ratio >= 0.9 ? HermesTone.warning : HermesTone.accent,
      badge: memory != null
          ? HermesBadge(
              dense: true,
              text:
                  '${SystemMonitorService.gib(memory.usedKb)} / ${SystemMonitorService.gib(memory.totalKb)}',
            )
          : null,
      visual: HermesSparkline(
        values: snapshot.memoryHistory,
        color: ratio >= 0.9 ? t.warning : t.accent,
        maxValue: 100,
      ),
      footer: memory != null && memory.hasSwap
          ? HermesMetaRow(
              label: 'Swap',
              value:
                  '${SystemMonitorService.gib(memory.swapUsedKb)} / ${SystemMonitorService.gib(memory.swapTotalKb)}',
            )
          : null,
    );
  }

  Widget _gpuTile(HermesTokens t, GpuSample gpu) {
    return HermesStatTile(
      label: 'GPU',
      icon: Icons.videogame_asset,
      value: gpu.utilizationPercent.toStringAsFixed(0),
      unit: '%',
      badge: HermesBadge(
        dense: true,
        text: '${gpu.temperatureC.toStringAsFixed(0)} °C',
      ),
      footer: HermesMetaRow(
        label: 'VRAM',
        value:
            '${(gpu.memoryUsedMb / 1024).toStringAsFixed(1)} / ${(gpu.memoryTotalMb / 1024).toStringAsFixed(0)} G',
      ),
    );
  }

  Widget _diskTile(HermesTokens t, MonitorSnapshot snapshot) {
    final DeviceInfo? worst = snapshot.disks.isEmpty
        ? null
        : snapshot.disks
            .reduce((a, b) => a.usedPercent >= b.usedPercent ? a : b);
    final critical = (worst?.usedPercent ?? 0) > 90;

    return HermesStatTile(
      label: 'Disks',
      icon: Icons.storage,
      value: worst != null ? '${worst.usedPercent}' : null,
      unit: '%',
      tone: critical ? HermesTone.error : HermesTone.accent,
      badge: worst != null ? HermesBadge(dense: true, text: worst.mountPoint) : null,
      visual: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final disk in snapshot.disks.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _diskBar(t, disk),
            ),
        ],
      ),
    );
  }

  Widget _diskBar(HermesTokens t, DeviceInfo disk) {
    final ratio = (disk.usedPercent / 100).clamp(0.0, 1.0);
    final color = disk.usedPercent > 90 ? t.error : t.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                disk.mountPoint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.muted, fontSize: 11),
              ),
            ),
            Text('${disk.sizeFree} free',
                style: TextStyle(color: t.muted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(HermesTokens.radiusPill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: t.surfaceSubtleHover,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _networkTile(HermesTokens t, MonitorSnapshot snapshot) {
    final maxRate = snapshot.netHistory.fold<double>(
        1024, (a, b) => b > a ? b : a); // sparkline floor: 1 K/s
    return HermesStatTile(
      label: 'Netzwerk',
      icon: Icons.network_check,
      value: SystemMonitorService.formatRate(snapshot.netRxPerSec),
      tone: HermesTone.accent,
      badge: HermesBadge(
        dense: true,
        icon: Icons.arrow_upward,
        text: SystemMonitorService.formatRate(snapshot.netTxPerSec),
      ),
      visual: HermesSparkline(
        values: snapshot.netHistory,
        color: t.accent,
        maxValue: maxRate,
      ),
    );
  }

  Widget _thermalTile(HermesTokens t, MonitorSnapshot snapshot) {
    final hottest =
        snapshot.thermals.isEmpty ? null : snapshot.thermals.first;
    return HermesStatTile(
      label: 'Thermal',
      icon: Icons.thermostat,
      value: hottest != null ? hottest.celsius.toStringAsFixed(0) : null,
      unit: '°C',
      tone: (hottest?.celsius ?? 0) >= 80 ? HermesTone.warning : HermesTone.accent,
      footer: snapshot.thermals.length <= 1
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final zone in snapshot.thermals.skip(1).take(3))
                  HermesMetaRow(
                    label: zone.label,
                    value: '${zone.celsius.toStringAsFixed(0)} °C',
                  ),
              ],
            ),
    );
  }

  Widget _processControls(HermesTokens t) {
    return TextField(
      onChanged: (value) => setState(() => _processFilter = value),
      style: TextStyle(color: t.strong, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Prozess suchen …',
        hintStyle: TextStyle(color: t.muted, fontSize: 13),
        prefixIcon: Icon(Icons.search, size: 16, color: t.muted),
        filled: true,
        fillColor: t.sidebar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
          borderSide: BorderSide(color: t.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
          borderSide: BorderSide(color: t.borderSubtle),
        ),
      ),
    );
  }

  Widget _processTable(HermesTokens t, MonitorSnapshot snapshot) {
    final filter = _processFilter.toLowerCase();
    final processes = snapshot.processes
        .where((p) => filter.isEmpty || p.name.toLowerCase().contains(filter))
        .toList();
    int compare(ProcessInfo a, ProcessInfo b) {
      switch (_sortColumn) {
        case 0:
          return a.pid.compareTo(b.pid);
        case 1:
          return a.cpuPercent.compareTo(b.cpuPercent);
        case 2:
          return a.memPercent.compareTo(b.memPercent);
        default:
          return a.name.compareTo(b.name);
      }
    }

    processes.sort((a, b) => _sortAsc ? compare(a, b) : compare(b, a));
    final visible = processes.take(100).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: HermesTokens.space2, vertical: HermesTokens.space1),
          child: Row(
            children: [
              SizedBox(width: 64, child: _sortHeader(t, 'PID', 0)),
              SizedBox(width: 64, child: _sortHeader(t, 'CPU %', 1)),
              SizedBox(width: 64, child: _sortHeader(t, 'RAM %', 2)),
              Expanded(child: _sortHeader(t, 'Name', 3, numeric: false)),
              const SizedBox(width: 32),
            ],
          ),
        ),
        Divider(color: t.borderSubtle, height: 1),
        for (final process in visible) _processRow(t, process),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(HermesTokens.space3),
            child: Text('Keine Prozesse gefunden',
                style: TextStyle(color: t.muted, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _sortHeader(HermesTokens t, String label, int column,
      {bool numeric = true}) {
    final active = _sortColumn == column;
    return InkWell(
      onTap: () => setState(() {
        if (active) {
          _sortAsc = !_sortAsc;
        } else {
          _sortColumn = column;
          _sortAsc = !numeric; // numbers default to descending
        }
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? t.accent : t.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (active)
            Icon(
              _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: t.accent,
            ),
        ],
      ),
    );
  }

  Widget _processRow(HermesTokens t, ProcessInfo process) {
    const numbers = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: HermesTokens.space2, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text('${process.pid}',
                style: numbers.copyWith(color: t.muted, fontSize: 12)),
          ),
          SizedBox(
            width: 64,
            child: Text(
              process.cpuPercent.toStringAsFixed(1),
              style: numbers.copyWith(
                color: process.cpuPercent >= 50 ? t.warning : t.strong,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(process.memPercent.toStringAsFixed(1),
                style: numbers.copyWith(color: t.strong, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              process.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.strong, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              onPressed: () => _terminate(process),
              icon: const Icon(Icons.close, size: 14),
              color: t.muted,
              tooltip: 'Prozess beenden',
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
