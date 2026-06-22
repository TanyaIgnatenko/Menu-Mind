import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu.dart';

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
  Future<List<HistoryEntry>> addToHistory(
    Menu menu, {
    String? menuPhotoPath,
  }) async {
    final entries = await getHistory();
    final entry = HistoryEntry(
      id: menu.id,
      displayName: menu.autoName,
      dishCount: menu.dishes.length,
      savedAt: DateTime.now(),
      menuPhotoPath: menuPhotoPath,
    );
    final updated = [entry, ...entries.where((e) => e.id != menu.id)]
        .take(_maxEntries)
        .toList();
    await _save(updated);
    return updated;
  }

  Future<List<HistoryEntry>> removeEntry(String id) async {
    final entries = await getHistory();
    final updated = entries.where((e) => e.id != id).toList();
    await _save(updated);
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
