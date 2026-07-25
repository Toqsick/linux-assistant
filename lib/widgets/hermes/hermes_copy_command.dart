import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

/// A monospace command line with a copy button.
///
/// This is how the read-only areas of the hub offer remediation: the app shows
/// what to run and hands it over, the user decides whether to run it. Nothing
/// here executes anything.
class HermesCopyCommand extends StatefulWidget {
  const HermesCopyCommand({
    super.key,
    required this.command,
    this.caption,
  });

  final String command;

  /// Optional line above the command explaining what it does.
  final String? caption;

  @override
  State<HermesCopyCommand> createState() => _HermesCopyCommandState();
}

class _HermesCopyCommandState extends State<HermesCopyCommand> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.command));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    // Revert the confirmation after a moment so the button stays reusable.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.caption != null) ...[
          Text(
            widget.caption!,
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          const SizedBox(height: HermesTokens.space1),
        ],
        Container(
          decoration: BoxDecoration(
            color: t.codeBg,
            borderRadius: BorderRadius.circular(HermesTokens.radiusSm),
            border:
                Border.all(color: t.border, width: HermesTokens.borderWidth),
          ),
          padding: const EdgeInsets.only(
            left: HermesTokens.space3,
            top: HermesTokens.space2,
            bottom: HermesTokens.space2,
            right: HermesTokens.space1,
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  widget.command,
                  style: TextStyle(
                    color: t.codeText,
                    fontFamily: HermesTokens.fontMono,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(width: HermesTokens.space2),
              Tooltip(
                message: _copied ? l10n.copied : l10n.copyCommand,
                child: IconButton(
                  onPressed: _copy,
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  splashRadius: 16,
                  color: _copied ? t.success : t.muted,
                  icon: Icon(_copied ? Icons.check : Icons.copy),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
