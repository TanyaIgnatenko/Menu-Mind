import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stripe_placeholder.dart';
import '../widgets/diet_chip.dart';

class DishScreen extends StatelessWidget {
  final Dish dish;
  final ApiService api;

  const DishScreen({super.key, required this.dish, required this.api});

  static const _heroHeight = 365.0;
  static const _sheetOverlap = 28.0;

  String get _name => dish.nameEnglish.isNotEmpty ? dish.nameEnglish : dish.nameOriginal;

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
    if (dish.descriptionEnglish.isNotEmpty) {
      buffer.write('\n\n${dish.descriptionEnglish}');
    }
    Share.share(buffer.toString(), subject: _name);
  }

  // ── Hero photo ───────────────────────────────────────────────────────────────
  Widget _hero() {
    if (dish.imageReady) {
      return CachedNetworkImage(
        imageUrl: api.imageUrl(dish.imageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => const GeneratingPlaceholder(),
        errorWidget: (_, __, ___) => const FailedPlaceholder(large: true),
      );
    }
    if (dish.imagePending) return const GeneratingPlaceholder();
    return const FailedPlaceholder(large: true);
  }

  // ── Info sheet ───────────────────────────────────────────────────────────────
  Widget _sheet() {
    final category = dish.categoryEnglish.isNotEmpty ? dish.categoryEnglish : dish.category;
    final showOriginal = dish.nameOriginal.isNotEmpty && dish.nameOriginal != _name;

    final tags = dish.dietaryTags.map(describeTag).whereType<DietTag>().toList();
    final allergens = tags.where((t) => t.kind == ChipKind.allergen || t.kind == ChipKind.caution).toList();
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
                    if (dish.price.isNotEmpty)
                      Text(dish.price, style: AppText.priceLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_name, style: AppText.dishTitle),
                if (showOriginal) ...[
                  const SizedBox(height: 4),
                  Text(
                    dish.nameOriginal,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.muted,
                    ),
                  ),
                ],

                // About this dish.
                if (dish.about.isNotEmpty || dish.descriptionEnglish.isNotEmpty) ...[
                  _divider(),
                  const _Eyebrow('About this dish'),
                  const SizedBox(height: 7),
                  Text(
                    dish.about.isNotEmpty ? dish.about : dish.descriptionEnglish,
                    style: AppText.bodySmall,
                  ),
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

                // Nutrition.
                if (dish.nutrition != null) ...[
                  _divider(),
                  const _Eyebrow('Nutrition · per serving'),
                  const SizedBox(height: 10),
                  _NutritionRow(nutrition: dish.nutrition!),
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
