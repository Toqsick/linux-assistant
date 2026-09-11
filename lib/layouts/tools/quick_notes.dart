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
  const QuickNotesPage({super.key, NotesService? service}) : _service = service;

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
  String? _loadError;
  bool _saveFailed = false;

  /// True ab der ersten Änderung bis zum erfolgreichen Autosave.
  bool _dirty = false;

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
    // Best-effort-Schlussstand: nur das Debounce abzubrechen würde die
    // letzten 500 ms Eingabe verwerfen. Ein await ist in dispose nicht
    // möglich, aber der Schreibvorgang darf loslaufen.
    if (_selected != null && _dirty) {
      unawaited(_service.save(_selected!.copyWith(content: _editor.text)));
    }
    _saveDebounce?.cancel();
    _editor.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final notes = await _service.list();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
        _loadError = null;
        if (_selected != null) {
          // Auswahl über die ID wiederherstellen (Liste wurde neu geladen).
          final match = notes.where((n) => n.id == _selected!.id);
          _selected = match.isEmpty ? null : match.first;
        }
      });
    } catch (e) {
      // Z. B. Notiz-Verzeichnis nicht lesbar: Fehlerzustand statt ewigem
      // Spinner und unhandled exception.
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _select(Note note) {
    _saveDebounce?.cancel();
    _flushSave(); // Offene Änderungen der vorherigen Notiz noch sichern.
    setState(() {
      _selected = note;
      _suppressAutosave = true;
      _editor.text = note.content;
      _suppressAutosave = false;
      _dirty = false;
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
    _dirty = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _flushSave);
  }

  Future<void> _flushSave() async {
    final current = _selected;
    if (current == null) return;
    // _editor.text wird synchron gelesen — vor dem ersten await, also noch
    // bevor ein _select den Editor auf die neue Notiz umstellen kann.
    final content = _editor.text;
    try {
      final saved = await _service.save(current.copyWith(content: content));
      _dirty = false;
      if (!mounted) return;
      if (_selected?.id != current.id) {
        // Der Nutzer hat während des Speicherns die Notiz gewechselt: das
        // Ergebnis darf die neue Auswahl nicht mehr zurückschreiben — sonst
        // landet beim nächsten Autosave der fremde Inhalt in der alten Notiz.
        setState(() {
          final i = _notes.indexWhere((n) => n.id == saved.id);
          if (i >= 0) _notes[i] = saved;
        });
        return;
      }
      setState(() {
        _selected = saved;
        _saveFailed = false;
        final i = _notes.indexWhere((n) => n.id == saved.id);
        if (i >= 0) _notes[i] = saved;
        // Liste neu sortieren: die gerade bearbeitete Notiz wandert nach oben.
        _notes.sort((a, b) => b.modified.compareTo(a.modified));
      });
    } catch (_) {
      // Speicher voll, Verzeichnis schreibgeschützt: weiter tippen erlauben,
      // aber sichtbar machen, dass gerade nichts persistiert wird.
      if (mounted) setState(() => _saveFailed = true);
    }
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

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: t.muted),
            const SizedBox(height: HermesTokens.space2),
            Text('Notizen konnten nicht geladen werden:',
                style: TextStyle(color: t.strong)),
            const SizedBox(height: HermesTokens.space1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: HermesTokens.space3),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
                _reload();
              },
              icon: Icon(Icons.refresh, size: 16, color: t.accent),
              label:
                  Text('Erneut versuchen', style: TextStyle(color: t.accent)),
            ),
          ],
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
                                color: selected ? t.accent : Colors.transparent,
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
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
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
        // Autosave-Warnung: persistieren schlägt fehl (Disk voll, Rechte).
        if (_saveFailed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: HermesTokens.space3, vertical: HermesTokens.space1),
            color: t.error.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: t.error),
                const SizedBox(width: HermesTokens.space2),
                Expanded(
                  child: Text(
                    'Autosave fehlgeschlagen – Änderungen werden aktuell nicht gespeichert.',
                    style: TextStyle(color: t.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        // Editor-Aktionsleiste.
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: HermesTokens.space3),
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
