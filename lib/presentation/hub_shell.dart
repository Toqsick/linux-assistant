import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_config.dart';
import 'browser_commander/browser_commander_page.dart';
import 'hub_placeholder.dart';
import 'main_search.dart';
import 'quick_notes/quick_notes.dart';
import 'settings/settings_dialog.dart';

/// Haupt-Navigationsschichten. Klick auf eine Sektion ersetzt den Content,
/// baut keinen Navigator-Stack auf (Step 2).
enum HubSection {
  dashboard,
  ai,
  devices,
  software,
  updates,
  maintenance,
  backup,
  security,
  system,
  notes,
  commands,
  search,
}

/// Werkzeuge in der Sidebar, die NICHT in der Hub-Shell rendert werden,
/// sondern einen externen Prozess starten (Stufe 1: Browser-Launch;
/// Stufe 2: eigener Fenster-Host, s. Docs/Engineering-Playbook §4).
/// Tools mit internem Screen (z. B. Quick Notes) wechseln wie Sektionen
/// den Content-Bereich.
enum HubTool { browser, quickNotes }

class HubShell extends StatefulWidget {
  const HubShell({super.key});

  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  /// Aktiver Eintrag: eine [HubSection] oder ein [HubTool] mit internem Screen.
  Object _active = HubSection.dashboard;

  /// Bereits gebaute Bereiche werden lazy erzeugt und bleiben über IndexedStack
  /// im Baum → Selektionen & Scrollzustände überleben Wechsel. Key: HubSection
  /// oder HubTool.
  final Map<Object, Widget> _built = {};

  int _launchToken = 0;

  @override
  void initState() {
    super.initState();
    AppConfig.instance.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    AppConfig.instance.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() => setState(() {});

  void _selectSection(HubSection section) {
    if (_active == section) return;
    setState(() => _active = section);
  }

  void _selectTool(HubTool tool) {
    if (_active == tool) return;
    setState(() => _active = tool);
  }

  void _onToolTap(HubTool tool) {
    switch (tool) {
      case HubTool.browser:
        _launchBrowser();
      case HubTool.quickNotes:
        _selectTool(HubTool.quickNotes);
    }
  }

  Future<void> _launchBrowser() async {
    final config = AppConfig.instance;
    final messenger = ScaffoldMessenger.of(context);

    if (!config.useBrowserCommander) {
      setState(() => _launchToken++);
      return;
    }
    final uri = Uri.tryParse(config.browserUrl.trim());
    if (uri == null || !uri.hasScheme) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Browser-URL ist leer oder ungültig (Einstellungen).')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Browser konnte nicht gestartet werden.')));
    }
  }

  bool _usesStats(Object entry) {
    if (entry is! HubSection) return false;
    return switch (entry) {
      HubSection.dashboard => true,
      HubSection.ai => AppConfig.instance.showOllamaStats,
      HubSection.devices => AppConfig.instance.showDeviceStats,
      HubSection.software => AppConfig.instance.showSoftwareStats,
      HubSection.updates => AppConfig.instance.showUpdateStats,
      HubSection.maintenance => AppConfig.instance.showMaintenanceStats,
      HubSection.backup => AppConfig.instance.showBackupStats,
      HubSection.security => AppConfig.instance.showSecurityStats,
      HubSection.system => AppConfig.instance.showSystemStats,
      HubSection.notes => AppConfig.instance.showNotesStats,
      HubSection.commands => AppConfig.instance.showCommandStats,
      HubSection.search => false,
    };
  }

  Widget _contentFor(Object entry) {
    if (entry is HubTool) {
      return switch (entry) {
        HubTool.quickNotes => const QuickNotesPage(),
        HubTool.browser => const _Placeholder(),
      };
    }
    final section = entry as HubSection;
    if (section == HubSection.search) {
      return MainSearch(
        key: const ValueKey('main-search'),
        onDismiss: () => _selectSection(HubSection.dashboard),
      );
    }
    return HubPlaceholder(section: section, launchToken: _launchToken);
  }

  String _titleOf(Object entry) {
    if (entry is HubTool) {
      return switch (entry) {
        HubTool.browser => 'Browser',
        HubTool.quickNotes => 'Quick Notes',
      };
    }
    return switch (entry as HubSection) {
      HubSection.dashboard => 'Dashboard',
      HubSection.ai => 'AI Assistent',
      HubSection.devices => 'Geräte',
      HubSection.software => 'Software',
      HubSection.updates => 'Updates',
      HubSection.maintenance => 'Wartung',
      HubSection.backup => 'Backup',
      HubSection.security => 'Sicherheit',
      HubSection.system => 'System',
      HubSection.notes => 'Notizen',
      HubSection.commands => 'Befehle',
      HubSection.search => 'Suche',
    };
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.terminal_rounded,
                size: 18, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Linux Assistant',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    ];

    for (final section in HubSection.values) {
      if (section == HubSection.search) {
        children.add(const _SidebarSectionLabel(label: 'Werkzeuge'));
        for (final tool in HubTool.values) {
          children.add(_SidebarItem(
            icon: switch (tool) {
              HubTool.browser => Icons.language_rounded,
              HubTool.quickNotes => Icons.edit_note_rounded,
            },
            title: switch (tool) {
              HubTool.browser => 'Browser',
              HubTool.quickNotes => 'Quick Notes',
            },
            selected: _active == tool,
            onTap: () => _onToolTap(tool),
          ));
        }
      }
      children.add(_SidebarItem(
        icon: switch (section) {
          HubSection.dashboard => Icons.dashboard_rounded,
          HubSection.ai => Icons.smart_toy_rounded,
          HubSection.devices => Icons.devices_rounded,
          HubSection.software => Icons.apps_rounded,
          HubSection.updates => Icons.system_update_rounded,
          HubSection.maintenance => Icons.build_rounded,
          HubSection.backup => Icons.backup_rounded,
          HubSection.security => Icons.security_rounded,
          HubSection.system => Icons.computer_rounded,
          HubSection.notes => Icons.note_alt_rounded,
          HubSection.commands => Icons.code_rounded,
          HubSection.search => Icons.search_rounded,
        },
        title: _titleOf(section),
        selected: _active == section,
        onTap: () => _selectSection(section),
      ));
    }

    children
      ..add(const Spacer())
      ..add(_SidebarItem(
        icon: Icons.settings_rounded,
        title: 'Einstellungen',
        onTap: () => SettingsDialog.show(context),
      ))
      ..add(const SizedBox(height: 12));

    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: Row(children: [
        Text(_titleOf(_active),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: () => _selectSection(HubSection.search),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('Suche'),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Einstellungen',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => SettingsDialog.show(context),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usesStats = _usesStats(_active);

    final activeContent =
        _built.putIfAbsent(_active, () => _contentFor(_active));
    final visited = _built.keys.toList(growable: false);

    return Scaffold(
      body: Row(children: [
        _buildSidebar(),
        Expanded(
          child: Column(children: [
            _buildTopBar(),
            Expanded(
              child: Row(children: [
                Expanded(
                  child: Container(
                    color: colorScheme.surface,
                    child: IndexedStack(
                      index: visited.indexOf(_active),
                      children: [
                        for (final entry in visited)
                          KeyedSubtree(
                            key: ValueKey(entry),
                            child: _built[entry]!,
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: usesStats ? 256 : 0,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    border: Border(
                      left: BorderSide(
                          color: usesStats
                              ? colorScheme.outlineVariant
                              : Colors.transparent,
                          width: 1),
                    ),
                  ),
                  child: usesStats
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text('Statistiken',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            const _Placeholder(),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  const _SidebarSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
