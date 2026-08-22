import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linux_assistant/services/file_browser_service.dart';

void main() {
  late Directory tmp;
  late FileBrowserService service;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('file_browser_test');
    service = FileBrowserService();

    await Directory('${tmp.path}/dirA').create();
    await Directory('${tmp.path}/dirB').create();
    await File('${tmp.path}/file1.txt').writeAsString('hello');
    await File('${tmp.path}/file2.md').writeAsString('# title\n');
    await File('${tmp.path}/.hidden').writeAsString('x');
    await Directory('${tmp.path}/.hiddendir').create();
    await Link('${tmp.path}/link_to_file').create('file1.txt');
    await Link('${tmp.path}/link_to_dir').create('dirA');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('listDir', () {
    test('directories first, then case-insensitive by name', () async {
      final listing = await service.listDir(tmp.path);
      final names = listing.entries.map((e) => e.name).toList();
      expect(names.sublist(0, 2), ['dirA', 'dirB']);
      expect(names.indexOf('file1.txt'), lessThan(names.indexOf('file2.md')));
      // A symlink to a directory sorts with the files, never the dirs:
      expect(names.indexOf('link_to_dir'),
          greaterThan(names.indexOf('file2.md')));
    });

    test('hidden entries are filtered by default', () async {
      final listing = await service.listDir(tmp.path);
      expect(listing.entries.any((e) => e.name == '.hidden'), isFalse);
      expect(listing.entries.any((e) => e.name == '.hiddendir'), isFalse);
    });

    test('hidden entries are included with showHidden', () async {
      final listing = await service.listDir(tmp.path, showHidden: true);
      expect(listing.entries.any((e) => e.name == '.hidden'), isTrue);
      expect(listing.entries.any((e) => e.name == '.hiddendir'), isTrue);
      // …and a hidden directory still sorts with the directories:
      final names = listing.entries.map((e) => e.name).toList();
      expect(names.indexOf('.hiddendir'), lessThan(names.indexOf('dirA')));
    });

    test('symlinks are flagged and never reported as directories', () async {
      final listing = await service.listDir(tmp.path);
      final link = listing.entries.firstWhere((e) => e.name == 'link_to_dir');
      expect(link.isSymlink, isTrue);
      expect(link.isDirectory, isFalse);
    });

    test('files carry their size, directories do not', () async {
      final listing = await service.listDir(tmp.path);
      final file = listing.entries.firstWhere((e) => e.name == 'file1.txt');
      final dir = listing.entries.firstWhere((e) => e.name == 'dirA');
      expect(file.size, 5);
      expect(dir.size, 0);
    });

    test('mode strings look like unix permissions', () async {
      final listing = await service.listDir(tmp.path);
      for (final entry in listing.entries) {
        expect(entry.modeString, hasLength(10));
      }
    });

    test('a missing directory reports an error instead of throwing', () async {
      final listing = await service.listDir('${tmp.path}/does-not-exist');
      expect(listing.hasError, isTrue);
      expect(listing.entries, isEmpty);
    });
  });

  group('protected paths', () {
    test('kernel filesystems are protected', () {
      expect(FileBrowserService.isProtected('/proc'), isTrue);
      expect(FileBrowserService.isProtected('/proc/cpuinfo'), isTrue);
      expect(FileBrowserService.isProtected('/sys/class'), isTrue);
      expect(FileBrowserService.isProtected('/dev/sda'), isTrue);
    });

    test('lookalike prefixes are not protected', () {
      expect(FileBrowserService.isProtected('/procedure'), isFalse);
      expect(FileBrowserService.isProtected('/home/user/dev'), isFalse);
      expect(FileBrowserService.isProtected('/'), isFalse);
    });

    test('delete refuses protected paths before touching the filesystem',
        () async {
      final entry = FileEntry(
        name: 'cmdline',
        path: '/proc/self/cmdline',
        isDirectory: false,
        isSymlink: false,
        isHidden: false,
        size: 0,
        modified: DateTime(2026),
        modeString: '-r--r--r--',
      );
      expect(await service.delete(entry), isNotNull);
    });
  });

  group('delete', () {
    test('deletes a file', () async {
      final listing = await service.listDir(tmp.path);
      final file = listing.entries.firstWhere((e) => e.name == 'file1.txt');
      expect(await service.delete(file), isNull);
      expect(await File(file.path).exists(), isFalse);
    });

    test('refuses a directory without the recursive flag', () async {
      final listing = await service.listDir(tmp.path);
      final dir = listing.entries.firstWhere((e) => e.name == 'dirA');
      expect(await service.delete(dir), isNotNull);
      expect(await Directory(dir.path).exists(), isTrue);
    });

    test('deletes a directory recursively', () async {
      await File('${tmp.path}/dirB/nested.txt').writeAsString('x');
      final listing = await service.listDir(tmp.path);
      final dir = listing.entries.firstWhere((e) => e.name == 'dirB');
      expect(await service.delete(dir, recursive: true), isNull);
      expect(await Directory(dir.path).exists(), isFalse);
    });

    test('deletes a symlink, not its target', () async {
      final listing = await service.listDir(tmp.path);
      final link =
          listing.entries.firstWhere((e) => e.name == 'link_to_file');
      expect(await service.delete(link), isNull);
      expect(await File('${tmp.path}/file1.txt').exists(), isTrue);
      expect(await FileSystemEntity.isLink(link.path), isFalse);
    });
  });

  group('path helpers', () {
    test('parentOf', () {
      expect(FileBrowserService.parentOf('/'), '/');
      expect(FileBrowserService.parentOf('/home'), '/');
      expect(FileBrowserService.parentOf('/home/user/'), '/home');
      expect(FileBrowserService.parentOf('/home/user/Docs'), '/home/user');
    });

    test('normalize strips trailing slashes except root', () {
      expect(FileBrowserService.normalize('/'), '/');
      expect(FileBrowserService.normalize('/home/'), '/home');
      expect(FileBrowserService.normalize(''), '/');
    });
  });

  group('formatting', () {
    test('formatSize', () {
      expect(FileBrowserService.formatSize(0), '0 B');
      expect(FileBrowserService.formatSize(512), '512 B');
      expect(FileBrowserService.formatSize(1024), '1.0 K');
      expect(FileBrowserService.formatSize(1536), '1.5 K');
      expect(FileBrowserService.formatSize(1048576), '1.0 M');
      expect(FileBrowserService.formatSize(2684354560), '2.5 G');
    });

    test('formatModified is compact and zero-padded', () {
      expect(FileBrowserService.formatModified(DateTime(2026, 8, 22, 17, 3)),
          '2026-08-22 17:03');
    });
  });
}
