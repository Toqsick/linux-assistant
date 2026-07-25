import 'package:flutter/material.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/widgets/hermes/hermes_badge.dart';
import 'package:linux_assistant/widgets/hermes/hermes_card.dart';
import 'package:linux_assistant/widgets/hermes/hermes_copy_command.dart';

/// Priority of a finding, following the P0-P3 ladder.
///
/// P0 is reserved for something actively exploitable; nothing the bundled
/// checker detects reaches that bar on its own, so it exists for completeness
/// rather than being emitted today.
enum FindingSeverity { critical, high, medium, info, ok }

/// One security observation, rendered read-only.
///
/// The app inspects and explains; it does not change anything here. Each
/// finding therefore carries the command to look closer or to act, and the
/// user decides whether to run it.
@immutable
class SecurityFinding {
  const SecurityFinding({
    required this.severity,
    required this.title,
    this.why,
    this.command,
    this.commandCaption,
    this.details = const [],
  });

  final FindingSeverity severity;
  final String title;

  /// Short justification, so a finding is not just a red line.
  final String? why;

  /// A read-only inspection command, or the change the user may choose to make
  /// themselves. Never executed by the app.
  final String? command;
  final String? commandCaption;

  /// Extra lines, e.g. the actual repository entries that were found.
  final List<String> details;
}

/// Renders a [SecurityFinding] as a card.
class SecurityFindingTile extends StatelessWidget {
  const SecurityFindingTile({super.key, required this.finding});

  final SecurityFinding finding;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tone = _toneFor(finding.severity);
    final colors = hermesToneColors(t, tone);

    return Padding(
      padding: const EdgeInsets.only(bottom: HermesTokens.space3),
      child: HermesCard(
        spineColor: finding.severity == FindingSeverity.ok ? null : colors.fg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(finding.severity), size: 16, color: colors.fg),
                const SizedBox(width: HermesTokens.space2),
                Expanded(
                  child: Text(
                    finding.title,
                    style: TextStyle(
                      color: t.text,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: HermesTokens.space2),
                HermesBadge(
                  dense: true,
                  tone: tone,
                  text: _severityLabel(context, finding.severity),
                ),
              ],
            ),
            if (finding.why != null) ...[
              const SizedBox(height: HermesTokens.space2),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Text(
                  "${l10n.whyItMatters}: ${finding.why!}",
                  style: TextStyle(
                    color: t.muted.withValues(alpha: HermesTokens.opacityStrong),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (finding.details.isNotEmpty) ...[
              const SizedBox(height: HermesTokens.space2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(HermesTokens.space2),
                decoration: BoxDecoration(
                  color: t.surfaceSubtle,
                  borderRadius: BorderRadius.circular(HermesTokens.radiusSm),
                  border: Border.all(
                      color: t.borderSubtle, width: HermesTokens.borderWidth),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final detail in finding.details)
                      Text(
                        detail,
                        style: TextStyle(
                          color: t.muted,
                          fontFamily: HermesTokens.fontMono,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (finding.command != null) ...[
              const SizedBox(height: HermesTokens.space3),
              HermesCopyCommand(
                command: finding.command!,
                caption: finding.commandCaption ?? l10n.checkItYourself,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static HermesTone _toneFor(FindingSeverity severity) {
    switch (severity) {
      case FindingSeverity.critical:
      case FindingSeverity.high:
        return HermesTone.error;
      case FindingSeverity.medium:
        return HermesTone.warning;
      case FindingSeverity.info:
        return HermesTone.info;
      case FindingSeverity.ok:
        return HermesTone.success;
    }
  }

  static IconData _iconFor(FindingSeverity severity) {
    switch (severity) {
      case FindingSeverity.critical:
      case FindingSeverity.high:
        return Icons.error_outline;
      case FindingSeverity.medium:
        return Icons.warning_amber;
      case FindingSeverity.info:
        return Icons.info_outline;
      case FindingSeverity.ok:
        return Icons.check_circle_outline;
    }
  }

  static String _severityLabel(BuildContext context, FindingSeverity severity) {
    final l10n = AppLocalizations.of(context)!;
    switch (severity) {
      case FindingSeverity.critical:
        return "P0 ${l10n.severityCritical}";
      case FindingSeverity.high:
        return "P1 ${l10n.severityHigh}";
      case FindingSeverity.medium:
        return "P2 ${l10n.severityMedium}";
      case FindingSeverity.info:
        return "P3 ${l10n.severityInfo}";
      case FindingSeverity.ok:
        return "OK";
    }
  }
}
