import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dish_card.dart';
import '../widgets/dietary_filters.dart';

const _webBaseUrl = 'https://menu-mind-tawny.vercel.app';

class MenuScreen extends StatefulWidget {
  final Menu menu;
  final ApiService api;
  final HistoryService history;

  const MenuScreen({
    super.key,
    required this.menu,
    required this.api,
    required this.history,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Menu _menu;
  Timer? _timer;
  Set<String> _activeFilters = {};

  // Ключи для скролла к категориям
  final Map<String, GlobalKey> _categoryKeys = {};
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _menu = widget.menu;
    if (!_menu.allImagesResolved) _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final updated = await widget.api.getMenu(_menu.id);
        if (mounted) setState(() => _menu = updated);
        if (updated.allImagesResolved) {
          _timer?.cancel();
          await widget.history.addToHistory(updated);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String get _shareUrl => '$_webBaseUrl/menu/${_menu.id}';

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(url: _shareUrl),
    );
  }

  void _scrollToCategory(String category) async {
    final key = _categoryKeys[category];
    if (key?.currentContext == null) return;
    await Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterDishes(_menu.dishes, _activeFilters);

    // Группируем по категориям
    final Map<String, List<Dish>> byCategory = {};
    for (final dish in filtered) {
      final cat = dish.categoryEnglish.isNotEmpty
          ? dish.categoryEnglish
          : dish.category;
      byCategory.putIfAbsent(cat, () => []).add(dish);
    }
    final categories = byCategory.keys.toList();

    // Регистрируем ключи для новых категорий
    for (final cat in categories) {
      _categoryKeys.putIfAbsent(cat, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(_menu.restaurantName ?? _menu.autoName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _showShareSheet,
            color: AppColors.beet,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Dietary filters
          SliverToBoxAdapter(
            child: DietaryFilters(
              dishes: _menu.dishes,
              active: _activeFilters,
              onToggle: (id) => setState(() {
                if (_activeFilters.contains(id)) {
                  _activeFilters.remove(id);
                } else {
                  _activeFilters.add(id);
                }
              }),
              shownCount: filtered.length,
            ),
          ),

          // Category navigation chips
          if (categories.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: categories.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(categories[i]),
                      backgroundColor: AppColors.white,
                      side: const BorderSide(
                          color: AppColors.chipInactiveBorder),
                      labelStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.deepBeet,
                      ),
                      onPressed: () => _scrollToCategory(categories[i]),
                    ),
                  ),
                ),
              ),
            ),

          // Блюда по категориям
          for (final cat in categories) ...[
            SliverToBoxAdapter(
              child: Padding(
                key: _categoryKeys[cat],
                padding:
                    const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  cat,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepBeet,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => DishCard(
                    dish: byCategory[cat]![i],
                    api: widget.api,
                  ),
                  childCount: byCategory[cat]!.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Share sheet ──────────────────────────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final String url;
  const _ShareSheet({required this.url});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Share this menu',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepBeet,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Scan the QR code or copy the link.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // QR код
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDDE5CE),
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: widget.url,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.deepBeet,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.deepBeet,
                ),
                backgroundColor: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ссылка + кнопка копирования
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: AppColors.chipInactiveBorder),
                  ),
                  child: Text(
                    widget.url,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _copied
                    ? _chipButton(
                        key: const ValueKey('copied'),
                        icon: Icons.check,
                        label: 'Copied',
                        onTap: _copy,
                      )
                    : _chipButton(
                        key: const ValueKey('copy'),
                        icon: Icons.copy_outlined,
                        label: 'Copy',
                        onTap: _copy,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.chipInactiveBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.beet),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.beet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
