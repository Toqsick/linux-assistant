import 'dart:io';

/// Eine einzelne Quick Note – eine Datei pro Notiz.
class Note {
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modified,
  });

  /// Dateiname ohne Extension (z. B. Zeitstempel-basiert).
  final String id;

  /// Erste nicht-leere Zeile des Inhalts (abgeleitet, nicht gespeichert).
  final String title;

  /// Roher Markdown-/Plaintext-Inhalt.
  final String content;

  /// Letzte Änderung (mtime der Datei).
  final DateTime modified;

  Note copyWith({String? title, String? content, DateTime? modified}) => Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        modified: modified ?? this.modified,
      );

  /// Leitet den Anzeigetitel aus dem Inhalt ab.
  static String deriveTitle(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed.length > 60 ? '${trimmed.substring(0, 60)}…' : trimmed;
      }
    }
    return '';
  }
}

/// CRUD + Persistenz für Quick Notes (Admin-Hub E2, Spec: docs/design/feature-spec-admin-hub.md).
///
/// Speicherort: `~/.local/share/linux-assistant/notes/*.md` (XDG-konform).
/// Schreiben erfolgt atomar (tmp + rename), damit ein Absturz während des
/// Autosave keine halbe Datei hinterlässt.
///
/// Testbar: Das Wurzelverzeichnis ist injizierbar ([NotesService.test]).
class NotesService {
  NotesService() : _dir = Directory(_defaultPath());

  /// Test-Konstruktor mit eigenem Verzeichnis.
  NotesService.test(Directory dir) : _dir = dir;

  final Directory _dir;

  static String _defaultPath() {
    final home = Platform.environment['HOME'] ?? '.';
    final xdg = Platform.environment['XDG_DATA_HOME'];
    final base = (xdg != null && xdg.isNotEmpty) ? xdg : '$home/.local/share';
    return '$base/linux-assistant/notes';
  }

  Future<void> _ensureDir() async {
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
  }

  /// Alle Notizen, zuletzt geändert zuerst.
  Future<List<Note>> list() async {
    await _ensureDir();
    final notes = <Note>[];
    await for (final entity in _dir.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          notes.add(await _read(entity));
        } catch (_) {
          // Korrupte Datei überspringen, nicht die ganze Liste opfern.
        }
      }
    }
    notes.sort((a, b) => b.modified.compareTo(a.modified));
    return notes;
  }

  Future<Note> _read(File file) async {
    final content = await file.readAsString();
    final stat = await file.stat();
    final id = _basename(file.path);
    return Note(
      id: id,
      title: Note.deriveTitle(content),
      content: content,
      modified: stat.modified,
    );
  }

  static String _basename(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
  }

  /// Legt eine neue leere Notiz an und gibt sie zurück.
  Future<Note> create() async {
    await _ensureDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final note = Note(id: id, title: '', content: '', modified: DateTime.now());
    await save(note);
    return note;
  }

  /// Speichert atomar: erst `.tmp`-Datei, dann rename.
  Future<Note> save(Note note) async {
    await _ensureDir();
    final target = File('${_dir.path}${Platform.pathSeparator}${note.id}.md');
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(note.content, flush: true);
    await tmp.rename(target.path);
    final stat = await target.stat();
    return note.copyWith(
      title: Note.deriveTitle(note.content),
      modified: stat.modified,
    );
  }

  /// Löscht eine Notiz endgültig. Der aufrufende Screen zeigt vorher einen
  /// Confirm-Dialog (destructive action, siehe Design-Roadmap B.4).
  Future<void> delete(Note note) async {
    final file = File('${_dir.path}${Platform.pathSeparator}${note.id}.md');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
