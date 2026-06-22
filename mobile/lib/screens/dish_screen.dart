import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DishScreen extends StatelessWidget {
  final Dish dish;
  final ApiService api;

  const DishScreen({super.key, required this.dish, required this.api});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Фото блюда — растягивается при скролле вниз ──────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.deepBeet,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Английское название ───────────────────────────
                  if (dish.nameEnglish.isNotEmpty &&
                      dish.nameEnglish != dish.nameOriginal)
                    Text(
                      dish.nameEnglish,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBeet,
                        height: 1.2,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // ── Оригинальное название + цена ──────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          dish.nameOriginal,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: dish.nameEnglish.isNotEmpty &&
                                    dish.nameEnglish != dish.nameOriginal
                                ? 16
                                : 26,
                            fontWeight: dish.nameEnglish.isNotEmpty &&
                                    dish.nameEnglish != dish.nameOriginal
                                ? FontWeight.w400
                                : FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (dish.price.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.beet,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            dish.price,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Категория ─────────────────────────────────────
                  if (dish.categoryEnglish.isNotEmpty ||
                      dish.category.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          dish.categoryEnglish.isNotEmpty
                              ? dish.categoryEnglish
                              : dish.category,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  _divider(),
                  const SizedBox(height: 20),

                  // ── Описание (только English под категорией) ────────────────────
                  if (dish.descriptionEnglish.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dish.descriptionEnglish,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Color(0xFF3D3D3D),
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _divider(),
                  const SizedBox(height: 20),

                  // ── About this dish (один параграф) ──────────────
                  if (dish.about.isNotEmpty) ...[
                    _sectionLabel('About this dish'),
                    const SizedBox(height: 10),
                    Text(
                      dish.about,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Color(0xFF3D3D3D),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 20),
                  ],

                  // ── Dietary tags (первым) ────────────────────────
                  if (dish.dietaryTags.isNotEmpty) ...[
                    _sectionLabel('Dietary info'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dish.dietaryTags
                          .map((tag) => _dietaryChip(tag))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tags are AI-generated. Always verify allergens with the restaurant.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 20),
                  ],

                  // ── Nutrition (после dietary) ─────────────────────
                  if (dish.nutrition != null) ...[
                    _sectionLabel('Nutrition (estimated per serving)'),
                    const SizedBox(height: 12),
                    _NutritionCard(nutrition: dish.nutrition!),
                    const SizedBox(height: 8),
                    const Text(
                      'Values are AI estimates and may vary. Not suitable for medical decisions.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    if (dish.imageReady) {
      return CachedNetworkImage(
        imageUrl: api.imageUrl(dish.imageUrl!),
        fit: BoxFit.cover,
        placeholder: (_, __) => _shimmer(),
        errorWidget: (_, __, ___) => _imagePlaceholder(),
      );
    }
    if (dish.imagePending) return _shimmer();
    return _imagePlaceholder();
  }

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: const Color(0xFFEDE5DC),
        highlightColor: const Color(0xFFF6EFE7),
        child: Container(color: const Color(0xFFEDE5DC)),
      );

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFEDE5DC),
        child: const Center(
          child: Icon(Icons.no_food_outlined,
              color: AppColors.textMuted, size: 48),
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      );

  Widget _divider() => Container(
        height: 1,
        color: const Color(0xFFE8DDD6),
      );

  Widget _factCard(int index, String fact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.beet.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.beet,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFF3D3D3D),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  Widget _dietaryChip(String tag) {
    final isWarning = tag.startsWith('contains_');
    final label = tag
        .replaceAll('contains_', 'Contains ')
        .replaceAll('_', ' ')
        .replaceFirst(
            tag[0], tag[0].toUpperCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.beet.withOpacity(0.08)
            : AppColors.dill.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWarning
              ? AppColors.beet.withOpacity(0.25)
              : AppColors.dill.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isWarning ? AppColors.beet : AppColors.dill,
        ),
      ),
    );
  }
}


// ── Карточка нутриентов ───────────────────────────────────────────────────────

class _NutritionCard extends StatelessWidget {
  final Nutrition nutrition;
  const _NutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Калории крупно по центру
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${nutrition.calories}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepBeet,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kcal',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Разделитель
          Container(height: 1, color: const Color(0xFFE8DDD6)),
          const SizedBox(height: 14),
          // Три макронутриента
          Row(
            children: [
              _MacroCell(
                label: 'Protein',
                value: nutrition.proteinG,
                unit: 'g',
                color: const Color(0xFF2B6CB0),
                icon: Icons.fitness_center_outlined,
              ),
              _vDivider(),
              _MacroCell(
                label: 'Carbs',
                value: nutrition.carbsG,
                unit: 'g',
                color: const Color(0xFF744210),
                icon: Icons.grain_outlined,
              ),
              _vDivider(),
              _MacroCell(
                label: 'Fat',
                value: nutrition.fatG,
                unit: 'g',
                color: AppColors.dill,
                icon: Icons.water_drop_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 48,
        color: const Color(0xFFE8DDD6),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _MacroCell extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MacroCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value % 1 == 0
                      ? value.toInt().toString()
                      : value.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
