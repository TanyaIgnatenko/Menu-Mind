import 'package:flutter/material.dart';
import '../models/menu.dart';
import '../theme/app_theme.dart';

class FilterDef {
  final String id;
  final String label;
  final List<String> tags;
  final String group; // 'needs' | 'prefs'
  final String mode; // 'require' | 'exclude'

  const FilterDef({
    required this.id,
    required this.label,
    required this.tags,
    required this.group,
    required this.mode,
  });
}

const _filters = [
  // Needs
  FilterDef(id: 'vegetarian', label: 'Vegetarian', tags: ['vegetarian'], group: 'needs', mode: 'require'),
  FilterDef(id: 'vegan', label: 'Vegan', tags: ['vegan'], group: 'needs', mode: 'require'),
  FilterDef(id: 'no_pork', label: 'No pork', tags: ['contains_pork'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_nuts', label: 'No nuts', tags: ['contains_nuts'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_gluten', label: 'No gluten', tags: ['contains_gluten'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_dairy', label: 'No dairy', tags: ['contains_dairy'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_eggs', label: 'No eggs', tags: ['contains_eggs'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_fish', label: 'No fish', tags: ['contains_fish'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_alcohol', label: 'No alcohol', tags: ['contains_alcohol'], group: 'needs', mode: 'exclude'),
  // Prefs
  FilterDef(id: 'spicy', label: 'Spicy', tags: ['spicy'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'sweet', label: 'Sweet', tags: ['sweet'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'chicken', label: 'Chicken', tags: ['contains_chicken'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'beef', label: 'Beef', tags: ['contains_beef'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'seafood', label: 'Seafood', tags: ['contains_fish', 'contains_shellfish'], group: 'prefs', mode: 'require'),
];

List<Dish> filterDishes(List<Dish> dishes, Set<String> activeIds) {
  if (activeIds.isEmpty) return dishes;

  final active = _filters.where((f) => activeIds.contains(f.id)).toList();
  final needs = active.where((f) => f.group == 'needs').toList();
  final prefs = active.where((f) => f.group == 'prefs').toList();

  return dishes.where((dish) {
    // All needs must pass (AND)
    for (final f in needs) {
      if (f.mode == 'require' && !f.tags.any((t) => dish.dietaryTags.contains(t))) return false;
      if (f.mode == 'exclude' && f.tags.any((t) => dish.dietaryTags.contains(t))) return false;
    }
    // At least one pref must match (OR) — if any prefs active
    if (prefs.isNotEmpty) {
      final matches = prefs.any((f) => f.tags.any((t) => dish.dietaryTags.contains(t)));
      if (!matches) return false;
    }
    return true;
  }).toList();
}

class DietaryFilters extends StatelessWidget {
  final List<Dish> dishes;
  final Set<String> active;
  final ValueChanged<String> onToggle;
  final int shownCount;

  const DietaryFilters({
    super.key,
    required this.dishes,
    required this.active,
    required this.onToggle,
    required this.shownCount,
  });

  @override
  Widget build(BuildContext context) {
    // Only show filters that appear in this menu
    final allTags = dishes.expand((d) => d.dietaryTags).toSet();
    final available = _filters.where((f) => f.tags.any((t) => allTags.contains(t))).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    final needs = available.where((f) => f.group == 'needs').toList();
    final prefs = available.where((f) => f.group == 'prefs').toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (needs.isNotEmpty) ...[
              _sectionLabel('DIETARY NEEDS'),
              const SizedBox(height: 8),
              _ChipRow(filters: needs, active: active, onToggle: onToggle, group: 'needs'),
            ],
            if (prefs.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionLabel('SHOW ME'),
              const SizedBox(height: 8),
              _ChipRow(filters: prefs, active: active, onToggle: onToggle, group: 'prefs'),
            ],
            if (active.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Showing $shownCount of ${dishes.length} dishes',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.beet,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Tags are AI-generated and may be inaccurate. Always verify allergens with the restaurant.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      );
}

class _ChipRow extends StatelessWidget {
  final List<FilterDef> filters;
  final Set<String> active;
  final ValueChanged<String> onToggle;
  final String group;

  const _ChipRow({
    required this.filters,
    required this.active,
    required this.onToggle,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: filters.map((f) {
        final isActive = active.contains(f.id);
        final activeColor = group == 'needs' ? AppColors.beet : AppColors.dill;
        return GestureDetector(
          onTap: () => onToggle(f.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? activeColor : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? activeColor : AppColors.chipInactiveBorder,
              ),
            ),
            child: Text(
              f.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.white : AppColors.deepBeet,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
