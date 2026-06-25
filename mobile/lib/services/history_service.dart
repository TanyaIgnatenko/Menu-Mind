import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu.dart';
import 'menu_photo_store.dart';

const _key = 'menumind:history';
const _maxEntries = 20;

class HistoryService {
  Future<List<HistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => HistoryEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Сохраняет меню в историю.
  /// [menuPhotoPath] — локальный путь к фото меню которое загрузил пользователь.
  ///
  /// Если запись с таким id уже есть (например, повторное сохранение из
  /// MenuScreen после догенерации фото), сохраняем её путь к фото, кастомное имя
  /// и время — чтобы не затереть их.
  Future<List<HistoryEntry>> addToHistory(
    Menu menu, {
    String? menuPhotoPath,
  }) async {
    final entries = await getHistory();
    HistoryEntry? existing;
    for (final e in entries) {
      if (e.id == menu.id) {
        existing = e;
        break;
      }
    }
    final entry = HistoryEntry(
      id: menu.id,
      displayName: menu.autoName,
      dishCount: menu.dishes.length,
      savedAt: existing?.savedAt ?? DateTime.now(),
      menuPhotoPath: menuPhotoPath ?? existing?.menuPhotoPath,
      customName: existing?.customName,
    );
    final full = [entry, ...entries.where((e) => e.id != menu.id)];
    final updated = full.take(_maxEntries).toList();
    await _save(updated);
    // Delete photos of entries evicted past the cap.
    for (final e in full.skip(_maxEntries)) {
      await MenuPhotoStore.delete(e.menuPhotoPath);
    }
    return updated;
  }

  Future<List<HistoryEntry>> removeEntry(String id) async {
    final entries = await getHistory();
    final updated = entries.where((e) => e.id != id).toList();
    await _save(updated);
    for (final e in entries.where((e) => e.id == id)) {
      await MenuPhotoStore.delete(e.menuPhotoPath);
    }
    return updated;
  }

  Future<List<HistoryEntry>> renameEntry(String id, String name) async {
    final entries = await getHistory();
    final updated = entries.map((e) {
      if (e.id == id) e.customName = name.trim().isEmpty ? null : name.trim();
      return e;
    }).toList();
    await _save(updated);
    return updated;
  }

  Future<void> _save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
