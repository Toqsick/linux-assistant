import 'package:flutter/material.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/disk_cleaner/cleaner_select_disk.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/linux/linux_filesystem.dart';
import 'package:linux_assistant/services/system_stats_service.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';
import 'package:linux_assistant/widgets/hermes/hermes_card.dart';
import 'package:linux_assistant/widgets/hermes/hermes_stat_tile.dart';

/// Every mounted filesystem with its fill level, plus the way into the disk
/// cleaner.
class StorageSection extends StatefulWidget {
  const StorageSection({super.key});

  @override
  State<StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<StorageSection> {
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
    final l10n = AppLocalizations.of(context)!;
    final t = HermesTokens.of(context);

    return ValueListenableBuilder<SystemStats>(
      valueListenable: _service.stats,
      builder: (context, stats, _) {
        if (!stats.hasData) {
          return Center(
            child: Text(
              l10n.collectingData,
              style: TextStyle(color: t.muted),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(HermesTokens.space4),
          children: [
            HermesSectionHeader(
              text: l10n.mountedDisks,
              trailing: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CleanerSelectDiskPage(),
                  ),
                ),
                icon: const Icon(Icons.cleaning_services, size: 14),
                label: Text(l10n.cleanDiskspace),
              ),
            ),
            for (final disk in stats.disks)
              Padding(
                padding: const EdgeInsets.only(bottom: HermesTokens.space3),
                child: _diskCard(context, disk, t),
              ),
          ],
        );
      },
    );
  }

  Widget _diskCard(BuildContext context, DeviceInfo disk, HermesTokens t) {
    final bool critical = disk.usedPercent > 90;
    final bool warning = !critical && disk.usedPercent > 75;
    final Color color =
        critical ? t.error : (warning ? t.warning : t.accent);

    return HermesCard(
      spineColor: critical ? t.error : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                disk.isRemovable ? Icons.usb : Icons.storage,
                size: 16,
                color: color,
              ),
              const SizedBox(width: HermesTokens.space2),
              Expanded(
                child: Text(
                  disk.mountPoint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.strong,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              HermesBadge(
                dense: true,
                tone: critical
                    ? HermesTone.error
                    : (warning ? HermesTone.warning : HermesTone.neutral),
                text: "${disk.usedPercent}%",
              ),
            ],
          ),
          const SizedBox(height: HermesTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(HermesTokens.radiusPill),
            child: LinearProgressIndicator(
              value: (disk.usedPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: t.surfaceSubtleHover,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: HermesTokens.space2),
          HermesMetaRow(label: disk.filesystem, value: disk.size),
          HermesMetaRow(
            label: AppLocalizations.of(context)!.diskUsage,
            value: "${disk.sizeUsed} / ${disk.size}",
          ),
        ],
      ),
    );
  }
}
