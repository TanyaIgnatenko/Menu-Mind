import 'package:flutter/material.dart';

/// Design tokens for the "Hot Dish" brand — see design_handoff_menumind/README.md.
class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const primary = Color(0xFFF05A28); // brand orange
  static const primaryDeep = Color(0xFFC03010); // gradient end / pressed
  static const primaryPeach = Color(0xFFFFD098); // gradient start / highlights
  static const primaryTintBg = Color(0xFFFFF3EE); // light orange pill bg

  // ── Text ───────────────────────────────────────────────────────────────────
  static const ink = Color(0xFF1A1008); // primary text
  static const body = Color(0xFF7A6858); // secondary / body
  static const muted = Color(0xFFB5A090); // tertiary / metadata
  static const muted2 = Color(0xFF9A8878); // captions

  // ── Surfaces ─────────────────────────────────────────────────────────────────
  static const canvas = Color(0xFFFFFBF7); // app background
  static const canvasAlt = Color(0xFFF2EDE5);
  static const surface = Color(0xFFFFFFFF); // cards
  static const border = Color(0xFFEDE3D8); // card & divider borders
  static const divider = Color(0xFFF0E8DF); // hairline dividers inside cards
  static const fillWarm = Color(0xFFF5EFE8); // neutral icon-button fills
  static const fillWarm2 = Color(0xFFF5E8D5); // skeleton / warmer fill

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const success = Color(0xFF27AE72); // vegetarian/vegan, safe
  static const successBg = Color(0xFFEDFBF4);
  static const caution = Color(0xFFD4870A); // gluten-free, carbs
  static const cautionBg = Color(0xFFFFF8EC);
  static const allergen = Color(0xFFE5332A); // allergen warnings
  static const allergenBg = Color(0xFFFFF0EF);
  static const category = Color(0xFF7B5EA7); // dish category, fat macro
  static const categoryBg = Color(0xFFF2EEFB);

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static const cardShadow = Color(0x14000000); // 0,0,0 @ .08 — resting cards
  static const floatShadow = Color(0x24000000); // 0,0,0 @ .14 — elevated/floating
}

/// Brand gradient used on the Hot Dish mark (top-left → bottom-right).
const kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primaryPeach, AppColors.primary, AppColors.primaryDeep],
  stops: [0.0, 0.52, 1.0],
);

class AppTheme {
  static const fontFamily = 'Plus Jakarta Sans';

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: fontFamily,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
        fontFamily: fontFamily,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Reusable text styles mapped to the README type scale.
class AppText {
  static const _f = AppTheme.fontFamily;

  // Display H1 (Scan hero): 40–46 / 800 / -0.04em / lh 1.02
  static const hero = TextStyle(
    fontFamily: _f,
    fontSize: 46,
    fontWeight: FontWeight.w800,
    height: 1.02,
    letterSpacing: -0.04 * 46,
    color: AppColors.ink,
  );

  // Screen title (History "Your Scans"): 28 / 800 / -0.035em
  static const screenTitle = TextStyle(
    fontFamily: _f,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.035 * 28,
    color: AppColors.ink,
  );

  // Dish name (detail): 26 / 800 / -0.025em
  static const dishTitle = TextStyle(
    fontFamily: _f,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.025 * 26,
    color: AppColors.ink,
  );

  // Section / screen header: 17–20 / 800 / -0.02em
  static const header = TextStyle(
    fontFamily: _f,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.02 * 17,
    color: AppColors.ink,
  );

  // Card title (dish/menu name): 14–15 / 700
  static const cardTitle = TextStyle(
    fontFamily: _f,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Body: 13–15 / 400–500 / lh 1.6
  static const body = TextStyle(
    fontFamily: _f,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.body,
  );

  static const bodySmall = TextStyle(
    fontFamily: _f,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.body,
  );

  // Original-language subtitle: 11 / 400 italic (muted)
  static const original = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.muted,
  );

  // Metadata / captions: 11–12 / 500–600 (muted)
  static const meta = TextStyle(
    fontFamily: _f,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  // Eyebrow / label: 10–11 / 700 / uppercase / +0.06–0.07em
  static const eyebrow = TextStyle(
    fontFamily: _f,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.07 * 11,
    color: AppColors.muted,
  );

  // Price (lists): 14 / 700
  static const price = TextStyle(
    fontFamily: _f,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Price (detail): 24 / 800 / primary
  static const priceLarge = TextStyle(
    fontFamily: _f,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.03 * 24,
    color: AppColors.primary,
  );
}
