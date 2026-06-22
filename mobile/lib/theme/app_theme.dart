import 'package:flutter/material.dart';

class AppColors {
  // Beet & Cream palette
  static const beet = Color(0xFF8E2A4C);
  static const deepBeet = Color(0xFF5A1C32);
  static const dill = Color(0xFF5E7D4A);
  static const cream = Color(0xFFF6EFE7);
  static const white = Color(0xFFFFFFFF);
  static const cardShadow = Color(0x148E2A4C);

  // Text
  static const textPrimary = Color(0xFF5A1C32);
  static const textSecondary = Color(0xFF9C8474);
  static const textMuted = Color(0xFFBFAFA5);

  // Chips
  static const needsActive = beet;
  static const prefsActive = dill;
  static const chipInactiveBorder = Color(0xFFD4C0B8);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.beet,
          surface: AppColors.cream,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: 'Outfit',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.deepBeet,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.deepBeet,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: AppColors.cardShadow,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.beet,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.beet,
            foregroundColor: AppColors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
