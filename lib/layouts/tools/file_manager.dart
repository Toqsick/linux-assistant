import 'dart:io';

import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/services/file_browser_service.dart';

/// Integrated file manager (Admin-Hub E4,
/// Spec: docs/design/feature-spec-admin-hub.md §4).
///
/// Embedded file browser – no external process for navigation. Scope of v1:
/// browse, open (xdg-open), delete (with confirm dialog showing the full
/// path). Copy/move/rename and thumbnails are deliberately out of scope.
class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key, FileBrowserService? service})
      : _service = service;

  /// Injectable for tests; the default talks to the real filesystem.
  final FileBrowserService? _service;

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  late final FileBrowserService _service =
      widget._service ?? FileBrowserService();

  late String _currentPath = Platform.environment['HOME'] ?? '/';
  DirListing? _listing;
  bool _loading = true;
  bool _showHidden = false;

  /// Quick-access entries that exist on this machine, resolved once.
  late final Map<String, String> _quickAccess = _existingQuickAccess();

  @override
  void initState() {
    super.initState();
    _navigate(_currentPath);
  }

  Map<String, String> _existingQuickAccess() {
    final result = <String, String>{};
    for (final entry in FileBrowserService.quickAccessCandidates().entries) {
      if (Directory(entry.value).existsSync()) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Future<void> _navigate(String path) async {
    setState(() => _loading = true);
    final listing = await _service.listDir(path, showHidden: _showHidden);
    if (!mounted) return;
    setState(() {
      // Keep the requested path even on error: the breadcrumb stays
      // navigable and the error state offers the way back up.
      _currentPath = FileBrowserService.normalize(path);
      _listing = listing;
      _loading = false;
    });
  }

  void _toggleHidden() {
    setState(() => _showHidden = !_showHidden);
    _navigate(_currentPath);
  }

  void _onEntryTap(FileEntry entry) {
    if (entry.isSymlink || !entry.isDirectory) {
      // Symlinks are never followed inside the browser (loop danger) – the
      // desktop handler resolves them safely instead.
      _open(entry.path);
    } else {
      _navigate(entry.path);
    }
  }

  Future<void> _open(String path) async {
    final ok = await _service.openPath(path);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Konnte nicht geöffnet werden.')));
    }
  }

  Future<void> _delete(FileEntry entry) async {
    final t = HermesTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.sidebar,
        title: Text(
          entry.isDirectory ? 'Ordner löschen?' : 'Datei löschen?',
          style: TextStyle(color: t.strong),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.isDirectory
                  ? '„${entry.name}" wird inklusive aller Inhalte '
                      'endgültig gelöscht.'
                  : '„${entry.name}" wird endgültig gelöscht.',
              style: TextStyle(color: t.muted),
            ),
            const SizedBox(height: HermesTokens.space2),
            // The full path is part of the confirmation on purpose
            // (destructive action, Spec §4).
            Text(
              entry.path,
              style: TextStyle(
                color: t.muted,
                fontSize: 12,
                fontFamily: HermesTokens.fontMono,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Abbrechen', style: TextStyle(color: t.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen',
                style: TextStyle(color: Color(0xfff44336))), // statusDanger
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await _service.delete(entry, recursive: entry.isDirectory);
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text('Löschen fehlgeschlagen: $error')));
      }
      _navigate(_currentPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final isProtectedPath = FileBrowserService.isProtected(_currentPath);

    return Container(
      color: t.bg,
      child: Column(
        children: [
          _topBar(t),
          if (isProtectedPath) _protectedBanner(t),
          Expanded(child: _body(t, isProtectedPath)),
        ],
      ),
    );
  }

  Widget _topBar(HermesTokens t) {
    return Container(
      decoration: BoxDecoration(
        color: t.sidebar,
        border: Border(
          bottom: BorderSide(color: t.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: HermesTokens.space2),
              children: [
                for (final entry in _quickAccess.entries)
                  _quickAccessChip(t, entry.key, entry.value),
              ],
            ),
          ),
          Divider(color: t.borderSubtle, height: 1),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                IconButton(
                  onPressed: () =>
                      _navigate(FileBrowserService.parentOf(_currentPath)),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: t.muted,
                  tooltip: 'Übergeordneter Ordner',
                ),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _breadcrumb(t),
                  ),
                ),
                IconButton(
                  onPressed: _toggleHidden,
                  icon: Icon(
                    _showHidden ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                  ),
                  color: _showHidden ? t.accent : t.muted,
                  tooltip: 'Versteckte Dateien',
                ),
                IconButton(
                  onPressed: () => _navigate(_currentPath),
                  icon: const Icon(Icons.refresh, size: 16),
                  color: t.muted,
                  tooltip: 'Neu laden',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessChip(HermesTokens t, String label, String path) {
    final active = _currentPath == path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: TextButton(
        onPressed: () => _navigate(path),
        style: TextButton.styleFrom(
          backgroundColor:
              active ? t.accent.withValues(alpha: 0.12) : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: HermesTokens.space2),
          minimumSize: const Size(0, 28),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? t.accent : t.muted,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  List<Widget> _breadcrumb(HermesTokens t) {
    final parts =
        _currentPath.split('/').where((part) => part.isNotEmpty).toList();
    final widgets = <Widget>[
      _crumb(t, '/', '/'),
    ];
    var acc = '';
    for (final part in parts) {
      acc += '/$part';
      widgets.add(Icon(Icons.chevron_right, size: 14, color: t.muted));
      widgets.add(_crumb(t, part, acc));
    }
    return widgets;
  }

  Widget _crumb(HermesTokens t, String label, String path) {
    final active = _currentPath == path;
    return TextButton(
      onPressed: active ? null : () => _navigate(path),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 28),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? t.strong : t.muted,
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _protectedBanner(HermesTokens t) {
    return Container(
      width: double.infinity,
      color: t.warning.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(
        horizontal: HermesTokens.space3,
        vertical: HermesTokens.space2,
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 14, color: t.warning),
          const SizedBox(width: HermesTokens.space2),
          Expanded(
            child: Text(
              'Systempfad – Ansicht nur lesen, Löschen ist hier deaktiviert.',
              style: TextStyle(color: t.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(HermesTokens t, bool protectedPath) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: t.accent),
        ),
      );
    }

    final listing = _listing;
    if (listing == null || listing.hasError) {
      return _errorState(t, listing?.error ?? 'Unbekannter Fehler');
    }
    if (listing.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: t.muted),
            const SizedBox(height: HermesTokens.space2),
            Text('Leerer Ordner', style: TextStyle(color: t.muted)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: listing.entries.length,
      itemBuilder: (context, index) =>
          _row(t, listing.entries[index], protectedPath),
    );
  }

  Widget _errorState(HermesTokens t, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: t.muted),
          const SizedBox(height: HermesTokens.space2),
          Text('Ordner kann nicht gelesen werden',
              style: TextStyle(color: t.strong)),
          const SizedBox(height: HermesTokens.space1),
          Text(message, style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: HermesTokens.space3),
          TextButton(
            onPressed: () =>
                _navigate(FileBrowserService.parentOf(_currentPath)),
            child: Text('Zum übergeordneten Ordner',
                style: TextStyle(color: t.accent)),
          ),
        ],
      ),
    );
  }

  Widget _row(HermesTokens t, FileEntry entry, bool protectedPath) {
    final protectedEntry = FileBrowserService.isProtected(entry.path);
    final deletable = !protectedPath && !protectedEntry;

    final icon = entry.isSymlink
        ? Icons.link
        : entry.isDirectory
            ? Icons.folder_outlined
            : Icons.insert_drive_file_outlined;
    final iconColor = entry.isDirectory && !entry.isSymlink
        ? t.accent
        : t.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onEntryTap(entry),
        hoverColor: t.surfaceSubtleHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HermesTokens.space3,
            vertical: HermesTokens.space2,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: HermesTokens.space3),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: protectedEntry ? t.muted : t.strong,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: entry.isDirectory
                    ? null
                    : Text(
                        FileBrowserService.formatSize(entry.size),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: t.muted, fontSize: 11),
                      ),
              ),
              const SizedBox(width: HermesTokens.space3),
              SizedBox(
                width: 116,
                child: Text(
                  FileBrowserService.formatModified(entry.modified),
                  style: TextStyle(color: t.muted, fontSize: 11),
                ),
              ),
              const SizedBox(width: HermesTokens.space3),
              SizedBox(
                width: 88,
                child: Text(
                  entry.modeString,
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 11,
                    fontFamily: HermesTokens.fontMono,
                  ),
                ),
              ),
              IconButton(
                onPressed: deletable ? () => _delete(entry) : null,
                icon: const Icon(Icons.delete_outline, size: 16),
                color: t.muted,
                disabledColor: t.muted.withValues(alpha: 0.3),
                tooltip: deletable ? 'Löschen' : 'Geschützt',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
