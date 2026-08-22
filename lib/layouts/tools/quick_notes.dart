import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linux_assistant/layouts/hermes_tokens.dart';
import 'package:linux_assistant/layouts/mint_y_tokens.dart';
import 'package:linux_assistant/services/notes_service.dart';

/// Quick Notes (Admin-Hub E2): Master-Detail-Notizblock.
///
/// Links die Notizliste (zuletzt geändert zuerst), rechts der Editor.
/// Autosave ist debounced (500 ms) – es gibt bewusst keinen Speichern-Button.
/// Löschen ist eine destructive action und braucht den Confirm-Dialog.
class QuickNotesPage extends StatefulWidget {
  const QuickNotesPage({super.key, NotesService? service})
      : _service = service;

  /// Injizierbar für Tests; Default: echter XDG-Speicherort.
  final NotesService? _service;

  @override
  State<QuickNotesPage> createState() => _QuickNotesPageState();
}

class _QuickNotesPageState extends State<QuickNotesPage> {
  late final NotesService _service = widget._service ?? NotesService();
  final TextEditingController _editor = TextEditingController();
  Timer? _saveDebounce;

  List<Note> _notes = [];
  Note? _selected;
  bool _loading = true;

  /// Während des Ladens/Wechselns einer Notiz darf der Editor-Listener
  /// keinen Autosave auslösen.
  bool _suppressAutosave = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _editor.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final notes = await _service.list();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
      if (_selected != null) {
        // Auswahl über die ID wiederherstellen (Liste wurde neu geladen).
        final match = notes.where((n) => n.id == _selected!.id);
        _selected = match.isEmpty ? null : match.first;
      }
    });
  }

  void _select(Note note) {
    _saveDebounce?.cancel();
    _flushSave(); // Offene Änderungen der vorherigen Notiz noch sichern.
    setState(() {
      _selected = note;
      _suppressAutosave = true;
      _editor.text = note.content;
      _suppressAutosave = false;
    });
  }

  Future<void> _createNote() async {
    final note = await _service.create();
    await _reload();
    final match = _notes.where((n) => n.id == note.id);
    if (match.isNotEmpty) _select(match.first);
  }

  void _onChanged(String value) {
    if (_suppressAutosave || _selected == null) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _flushSave);
  }

  Future<void> _flushSave() async {
    final current = _selected;
    if (current == null) return;
    final saved =
        await _service.save(current.copyWith(content: _editor.text));
    if (!mounted) return;
    setState(() {
      _selected = saved;
      final i = _notes.indexWhere((n) => n.id == saved.id);
      if (i >= 0) _notes[i] = saved;
      // Liste neu sortieren: die gerade bearbeitete Notiz wandert nach oben.
      _notes.sort((a, b) => b.modified.compareTo(a.modified));
    });
  }

  Future<void> _deleteSelected() async {
    final note = _selected;
    if (note == null) return;
    final t = HermesTokens.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.sidebar,
        title: Text('Notiz löschen?', style: TextStyle(color: t.strong)),
        content: Text(
          '„${note.title.isEmpty ? 'Unbenannt' : note.title}" wird '
          'endgültig gelöscht.',
          style: TextStyle(color: t.muted),
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
      await _service.delete(note);
      setState(() => _selected = null);
      _editor.clear();
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);

    if (_loading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: t.accent),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _noteList(t),
        VerticalDivider(width: 1, color: t.borderSubtle),
        Expanded(child: _editorPane(t)),
      ],
    );
  }

  Widget _noteList(HermesTokens t) {
    return Container(
      width: 240,
      color: t.sidebar,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(HermesTokens.space2),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _createNote,
                icon: Icon(Icons.add, size: 16, color: t.accent),
                label: Text('Neue Notiz', style: TextStyle(color: t.accent)),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: HermesTokens.space2,
                    vertical: HermesTokens.space2,
                  ),
                ),
              ),
            ),
          ),
          Divider(color: t.borderSubtle, height: 1),
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Text('Keine Notizen',
                        style: TextStyle(color: t.muted, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, i) {
                      final note = _notes[i];
                      final selected = note.id == _selected?.id;
                      return InkWell(
                        onTap: () => _select(note),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: HermesTokens.space3,
                            vertical: HermesTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? t.accent.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                width: 3,
                                color: selected
                                    ? t.accent
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(
                            note.title.isEmpty ? 'Unbenannt' : note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? t.accent : t.strong,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _editorPane(HermesTokens t) {
    if (_selected == null) {
      // Empty State (Roadmap: Icon + Text + CTA).
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 48, color: t.muted),
            const SizedBox(height: HermesTokens.space2),
            Text('Wähle eine Notiz oder lege eine neue an.',
                style: TextStyle(color: t.muted)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Editor-Aktionsleiste.
        Container(
          height: 44,
          padding:
              const EdgeInsets.symmetric(horizontal: HermesTokens.space3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: t.borderSubtle, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selected!.title.isEmpty ? 'Unbenannt' : _selected!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.strong,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: t.muted,
                tooltip: 'Notiz löschen',
              ),
            ],
          ),
        ),
        // Editor: Monospace-Token, canvas-Fläche, Autosave onChange.
        Expanded(
          child: Container(
            color: t.bg,
            padding: const EdgeInsets.all(HermesTokens.space3),
            child: TextField(
              controller: _editor,
              onChanged: _onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: MintYText.mono.copyWith(color: t.strong),
              decoration: InputDecoration.collapsed(
                hintText: 'Schreib los …',
                hintStyle: MintYText.mono.copyWith(color: t.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
