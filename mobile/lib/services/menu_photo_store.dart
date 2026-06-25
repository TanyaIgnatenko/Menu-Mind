import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Persists the user's original menu photos in the app's documents directory.
///
/// History entries store only the *filename* (e.g. `<menuId>.jpg`); the absolute
/// path is rebuilt at read time from the current documents dir. Storing relative
/// names avoids the classic bug where a saved absolute path becomes invalid if
/// the app's storage location ever changes (app move / reinstall).
class MenuPhotoStore {
  MenuPhotoStore._();

  static Directory? _dir;

  /// Resolves and creates the photos directory. Call once at startup.
  static Future<void> init() async {
    if (_dir != null) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final d = Directory('${docs.path}/menu_photos');
      if (!d.existsSync()) d.createSync(recursive: true);
      _dir = d;
    } catch (_) {
      // Leave _dir null — callers degrade to the stripe placeholder.
    }
  }

  /// Copies [src] into the store keyed by [id]; returns the stored filename
  /// (relative), or null on failure.
  static Future<String?> save(File src, String id) async {
    await init();
    final dir = _dir;
    if (dir == null) return null;
    try {
      final dot = src.path.lastIndexOf('.');
      final ext = dot != -1 ? src.path.substring(dot + 1) : 'jpg';
      final name = '$id.$ext';
      await src.copy('${dir.path}/$name');
      return name;
    } catch (_) {
      return null;
    }
  }

  /// Rebuilds the absolute [File] for a stored value, or null. Tolerates legacy
  /// entries that stored an absolute path (pre-refactor).
  static File? resolve(String? name) {
    if (name == null || name.isEmpty) return null;
    if (name.contains('/') || name.contains('\\')) return File(name); // legacy
    final dir = _dir;
    if (dir == null) return null;
    return File('${dir.path}/$name');
  }

  /// Deletes a stored photo (only files we own, never legacy absolute paths).
  static Future<void> delete(String? name) async {
    final dir = _dir;
    if (dir == null || name == null || name.isEmpty) return;
    if (name.contains('/') || name.contains('\\')) return; // don't touch legacy paths
    try {
      final f = File('${dir.path}/$name');
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}
