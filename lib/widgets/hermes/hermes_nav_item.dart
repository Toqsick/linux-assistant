import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';

/// A sidebar row.
///
/// Follows the Hermes session-item motif: muted when idle, full text color on
/// hover, and an accent tint plus a 2px spine when active.
class HermesNavItem extends StatefulWidget {
  const HermesNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.collapsed = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional badge, e.g. a pending-update count.
  final Widget? trailing;

  /// Icon-only rail mode for narrow windows.
  final bool collapsed;

  @override
  State<HermesNavItem> createState() => _HermesNavItemState();
}

class _HermesNavItemState extends State<HermesNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final selected = widget.selected;

    final Color foreground = selected
        ? t.accentText
        : _hovered
            ? t.text
            : t.muted;

    final Color background = selected
        ? t.accentBg
        : _hovered
            ? t.surfaceSubtleHover
            : Colors.transparent;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon, size: 18, color: foreground),
        if (!widget.collapsed) ...[
          const SizedBox(width: HermesTokens.space3),
          Expanded(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ],
    );

    return Semantics(
      selected: selected,
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: EdgeInsets.only(
              left: widget.collapsed ? 0 : HermesTokens.space3,
              right: widget.collapsed ? 0 : HermesTokens.space2,
              top: HermesTokens.space2,
              bottom: HermesTokens.space2,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(HermesTokens.radiusMd),
              border: Border(
                left: BorderSide(
                  color: selected ? t.accent : Colors.transparent,
                  width: HermesTokens.spineWidth,
                ),
              ),
            ),
            child: widget.collapsed
                ? Center(child: row)
                : SizedBox(width: double.infinity, child: row),
          ),
        ),
      ),
    );
  }
}
