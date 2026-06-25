import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/menu.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/menu_photo_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/camera_glyph.dart';
import '../widgets/hot_dish_mark.dart';
import '../widgets/stripe_placeholder.dart';
import 'menu_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> with WidgetsBindingObserver {
  final _history = HistoryService();
  final _api = ApiService();

  List<HistoryEntry> _entries = [];
  bool _loading = true;
  String _query = '';

  // Inline rename state.
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
    if (mounted) setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  /// Re-reads history from storage. Called by AppShell when this tab is shown,
  /// so a just-scanned menu appears without leaving/returning to the screen.
  void reload() => _load();

  List<HistoryEntry> get _visible {
    if (_query.trim().isEmpty) return _entries;
    final q = _query.toLowerCase();
    return _entries.where((e) => e.title.toLowerCase().contains(q)).toList();
  }

  Future<void> _open(HistoryEntry entry) async {
    _stopEditing();
    try {
      final menu = await _api.getMenu(entry.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MenuScreen(menu: menu, api: _api, history: _history),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e'), backgroundColor: AppColors.primaryDeep),
      );
    }
  }

  Future<void> _confirmDelete(HistoryEntry entry) async {
    _stopEditing();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete this menu?', style: AppText.header),
        content: Text('“${entry.title}” will be removed from your saved scans.',
            style: AppText.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.body)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.allergen)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final updated = await _history.removeEntry(entry.id);
      if (mounted) setState(() => _entries = updated);
    }
  }

  void _startEditing(HistoryEntry entry) {
    setState(() {
      _editingId = entry.id;
      _editCtrl.text = entry.customName ?? entry.displayName;
    });
    Future.delayed(const Duration(milliseconds: 50), _editFocus.requestFocus);
  }

  void _stopEditing() {
    if (_editingId == null) return;
    setState(() => _editingId = null);
    _editCtrl.clear();
  }

  Future<void> _saveEdit(String id) async {
    final updated = await _history.renameEntry(id, _editCtrl.text.trim());
    if (mounted) setState(() {
      _entries = updated;
      _editingId = null;
    });
    _editCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _stopEditing,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : (_entries.isEmpty ? _emptyState() : _populated()),
        ),
      ),
    );
  }

  // ── Populated ──────────────────────────────────────────────────────────────
  Widget _populated() {
    final visible = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Scans', style: AppText.screenTitle),
                    Text(
                      '${_entries.length} saved ${_entries.length == 1 ? 'menu' : 'menus'}',
                      style: AppText.meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search field.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: AppText.bodySmall.copyWith(color: AppColors.ink),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search saved menus…',
                      hintStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        color: Color(0xFFC5B8AD),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: visible.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(child: Text('No menus match “$_query”.', style: AppText.body)),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _entryCard(visible[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _entryCard(HistoryEntry entry) {
    final editing = _editingId == entry.id;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: editing ? AppColors.primary : AppColors.border,
          width: editing ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 58, height: 58, child: _thumb(entry)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: editing ? _renameField(entry) : _entryInfo(entry),
          ),
          const SizedBox(width: 8),
          if (editing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _smallAction(Icons.check, AppColors.success, AppColors.successBg,
                    () => _saveEdit(entry.id)),
                const SizedBox(width: 6),
                _smallAction(Icons.close, AppColors.allergen, AppColors.allergenBg,
                    _stopEditing),
              ],
            )
          else
            _overflow(entry),
        ],
      ),
    );
  }

  Widget _entryInfo(HistoryEntry entry) {
    return GestureDetector(
      onTap: () => _open(entry),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${entry.dishCount} dishes · ${timeago.format(entry.savedAt)}',
            style: AppText.meta,
          ),
        ],
      ),
    );
  }

  Widget _renameField(HistoryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: TextField(
            controller: _editCtrl,
            focusNode: _editFocus,
            cursorColor: AppColors.primary,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _saveEdit(entry.id),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(height: 4),
        const Text('Tap checkmark to save name', style: AppText.meta),
      ],
    );
  }

  Widget _smallAction(IconData icon, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }

  Widget _overflow(HistoryEntry entry) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.fillWarm,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.more_vert, size: 16, color: AppColors.muted),
      ),
      padding: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        if (v == 'rename') _startEditing(entry);
        if (v == 'delete') _confirmDelete(entry);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'rename',
          child: Row(children: [
            Icon(Icons.edit_outlined, size: 18, color: AppColors.body),
            SizedBox(width: 10),
            Text('Rename', style: AppText.bodySmall),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 18, color: AppColors.allergen),
            SizedBox(width: 10),
            Text('Delete', style: TextStyle(
                fontFamily: AppTheme.fontFamily, fontSize: 13, color: AppColors.allergen)),
          ]),
        ),
      ],
    );
  }

  Widget _thumb(HistoryEntry entry) {
    final file = MenuPhotoStore.resolve(entry.menuPhotoPath);
    if (file != null && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const StripePlaceholder.warm());
    }
    return const StripePlaceholder.warm();
  }

  // ── Empty state ──────────────────────────────────────────────────────────────
  Widget _emptyState() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Scans', style: AppText.screenTitle),
                Text('No saved menus yet', style: AppText.meta),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Hot Dish hero in a peach diagonal-stripe squircle.
                SizedBox(
                  width: 156,
                  height: 156,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const StripePlaceholder(
                          stripeA: AppColors.primaryTintBg,
                          stripeB: Color(0xFFFFE9DE),
                        ),
                        const HotDishMark(
                          size: 92,
                          shadows: [
                            BoxShadow(
                              color: Color(0x47F05A28),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'No saved scans yet',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.025 * 22,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Menus you photograph will be saved here so you can revisit '
                  'them anytime — even offline.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => appShellKey.currentState?.switchTab(0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CameraGlyph(size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Scan your first menu',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const _HowItWorks(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', AppColors.primary, AppColors.primaryTintBg,
          'Photograph any restaurant menu — works in 40+ languages'),
      ('2', AppColors.success, AppColors.successBg,
          'Get every dish translated with AI photos and descriptions'),
      ('3', AppColors.category, AppColors.categoryBg,
          'Save and revisit your menus anytime, even offline'),
    ];
    return Column(
      children: [
        for (final s in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.$3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s.$1,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: s.$2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.$4,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
