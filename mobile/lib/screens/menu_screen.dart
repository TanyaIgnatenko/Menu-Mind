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
  final Set<String> _activeFilters = {};

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

  String get _subtitle {
    final parts = <String>['${_menu.dishes.length} dishes'];
    if (_menu.cuisineType != null && _menu.cuisineType!.isNotEmpty) {
      parts.add(_menu.cuisineType!);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterDishes(_menu.dishes, _activeFilters);

    // Group by category, preserving first-seen order.
    final byCategory = <String, List<Dish>>{};
    for (final dish in filtered) {
      final cat = dish.categoryEnglish.isNotEmpty ? dish.categoryEnglish : dish.category;
      byCategory.putIfAbsent(cat.isEmpty ? 'Menu' : cat, () => []).add(dish);
    }
    final categories = byCategory.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 10),
            DietaryFilters(
              dishes: _menu.dishes,
              active: _activeFilters,
              onToggle: (id) => setState(() {
                _activeFilters.contains(id) ? _activeFilters.remove(id) : _activeFilters.add(id);
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      for (final cat in categories) ...[
                        _categoryHeader(cat, byCategory[cat]!.length),
                        for (final dish in byCategory[cat]!)
                          DishCard(dish: dish, api: widget.api),
                        const SizedBox(height: 8),
                      ],
                      if (categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: Text('No dishes match these filters.',
                                style: AppText.body),
                          ),
                        ),
                    ],
                  ),
                  // Bottom fade.
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.canvas, AppColors.canvas.withOpacity(0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          _IconTile(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _menu.autoName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.header,
                ),
                Text(_subtitle, style: AppText.meta),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _IconTile(icon: Icons.ios_share_rounded, onTap: _showShareSheet),
        ],
      ),
    );
  }

  Widget _categoryHeader(String name, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            '$count ${count == 1 ? 'dish' : 'dishes'}',
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 38px neutral icon button used in headers.
class _IconTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconTile({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fillWarm,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: AppColors.body),
        ),
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
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Share this menu', style: AppText.header),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.body),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text('Scan the QR code or copy the link.', style: AppText.bodySmall),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: QrImageView(
                data: widget.url,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
                backgroundColor: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    widget.url,
                    style: AppText.meta,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _copy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTintBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_copied ? Icons.check : Icons.copy_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
