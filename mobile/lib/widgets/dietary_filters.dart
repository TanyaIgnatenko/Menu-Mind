import 'package:flutter/material.dart';
import '../models/menu.dart';
import '../theme/app_theme.dart';

class FilterDef {
  final String id;
  final String label;
  final String emoji;
  final List<String> tags;
  final String group; // 'needs' | 'prefs'
  final String mode; // 'require' | 'exclude'

  const FilterDef({
    required this.id,
    required this.label,
    required this.emoji,
    required this.tags,
    required this.group,
    required this.mode,
  });
}

const _filters = [
  // Restrictions (needs)
  FilterDef(id: 'vegetarian', label: 'Vegetarian', emoji: '🥗', tags: ['vegetarian'], group: 'needs', mode: 'require'),
  FilterDef(id: 'vegan', label: 'Vegan', emoji: '🌱', tags: ['vegan'], group: 'needs', mode: 'require'),
  FilterDef(id: 'no_gluten', label: 'GF', emoji: '🌾', tags: ['contains_gluten'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_pork', label: 'No pork', emoji: '🚫', tags: ['contains_pork'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_nuts', label: 'No nuts', emoji: '🥜', tags: ['contains_nuts'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_dairy', label: 'No dairy', emoji: '🥛', tags: ['contains_dairy'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_eggs', label: 'No eggs', emoji: '🥚', tags: ['contains_eggs'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_fish', label: 'No fish', emoji: '🐟', tags: ['contains_fish'], group: 'needs', mode: 'exclude'),
  FilterDef(id: 'no_alcohol', label: 'No alcohol', emoji: '🍷', tags: ['contains_alcohol'], group: 'needs', mode: 'exclude'),
  // Preferences (prefs)
  FilterDef(id: 'spicy', label: 'Spicy', emoji: '🌶', tags: ['spicy'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'sweet', label: 'Sweet', emoji: '🍰', tags: ['sweet'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'chicken', label: 'Chicken', emoji: '🍗', tags: ['contains_chicken'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'beef', label: 'Beef', emoji: '🥩', tags: ['contains_beef'], group: 'prefs', mode: 'require'),
  FilterDef(id: 'seafood', label: 'Seafood', emoji: '🦐', tags: ['contains_fish', 'contains_shellfish'], group: 'prefs', mode: 'require'),
];

List<Dish> filterDishes(List<Dish> dishes, Set<String> activeIds) {
  if (activeIds.isEmpty) return dishes;

  final active = _filters.where((f) => activeIds.contains(f.id)).toList();
  final needs = active.where((f) => f.group == 'needs').toList();
  final prefs = active.where((f) => f.group == 'prefs').toList();

  return dishes.where((dish) {
    // All restrictions must pass (AND).
    for (final f in needs) {
      if (f.mode == 'require' && !f.tags.any((t) => dish.dietaryTags.contains(t))) return false;
      if (f.mode == 'exclude' && f.tags.any((t) => dish.dietaryTags.contains(t))) return false;
    }
    // At least one active preference must match (OR).
    if (prefs.isNotEmpty) {
      final matches = prefs.any((f) => f.tags.any((t) => dish.dietaryTags.contains(t)));
      if (!matches) return false;
    }
    return true;
  }).toList();
}

/// Horizontal scroll row of dietary filter chips. Selected chips are
/// success-filled; only filters present in this menu are shown.
class DietaryFilters extends StatelessWidget {
  final List<Dish> dishes;
  final Set<String> active;
  final ValueChanged<String> onToggle;

  const DietaryFilters({
    super.key,
    required this.dishes,
    required this.active,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final allTags = dishes.expand((d) => d.dietaryTags).toSet();
    final available = _filters.where((f) => f.tags.any((t) => allTags.contains(t))).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: available.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final f = available[i];
          return _Chip(
            filter: f,
            selected: active.contains(f.id),
            onTap: () => onToggle(f.id),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final FilterDef filter;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.filter, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.successBg : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.success : AppColors.border,
            width: selected ? 1 : 1.5,
          ),
        ),
        child: Text(
          '${filter.emoji} ${filter.label}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.success : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
