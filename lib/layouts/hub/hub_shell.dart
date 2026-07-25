import 'package:flutter/material.dart';
import 'package:linux_assistant/l10n/app_localizations.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/hub/dashboard_section.dart';
import 'package:linux_assistant/layouts/hub/storage_section.dart';
import 'package:linux_assistant/layouts/linux_health/overview.dart';
import 'package:linux_assistant/layouts/main_screen/main_search.dart';
import 'package:linux_assistant/layouts/security_check/overview.dart';
import 'package:linux_assistant/layouts/settings/settings_start.dart';
import 'package:linux_assistant/main.dart';
import 'package:linux_assistant/services/system_stats_service.dart';
import 'package:linux_assistant/services/theme_controller.dart';
import 'package:linux_assistant/widgets/hermes/hermes_nav_item.dart';

/// The sections reachable from the sidebar.
enum HubSection { dashboard, search, storage, health, security }

/// The persistent frame of the hub: sidebar, top bar and the active section.
///
/// Sections are swapped inside the frame rather than pushed onto the
/// [Navigator]. The app's existing convention is to "go back" by pushing the
/// destination again, which grows the history without bound; keeping section
/// changes out of the navigator avoids adding to that.
class HubShell extends StatefulWidget {
  const HubShell({super.key, this.initialSection = HubSection.dashboard});

  final HubSection initialSection;

  /// Set while a hub is mounted, so the global hotkey can jump straight to the
  /// search section instead of only raising the window.
  static VoidCallback? onSearchRequested;

  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  static const double _sidebarWidth = 260;
  static const double _railWidth = 56;

  /// Below this width the sidebar collapses to an icon rail.
  static const double _collapseBreakpoint = 1000;

  late HubSection _section = widget.initialSection;

  /// Sections are created on first visit and then kept alive. Building them all
  /// up front would start every section's polling and let the search field
  /// steal focus while the dashboard is on screen.
  final Map<HubSection, Widget> _built = {};

  @override
  void initState() {
    super.initState();
    // While the hub is open, dismissing a search result should return here
    // rather than minimizing the window.
    MainSearch.onDismiss = _returnToDashboard;
    HubShell.onSearchRequested = _focusSearch;
  }

  @override
  void dispose() {
    if (MainSearch.onDismiss == _returnToDashboard) {
      MainSearch.onDismiss = null;
    }
    if (HubShell.onSearchRequested == _focusSearch) {
      HubShell.onSearchRequested = null;
    }
    super.dispose();
  }

  void _focusSearch() {
    if (mounted) {
      setState(() => _section = HubSection.search);
    }
  }

  void _returnToDashboard() {
    if (mounted) {
      setState(() => _section = HubSection.dashboard);
    }
  }

  void _select(HubSection section) {
    if (_section != section) {
      setState(() => _section = section);
    }
  }

  String _titleOf(BuildContext context, HubSection section) {
    final l10n = AppLocalizations.of(context)!;
    switch (section) {
      case HubSection.dashboard:
        return l10n.dashboard;
      case HubSection.search:
        return l10n.hubSearch;
      case HubSection.storage:
        return l10n.hubStorage;
      case HubSection.health:
        return l10n.linuxHealth;
      case HubSection.security:
        return l10n.securityCheck;
    }
  }

  IconData _iconOf(HubSection section) {
    switch (section) {
      case HubSection.dashboard:
        return Icons.dashboard_outlined;
      case HubSection.search:
        return Icons.search;
      case HubSection.storage:
        return Icons.storage;
      case HubSection.health:
        return Icons.favorite_outline;
      case HubSection.security:
        return Icons.shield_outlined;
    }
  }

  Widget _buildSection(HubSection section) {
    switch (section) {
      case HubSection.dashboard:
        return DashboardSection(
          onOpenStorage: () => _select(HubSection.storage),
          onOpenSecurity: () => _select(HubSection.security),
        );
      case HubSection.search:
        return MainSearch();
      case HubSection.storage:
        return const StorageSection();
      case HubSection.health:
        return const Padding(
          padding: EdgeInsets.all(HermesTokens.space4),
          child: LinuxHealthContent(),
        );
      case HubSection.security:
        return const SecurityCheckContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool collapsed = constraints.maxWidth < _collapseBreakpoint;

        return Scaffold(
          backgroundColor: t.bg,
          body: Row(
            children: [
              _sidebar(context, t, collapsed),
              Expanded(
                child: Column(
                  children: [
                    _topBar(context, t),
                    Expanded(child: _content()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _content() {
    _built.putIfAbsent(_section, () => _buildSection(_section));
    final visited = _built.keys.toList();

    return IndexedStack(
      index: visited.indexOf(_section),
      children: [
        for (final section in visited)
          // TickerMode stops animations and the search field's timers in
          // sections that are currently off screen.
          TickerMode(
            enabled: section == _section,
            child: _built[section]!,
          ),
      ],
    );
  }

  Widget _sidebar(BuildContext context, HermesTokens t, bool collapsed) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: collapsed ? _railWidth : _sidebarWidth,
      decoration: BoxDecoration(
        color: t.sidebar,
        border: Border(
          right: BorderSide(color: t.border, width: HermesTokens.borderWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brand(context, t, collapsed),
          Divider(color: t.borderSubtle, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: HermesTokens.space2,
                vertical: HermesTokens.space2,
              ),
              children: [
                for (final section in HubSection.values)
                  HermesNavItem(
                    icon: _iconOf(section),
                    label: _titleOf(context, section),
                    selected: _section == section,
                    collapsed: collapsed,
                    onTap: () => _select(section),
                  ),
              ],
            ),
          ),
          Divider(color: t.borderSubtle, height: 1),
          Padding(
            padding: const EdgeInsets.all(HermesTokens.space2),
            child: HermesNavItem(
              icon: Icons.settings_outlined,
              label: l10n.settings,
              selected: false,
              collapsed: collapsed,
              onTap: () => showDialog(
                context: context,
                builder: (context) => const SettingsStart(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand(BuildContext context, HermesTokens t, bool collapsed) {
    final logo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accentHover, t.accent],
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        "LA",
        style: TextStyle(
          color: t.onAccent,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(HermesTokens.space3),
      child: collapsed
          ? Center(child: logo)
          : Row(
              children: [
                logo,
                const SizedBox(width: HermesTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Linux Assistant",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.strong,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (CURRENT_LINUX_ASSISTANT_VERSION.isNotEmpty)
                        Text(
                          "v$CURRENT_LINUX_ASSISTANT_VERSION",
                          style: TextStyle(color: t.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _topBar(BuildContext context, HermesTokens t) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ThemeController();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: HermesTokens.space4),
      decoration: BoxDecoration(
        color: t.sidebar,
        border: Border(
          bottom: BorderSide(color: t.border, width: HermesTokens.borderWidth),
        ),
      ),
      child: Row(
        children: [
          Text(
            _titleOf(context, _section),
            style: TextStyle(
              color: t.strong,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_section != HubSection.search)
            IconButton(
              onPressed: () => _select(HubSection.search),
              icon: const Icon(Icons.search, size: 18),
              color: t.muted,
              tooltip: l10n.hubSearch,
            ),
          IconButton(
            onPressed: () => SystemStatsService().refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            color: t.muted,
            tooltip: l10n.reload,
          ),
          IconButton(
            onPressed: () async {
              await controller.cycleThemeMode();
            },
            icon: Icon(_themeIcon(controller.themeMode), size: 18),
            color: t.muted,
            tooltip: l10n.switchTheme,
          ),
        ],
      ),
    );
  }

  static IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
