import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stripe_placeholder.dart';
import '../widgets/diet_chip.dart';

class DishScreen extends StatefulWidget {
  final Dish dish;
  final ApiService api;

  /// Identity of this dish within its menu, so the screen can keep polling for
  /// the second-pass enrichment (about + nutrition) that may still be in flight
  /// when the dish is opened.
  final String menuId;
  final int dishIndex;

  /// Whether the whole menu was already finished (all images resolved) at the
  /// moment this dish was opened. If so, no more enrichment is coming and we
  /// must not show a perpetual loader for a dish whose enrichment simply failed.
  final bool menuSettled;

  const DishScreen({
    super.key,
    required this.dish,
    required this.api,
    required this.menuId,
    required this.dishIndex,
    required this.menuSettled,
  });

  @override
  State<DishScreen> createState() => _DishScreenState();
}

class _DishScreenState extends State<DishScreen> {
  static const _heroHeight = 365.0;
  static const _sheetOverlap = 28.0;

  late Dish _dish;

  /// True while we still expect the enrichment pass to deliver about/nutrition.
  /// Drives both the polling loop and the shimmer placeholders.
  bool _expectMore = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _dish = widget.dish;
    // Only wait for more if this dish isn't enriched yet AND the menu was still
    // being processed when it was opened (otherwise nothing more is coming).
    if (!_isEnriched(_dish) && !widget.menuSettled) {
      _expectMore = true;
      _startPolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isEnriched(Dish d) => d.about.isNotEmpty && d.nutrition != null;

  /// Show shimmer placeholders while enrichment is still expected and the field
  /// hasn't arrived yet.
  bool get _showAboutLoader => _expectMore && _dish.about.isEmpty;
  bool get _showNutritionLoader => _expectMore && _dish.nutrition == null;

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final menu = await widget.api.getMenu(widget.menuId);
        if (!mounted) return;
        if (widget.dishIndex < menu.dishes.length) {
          final updated = menu.dishes[widget.dishIndex];
          setState(() => _dish = updated);
          // Stop once enriched, or once the whole menu is done (no more coming).
          if (_isEnriched(updated) || menu.allImagesResolved) {
            _timer?.cancel();
            setState(() => _expectMore = false);
          }
        } else if (menu.allImagesResolved) {
          _timer?.cancel();
          setState(() => _expectMore = false);
        }
      } catch (_) {}
    });
  }

  String get _name =>
      _dish.nameEnglish.isNotEmpty ? _dish.nameEnglish : _dish.nameOriginal;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: _heroHeight, child: _hero()),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -_sheetOverlap),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenH - _heroHeight + _sheetOverlap,
                    ),
                    child: _sheet(),
                  ),
                ),
              ),
            ],
          ),
          // Floating nav buttons.
          Positioned(
            top: topInset + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FloatingButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.maybePop(context),
                ),
                _FloatingButton(
                  icon: Icons.ios_share_rounded,
                  iconColor: AppColors.body,
                  onTap: () => _share(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _share() {
    final buffer = StringBuffer(_name);
    if (_dish.descriptionEnglish.isNotEmpty) {
      buffer.write('\n\n${_dish.descriptionEnglish}');
    }
    Share.share(buffer.toString(), subject: _name);
  }

  // ── Hero photo ───────────────────────────────────────────────────────────────
  Widget _hero() {
    if (_dish.imageReady) {
      return CachedNetworkImage(
        imageUrl: widget.api.imageUrl(_dish.imageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => const GeneratingPlaceholder(),
        errorWidget: (_, __, ___) => const FailedPlaceholder(large: true),
      );
    }
    if (_dish.imagePending) return const GeneratingPlaceholder();
    return const FailedPlaceholder(large: true);
  }

  // ── Info sheet ───────────────────────────────────────────────────────────────
  Widget _sheet() {
    final category =
        _dish.categoryEnglish.isNotEmpty ? _dish.categoryEnglish : _dish.category;
    final showOriginal =
        _dish.nameOriginal.isNotEmpty && _dish.nameOriginal != _name;

    final tags = _dish.dietaryTags.map(describeTag).whereType<DietTag>().toList();
    final allergens = tags
        .where((t) => t.kind == ChipKind.allergen || t.kind == ChipKind.caution)
        .toList();
    final positives = tags.where((t) => t.kind == ChipKind.positive).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle.
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + price.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (category.isNotEmpty)
                      DietChip(DietTag(category, ChipKind.category)),
                    const Spacer(),
                    if (_dish.price.isNotEmpty)
                      Text(_dish.price, style: AppText.priceLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_name, style: AppText.dishTitle),
                if (showOriginal) ...[
                  const SizedBox(height: 4),
                  Text(
                    _dish.nameOriginal,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.muted,
                    ),
                  ),
                ],

                // Menu description (as written) + its translation.
                if (_dish.descriptionEnglish.isNotEmpty ||
                    _dish.descriptionOriginal.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  if (_dish.descriptionEnglish.isNotEmpty)
                    Text(_dish.descriptionEnglish, style: AppText.bodySmall),
                  if (_dish.descriptionOriginal.isNotEmpty &&
                      _dish.descriptionOriginal != _dish.descriptionEnglish) ...[
                    const SizedBox(height: 3),
                    Text(
                      _dish.descriptionOriginal,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],

                // About this dish (AI-generated narrative) — real, or a loading
                // placeholder while the enrichment pass is still in flight.
                if (_dish.about.isNotEmpty) ...[
                  _divider(),
                  const _Eyebrow('About this dish'),
                  const SizedBox(height: 7),
                  Text(_dish.about, style: AppText.bodySmall),
                ] else if (_showAboutLoader) ...[
                  _divider(),
                  const _Eyebrow('About this dish'),
                  const SizedBox(height: 9),
                  const _AboutLoading(),
                ],

                // Dietary information.
                if (tags.isNotEmpty) ...[
                  _divider(),
                  const _Eyebrow('Dietary information'),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...allergens.map((t) => DietChip(t)),
                      ...positives.map((t) => DietChip(t)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tags are AI-generated. Always verify allergens with the restaurant.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ],

                // Nutrition — real, or a loading placeholder while enrichment runs.
                if (_dish.nutrition != null) ...[
                  _divider(),
                  const _Eyebrow('Nutrition · per serving'),
                  const SizedBox(height: 10),
                  _NutritionRow(nutrition: _dish.nutrition!),
                  const SizedBox(height: 10),
                  const Text(
                    'Values are AI estimates and may vary. Not for medical decisions.',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                ] else if (_showNutritionLoader) ...[
                  _divider(),
                  const _Eyebrow('Nutrition · per serving'),
                  const SizedBox(height: 10),
                  const _NutritionLoading(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(vertical: 13),
        height: 1,
        color: AppColors.divider,
      );
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppText.eyebrow);
  }
}

// ── Enrichment loading placeholders ────────────────────────────────────────────
// Shown while the second-pass enrichment (about + nutrition) is still generating.
// Same warm shimmer as the dish-photo placeholder so the whole screen reads as
// "still loading" with one visual language.

const _shimmerPeriod = Duration(milliseconds: 1600);
const _shimmerBase = Color(0xFFEFE7DC);
const _shimmerHighlight = Color(0xFFFBF7F1);

/// Three shimmering text lines standing in for the "about" paragraph.
class _AboutLoading extends StatelessWidget {
  const _AboutLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: _shimmerPeriod,
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ShimmerBar(),
          SizedBox(height: 8),
          _ShimmerBar(),
          SizedBox(height: 8),
          _ShimmerBar(width: 180),
        ],
      ),
    );
  }
}

/// Four shimmering tiles standing in for the nutrition row.
class _NutritionLoading extends StatelessWidget {
  const _NutritionLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: _shimmerPeriod,
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single rounded bar for the shimmering text lines.
class _ShimmerBar extends StatelessWidget {
  final double? width;
  const _ShimmerBar({this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: 11,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _FloatingButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x24000000), blurRadius: 14, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

// ── Nutrition 4-up tiles ───────────────────────────────────────────────────────

class _NutritionRow extends StatelessWidget {
  final Nutrition nutrition;
  const _NutritionRow({required this.nutrition});

  String _g(double v) => '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(0)}g';

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _NutritionTile('${nutrition.calories}', 'kcal', AppColors.primary, AppColors.primaryTintBg),
      _NutritionTile(_g(nutrition.proteinG), 'protein', AppColors.success, AppColors.successBg),
      _NutritionTile(_g(nutrition.carbsG), 'carbs', AppColors.caution, AppColors.cautionBg),
      _NutritionTile(_g(nutrition.fatG), 'fat', AppColors.category, AppColors.categoryBg),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color bg;
  const _NutritionTile(this.value, this.label, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.02 * 19,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04 * 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
