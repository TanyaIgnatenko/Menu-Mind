import 'package:flutter/material.dart';
import '../models/menu.dart';
import '../services/analytics.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/dish_screen.dart';
import 'dish_image.dart';
import 'diet_chip.dart';

/// A single dish row in the categorized menu list.
class DishCard extends StatelessWidget {
  final Dish dish;
  final ApiService api;

  /// Menu identity + this dish's index, so the dish screen can keep polling for
  /// the enrichment pass (about + nutrition) that may still be in flight.
  final String menuId;
  final int index;

  /// Whether the menu was already fully processed when this card was built —
  /// tells the dish screen not to wait for enrichment that is never coming.
  final bool menuSettled;

  const DishCard({
    super.key,
    required this.dish,
    required this.api,
    required this.menuId,
    required this.index,
    required this.menuSettled,
  });

  @override
  Widget build(BuildContext context) {
    final name = dish.nameEnglish.isNotEmpty ? dish.nameEnglish : dish.nameOriginal;
    final showOriginal = dish.nameOriginal.isNotEmpty && dish.nameOriginal != name;
    final chips = _topChips();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Analytics.capture('dish_opened', {'dish_name': name});
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DishScreen(
                  dish: dish,
                  api: api,
                  menuId: menuId,
                  dishIndex: index,
                  menuSettled: menuSettled,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: DishImage(dish: dish, api: api),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle,
                      ),
                      if (showOriginal) ...[
                        const SizedBox(height: 2),
                        Text(
                          dish.nameOriginal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.original,
                        ),
                      ],
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: chips.map((t) => DietChip(t, small: true)).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (dish.price.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(dish.price, style: AppText.price),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Up to three chips: only appetising/neutral tags (positives first, then
  /// cautions). Allergen ⚠ are intentionally NOT shown on cards — unsafe dishes
  /// are removed by the dietary filters, and the full allergen list lives on the
  /// dish detail page. This keeps the menu from becoming a wall of red.
  List<DietTag> _topChips() {
    final tags = dish.dietaryTags.map(describeTag).whereType<DietTag>().toList();
    final positive = tags.where((t) => t.kind == ChipKind.positive);
    final caution = tags.where((t) => t.kind == ChipKind.caution);
    return [...positive, ...caution].take(3).toList();
  }
}
