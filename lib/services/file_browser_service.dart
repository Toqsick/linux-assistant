import 'dart:io';

/// A single entry in a directory listing.
class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.isSymlink,
    required this.isHidden,
    required this.size,
    required this.modified,
    required this.modeString,
  });

  final String name;
  final String path;
  final bool isDirectory;

  /// Symlinks are never followed for navigation (loop danger, Spec §4):
  /// a symlinked directory is opened externally instead of being entered.
  final bool isSymlink;

  /// Dot-prefixed name.
  final bool isHidden;

  /// Bytes. Always 0 for directories – recursive sizes are computed on
  /// demand only, never during listing (performance, Spec §4).
  final int size;

  final DateTime modified;

  /// Unix permission string from [FileStat.modeString], e.g. "drwxr-xr-x".
  final String modeString;
}

/// Result of listing a directory. [error] is reported in-band instead of
/// throwing, so the screen can render permission problems inline.
class DirListing {
  const DirListing({
    required this.path,
    required this.entries,
    this.error,
  });

  final String path;
  final List<FileEntry> entries;
  final String? error;

  bool get hasError => error != null;
}

/// Directory access for the integrated file manager (Admin-Hub E4,
/// Spec: docs/design/feature-spec-admin-hub.md §4).
///
/// Pure dart:io – listing never shells out. External programs are only used
/// to open a path (`xdg-open`, detached).
class FileBrowserService {
  /// Virtual kernel filesystems. They are read-only by policy in the UI:
  /// shown greyed out, never deletable.
  static const List<String> protectedPrefixes = ['/proc', '/sys', '/dev'];

  /// Quick-access locations of the Spec; the screen filters this map to
  /// paths that exist.
  static Map<String, String> quickAccessCandidates() {
    final home = Platform.environment['HOME'] ?? '/';
    return <String, String>{
      'Home': home,
      '/': '/',
      '/mnt': '/mnt',
      'Downloads': '$home/Downloads',
      'Desktop': '$home/Desktop',
    };
  }

  /// True for [protectedPrefixes] and everything below them.
  static bool isProtected(String path) {
    final normalized = normalize(path);
    for (final prefix in protectedPrefixes) {
      if (normalized == prefix || normalized.startsWith('$prefix/')) {
        return true;
      }
    }
    return false;
  }

  /// Strips trailing slashes (except for the root itself).
  static String normalize(String path) {
    var p = path.isEmpty ? '/' : path;
    while (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  static String baseName(String path) {
    final normalized = normalize(path);
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }

  /// Parent directory of [path]; the parent of `/` is `/`.
  static String parentOf(String path) {
    final normalized = normalize(path);
    if (normalized == '/') return '/';
    final index = normalized.lastIndexOf('/');
    return index <= 0 ? '/' : normalized.substring(0, index);
  }

  /// Lists [path]: directories first, then case-insensitive by name.
  /// Dot-files are included only with [showHidden]. Unreadable entries are
  /// skipped; an unreadable directory yields a [DirListing] with [error].
  Future<DirListing> listDir(String path, {bool showHidden = false}) async {
    final entries = <FileEntry>[];
    try {
      await for (final entity in Directory(path).list(followLinks: false)) {
        final name = baseName(entity.path);
        final hidden = name.startsWith('.');
        if (hidden && !showHidden) continue;
        try {
          // With followLinks: false a symlink surfaces as a Link, never as
          // the Directory/File it points at – so `entity is Directory` is a
          // reliable type test and no extra stat call is needed for it.
          final isLink = entity is Link;
          final stat = await FileStat.stat(entity.path);
          entries.add(FileEntry(
            name: name,
            path: entity.path,
            isDirectory: entity is Directory,
            isSymlink: isLink,
            isHidden: hidden,
            size: entity is File ? stat.size : 0,
            modified: stat.modified,
            modeString: stat.modeString(),
          ));
        } catch (_) {
          // Vanished or unreadable between list() and stat() – skip the
          // entry, don't sacrifice the whole listing.
        }
      }
    } on FileSystemException catch (e) {
      return DirListing(path: path, entries: const [], error: e.message);
    }
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return DirListing(path: path, entries: entries);
  }

  /// Deletes [entry] and returns null on success or an error message.
  ///
  /// Directories require [recursive]. Protected system paths are refused
  /// before touching the filesystem. Symlinks are deleted as links (the
  /// target is never touched).
  Future<String?> delete(FileEntry entry, {bool recursive = false}) async {
    if (isProtected(entry.path)) {
      return 'Geschützter Systempfad: ${entry.path}';
    }
    try {
      if (entry.isDirectory) {
        if (!recursive) {
          return 'Verzeichnis – rekursives Löschen erforderlich';
        }
        await Directory(entry.path).delete(recursive: true);
      } else {
        // File.delete on a symlink path removes the link, not the target.
        await File(entry.path).delete();
      }
    } on FileSystemException catch (e) {
      return e.message;
    }
    return null;
  }

  /// Opens [path] with the desktop's default handler. Detached: the handler
  /// outlives this call and must not block the UI.
  Future<bool> openPath(String path) async {
    try {
      await Process.start(
        'xdg-open',
        [path],
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 0 → "0 B", 1536 → "1.5 K", 2621440 → "2.5 M".
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['K', 'M', 'G', 'T'];
    var value = bytes.toDouble();
    var unit = -1;
    do {
      value /= 1024;
      unit++;
    } while (value >= 1024 && unit < units.length - 1);
    return '${value.toStringAsFixed(1)} ${units[unit]}';
  }

  /// "2026-08-22 17:03" – compact, sortable, locale-independent.
  static String formatModified(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}
