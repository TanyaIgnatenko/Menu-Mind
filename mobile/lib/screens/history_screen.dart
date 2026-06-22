import 'dart:io';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/menu.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import 'menu_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  final _history = HistoryService();
  final _api = ApiService();
  List<HistoryEntry> _entries = [];
  bool _loading = true;
  // id записи которая сейчас редактируется
  String? _editingId;
  final _editCtrl = TextEditingController();
  final _editFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editCtrl.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final entries = await _history.getHistory();
    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  Future<void> _open(HistoryEntry entry) async {
    _stopEditing();
    try {
      final menu = await _api.getMenu(entry.id);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, __) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: MenuScreen(menu: menu, api: _api, history: _history),
          ),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e'), backgroundColor: AppColors.beet),
      );
    }
  }

  Future<void> _delete(String id) async {
    _stopEditing();
    final updated = await _history.removeEntry(id);
    if (mounted) setState(() => _entries = updated);
  }

  void _startEditing(HistoryEntry entry) {
    setState(() {
      _editingId = entry.id;
      _editCtrl.text = entry.customName ?? entry.displayName;
    });
    Future.delayed(const Duration(milliseconds: 50), () => _editFocus.requestFocus());
  }

  void _stopEditing() {
    if (_editingId == null) return;
    setState(() => _editingId = null);
    _editCtrl.clear();
  }

  Future<void> _saveEdit(String id) async {
    final name = _editCtrl.text.trim();
    final updated = await _history.renameEntry(id, name);
    if (mounted) setState(() { _entries = updated; _editingId = null; });
    _editCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _stopEditing,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('Recent menus'),
          automaticallyImplyLeading: false,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.beet))
            : RefreshIndicator(
                color: AppColors.beet,
                onRefresh: _load,
                child: _entries.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (_, i) => _entryCard(_entries[i]),
                      ),
              ),
      ),
    );
  }

  Widget _entryCard(HistoryEntry entry) {
    final isEditing = _editingId == entry.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isEditing ? null : () => _open(entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ── Превью фото ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildPreview(entry),
                ),
              ),
              const SizedBox(width: 12),

              // ── Название и метаданные ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing)
                      // Inline редактирование
                      TextField(
                        controller: _editCtrl,
                        focusNode: _editFocus,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBeet,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.beet),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: AppColors.beet, width: 1.5),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check,
                                color: AppColors.beet, size: 18),
                            onPressed: () => _saveEdit(entry.id),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        onSubmitted: (_) => _saveEdit(entry.id),
                        textInputAction: TextInputAction.done,
                      )
                    else
                      // Название
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBeet,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    // Метаданные
                    Text(
                      '${entry.dishCount} dishes · ${timeago.format(entry.savedAt)}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Кнопки ───────────────────────────────────────────
              if (!isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textMuted),
                  onPressed: () => _startEditing(entry),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.textMuted),
                  onPressed: () => _delete(entry.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(HistoryEntry entry) {
    final path = entry.menuPhotoPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEDE5DC),
        child: const Center(
          child: Icon(Icons.restaurant_menu_outlined,
              color: AppColors.textMuted, size: 24),
        ),
      );

  Widget _emptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'No menus yet',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.deepBeet,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Upload your first menu to get started.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
