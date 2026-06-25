import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/menu.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/history_service.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/screens/scan_screen.dart';
import 'package:mobile/screens/menu_screen.dart';
import 'package:mobile/screens/dish_screen.dart';
import 'package:mobile/screens/history_screen.dart';
import 'package:mobile/screens/loading_view.dart';
import 'package:mobile/widgets/stripe_placeholder.dart';

Future<void> _loadFonts() async {
  for (final path in [
    'assets/fonts/PlusJakartaSans.ttf',
    'assets/fonts/PlusJakartaSans-Italic.ttf',
  ]) {
    final bytes = await File(path).readAsBytes();
    final loader = FontLoader('Plus Jakarta Sans')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

Dish _dish({
  required String en,
  required String orig,
  required String price,
  required String cat,
  List<String> tags = const [],
  String about = '',
  Nutrition? nutrition,
}) =>
    Dish(
      nameOriginal: orig,
      nameEnglish: en,
      descriptionOriginal: '',
      descriptionEnglish: 'A short, appetizing description of the dish.',
      category: cat,
      categoryEnglish: cat,
      price: price,
      imageStatus: 'failed', // stripe placeholder, no network
      dietaryTags: tags,
      about: about,
      nutrition: nutrition,
    );

Menu _sampleMenu() => Menu(
      id: 'demo',
      sourceLanguage: 'it',
      restaurantName: 'La Bella Italia',
      cuisineType: 'Italian',
      createdAt: DateTime(2026, 6, 20),
      dishes: [
        _dish(en: 'Bruschetta al Pomodoro', orig: 'ブルスケッタ ポモドーロ', price: '€6.50', cat: 'Antipasti', tags: ['vegetarian', 'vegan']),
        _dish(en: 'Carpaccio di Manzo', orig: '牛肉のカルパッチョ', price: '€12.00', cat: 'Antipasti', tags: ['contains_gluten']),
        _dish(en: 'Spaghetti Carbonara', orig: 'スパゲッティ カルボナーラ', price: '€14.50', cat: 'Primi Piatti', tags: ['contains_egg', 'contains_dairy', 'contains_gluten']),
        _dish(en: 'Risotto ai Funghi', orig: 'マッシュルームリゾット', price: '€15.00', cat: 'Primi Piatti', tags: ['vegetarian']),
      ],
    );

Future<void> _shoot(WidgetTester tester, Widget child, String name,
    {Duration settle = const Duration(milliseconds: 300)}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.theme,
    debugShowCheckedModeBanner: false,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(top: 47, bottom: 34)),
      child: child,
    ),
  ));
  await tester.pump(settle);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('scan', (t) async {
    await _shoot(t, const ScanScreen(), 'scan');
  });

  testWidgets('history_empty', (t) async {
    await _shoot(t, const HistoryScreen(), 'history_empty');
  });

  testWidgets('loading', (t) async {
    // Pump past the 1s pulse-start timer so no Timer is left pending.
    await _shoot(t, const LoadingView(stageIndex: 1, dishCount: 24), 'loading',
        settle: const Duration(milliseconds: 1100));
  });

  testWidgets('placeholders', (t) async {
    await _shoot(
      t,
      const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: GeneratingPlaceholder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: GeneratingPlaceholder(),
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: FailedPlaceholder(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      'placeholders',
    );
  });

  testWidgets('menu', (t) async {
    await _shoot(t, MenuScreen(menu: _sampleMenu(), api: ApiService(), history: HistoryService()), 'menu');
  });

  testWidgets('dish', (t) async {
    final dish = _dish(
      en: 'Spaghetti Carbonara',
      orig: 'スパゲッティ カルボナーラ',
      price: '€14.50',
      cat: 'Primi Piatti',
      tags: ['contains_gluten', 'contains_egg', 'contains_dairy', 'nut_free', 'shellfish_free'],
      about: 'A classic Roman pasta made with eggs, Pecorino Romano, guanciale, and black pepper. Silky, rich, and deeply savory.',
      nutrition: const Nutrition(calories: 580, proteinG: 28, carbsG: 64, fatG: 22),
    );
    await _shoot(t, DishScreen(dish: dish, api: ApiService()), 'dish');
  });
}
