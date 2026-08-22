import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/services/notes_service.dart';

void main() {
  late Directory tmp;
  late NotesService service;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('notes_test');
    service = NotesService.test(tmp);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('NotesService', () {
    test('list() auf leerem/fehlendem Verzeichnis gibt leere Liste', () async {
      expect(await service.list(), isEmpty);
      // Verzeichnis wurde dabei angelegt:
      expect(await tmp.exists(), isTrue);
    });

    test('create() legt eine leere .md-Datei an', () async {
      final note = await service.create();
      expect(note.content, isEmpty);
      final file = File('${tmp.path}/${note.id}.md');
      expect(await file.exists(), isTrue);
    });

    test('save() persistiert Inhalt und leitet den Titel ab', () async {
      final note = await service.create();
      final saved = await service
          .save(note.copyWith(content: 'Einkaufen\n\n- Milch\n- Kaffee'));

      expect(saved.title, 'Einkaufen');

      final reloaded = (await service.list()).single;
      expect(reloaded.content, contains('- Milch'));
      expect(reloaded.title, 'Einkaufen');
    });

    test('save() ist atomar – keine .tmp-Reste bleiben liegen', () async {
      final note = await service.create();
      await service.save(note.copyWith(content: 'test'));

      final leftovers = await tmp
          .list()
          .where((e) => e.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    });

    test('list() sortiert zuletzt geändert zuerst', () async {
      final a = await service.create();
      await Future.delayed(const Duration(milliseconds: 10));
      final b = await service.create();
      await service.save(a.copyWith(content: 'alt aber gerade editiert'));

      final notes = await service.list();
      expect(notes.first.id, a.id);
      expect(notes.last.id, b.id);
    });

    test('delete() entfernt die Datei', () async {
      final note = await service.create();
      await service.delete(note);
      expect(await service.list(), isEmpty);
    });

    test('delete() auf nicht-existente Notiz wirft nicht', () async {
      final ghost = Note(
          id: 'ghost', title: '', content: '', modified: DateTime.now());
      await service.delete(ghost); // darf nicht crashen
    });

    test('korrupte Dateien brechen list() nicht', () async {
      await service.create();
      // Binärmüll in eine zweite Datei schreiben:
      final bad = File('${tmp.path}/bad.md');
      await bad.writeAsBytes([0, 159, 146, 150]); // ungültiges UTF-8

      final notes = await service.list();
      expect(notes.length, 1); // nur die valide Notiz
    });
  });

  group('Note.deriveTitle', () {
    test('erste nicht-leere Zeile wird Titel', () {
      expect(Note.deriveTitle('\n\n  Hallo Welt\nfoo'), 'Hallo Welt');
    });

    test('leerer Inhalt → leerer Titel', () {
      expect(Note.deriveTitle(''), '');
      expect(Note.deriveTitle('\n  \n'), '');
    });

    test('lange Zeilen werden auf 60 Zeichen gekürzt', () {
      final long = 'a' * 100;
      expect(Note.deriveTitle(long).length, 61); // 60 + Ellipsis
    });
  });
}
