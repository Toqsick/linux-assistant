import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/layouts/tools/quick_notes.dart';
import 'package:linux_assistant/services/notes_service.dart';

/// Real file IO started from the fake-async test zone needs several
/// drain-and-pump rounds to work through its await chain; one round only
/// advances it by a single hop.
Future<void> _drainRealIo(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// In-memory stand-in with the same surface as [NotesService].
///
/// The corruption bug lives in the page's state handling, not on disk, and
/// dart:io streams do not reliably complete under the test binding's fake
/// clock — so the guard is tested against pure futures.
class _MemoryNotesService extends NotesService {
  _MemoryNotesService() : super.test(Directory('/unused-in-memory-service'));

  final Map<String, Note> _store = {};

  /// Parks saves of note 'a' until the test releases them: the corruption
  /// happened in the window between "save started" and "save continuation
  /// runs", which timing alone cannot hit deterministically.
  Completer<void>? gateA;

  void seed(String id, String content) {
    _store[id] = Note(
        id: id,
        title: Note.deriveTitle(content),
        content: content,
        modified: DateTime.now());
  }

  @override
  Future<List<Note>> list() async {
    final notes = _store.values.toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));
    return notes;
  }

  @override
  Future<Note> save(Note note) async {
    final gate = gateA;
    if (gate != null && note.id == 'a') {
      await gate.future;
    }
    final saved = note.copyWith(
        title: Note.deriveTitle(note.content), modified: DateTime.now());
    _store[note.id] = saved;
    return saved;
  }

  @override
  Future<Note> create() async =>
      save(Note(id: 'new', title: '', content: '', modified: DateTime.now()));

  @override
  Future<void> delete(Note note) async {
    _store.remove(note.id);
  }
}

void main() {
  testWidgets('switching notes mid-save keeps the new selection and both notes',
      (tester) async {
    final service = _MemoryNotesService();
    service.seed('a', 'AAA');
    service.seed('b', 'BBB');
    service.gateA = Completer<void>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(child: QuickNotesPage(service: service)),
      ),
    ));
    await tester.pump();

    final editor = find.byType(TextField);

    // Edit note A …
    await tester.tap(find.text('AAA'));
    await tester.pump();
    await tester.enterText(editor, 'AAA-extended');
    // … and switch to B while A's save is still parked in the gate.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('BBB'));
    await tester.pump();

    // Release the parked save of A — its continuation must not write the
    // selection back to A.
    service.gateA!.complete();
    await tester.pump();

    expect(tester.widget<TextField>(editor).controller?.text, 'BBB',
        reason: 'the editor must keep showing the newly selected note');

    // A keystroke now must land in B, not in A.
    await tester.enterText(editor, 'BBB-new');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(service._store['a']!.content, 'AAA-extended',
        reason: 'B content must never be written into note A');
    expect(service._store['b']!.content, 'BBB-new');
  });

  testWidgets('a failing load shows an error state, not an endless spinner',
      (tester) async {
    final blocked = Directory.systemTemp.createTempSync('notes-load-error');
    addTearDown(() => blocked.deleteSync(recursive: true));
    // Shadow the notes directory with a regular file: list() then throws.
    File('${blocked.path}/linux-assistant').createSync(recursive: true);
    final service =
        NotesService.test(Directory('${blocked.path}/linux-assistant/notes'));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(child: QuickNotesPage(service: service)),
      ),
    ));
    await _drainRealIo(tester);

    expect(find.textContaining('Notizen konnten nicht geladen werden'),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
