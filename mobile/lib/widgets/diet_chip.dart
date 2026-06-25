import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ChipKind { positive, allergen, caution, category }

/// A normalized dietary tag ready for display.
class DietTag {
  final String label;
  final ChipKind kind;
  final bool warn; // prefix a ⚠ marker
  const DietTag(this.label, this.kind, {this.warn = false});
}

/// Maps a raw `dietary_tags` string to a display tag, or null if unknown.
DietTag? describeTag(String tag) {
  switch (tag) {
    case 'vegetarian':
      return const DietTag('Vegetarian', ChipKind.positive);
    case 'vegan':
      return const DietTag('Vegan', ChipKind.positive);
    case 'pescatarian':
      return const DietTag('Pescatarian', ChipKind.positive);
    case 'halal':
      return const DietTag('Halal', ChipKind.positive);
    case 'kosher':
      return const DietTag('Kosher', ChipKind.positive);
    case 'gluten_free':
      return const DietTag('Gluten-free', ChipKind.caution);
    case 'nut_free':
      return const DietTag('Nut-free', ChipKind.positive);
    case 'dairy_free':
      return const DietTag('Dairy-free', ChipKind.positive);
    case 'shellfish_free':
      return const DietTag('Shellfish-free', ChipKind.positive);
    case 'spicy':
      return const DietTag('Spicy', ChipKind.caution);
    case 'sweet':
      return const DietTag('Sweet', ChipKind.caution);
    case 'contains_gluten':
      return const DietTag('Gluten', ChipKind.allergen, warn: true);
    case 'contains_dairy':
      return const DietTag('Dairy', ChipKind.allergen, warn: true);
    case 'contains_egg':
    case 'contains_eggs':
      return const DietTag('Egg', ChipKind.allergen, warn: true);
    case 'contains_nuts':
      return const DietTag('Nuts', ChipKind.allergen, warn: true);
    case 'contains_peanuts':
      return const DietTag('Peanuts', ChipKind.allergen, warn: true);
    case 'contains_fish':
      return const DietTag('Fish', ChipKind.allergen, warn: true);
    case 'contains_shellfish':
      return const DietTag('Shellfish', ChipKind.allergen, warn: true);
    case 'contains_soy':
      return const DietTag('Soy', ChipKind.allergen, warn: true);
    case 'contains_sesame':
      return const DietTag('Sesame', ChipKind.allergen, warn: true);
    case 'contains_pork':
      return const DietTag('Pork', ChipKind.caution);
    case 'contains_alcohol':
      return const DietTag('Alcohol', ChipKind.caution);
    case 'contains_chicken':
      return const DietTag('Chicken', ChipKind.caution);
    case 'contains_beef':
      return const DietTag('Beef', ChipKind.caution);
    default:
      return null;
  }
}

({Color fg, Color bg}) _colors(ChipKind kind) {
  switch (kind) {
    case ChipKind.positive:
      return (fg: AppColors.success, bg: AppColors.successBg);
    case ChipKind.allergen:
      return (fg: AppColors.allergen, bg: AppColors.allergenBg);
    case ChipKind.caution:
      return (fg: AppColors.caution, bg: AppColors.cautionBg);
    case ChipKind.category:
      return (fg: AppColors.category, bg: AppColors.categoryBg);
  }
}

/// A pill chip for a dietary tag. [small] is the dense list-card variant.
class DietChip extends StatelessWidget {
  final DietTag tag;
  final bool small;
  const DietChip(this.tag, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = _colors(tag.kind);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 11,
        vertical: small ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag.warn ? '⚠ ${tag.label}' : tag.label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: c.fg,
        ),
      ),
    );
  }
}
