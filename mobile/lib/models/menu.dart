class Nutrition {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const Nutrition({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      );
}

class Dish {
  final String nameOriginal;
  final String nameEnglish;
  final String descriptionOriginal;
  final String descriptionEnglish;
  final String category;
  final String categoryEnglish;
  final String price;
  final String imageStatus; // pending, generating, ready, failed
  final String? imageUrl;
  final List<String> dietaryTags;
  final List<String> funFacts;
  final Nutrition? nutrition;

  const Dish({
    required this.nameOriginal,
    required this.nameEnglish,
    required this.descriptionOriginal,
    required this.descriptionEnglish,
    required this.category,
    required this.categoryEnglish,
    required this.price,
    required this.imageStatus,
    this.imageUrl,
    this.dietaryTags = const [],
    this.funFacts = const [],
    this.nutrition,
  });

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        nameOriginal: json['name_original'] ?? '',
        nameEnglish: json['name_english'] ?? '',
        descriptionOriginal: json['description_original'] ?? '',
        descriptionEnglish: json['description_english'] ?? '',
        category: json['category'] ?? '',
        categoryEnglish: json['category_english'] ?? '',
        price: json['price'] ?? '',
        imageStatus: json['image_status'] ?? 'pending',
        imageUrl: json['image_url'],
        dietaryTags: List<String>.from(json['dietary_tags'] ?? []),
        funFacts: List<String>.from(json['fun_facts'] ?? []),
        nutrition: json['nutrition'] != null
            ? Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
            : null,
      );

  bool get imageReady => imageStatus == 'ready' && imageUrl != null && imageUrl!.isNotEmpty;
  bool get imagePending => imageStatus == 'pending' || imageStatus == 'generating';
}

class Menu {
  final String id;
  final String sourceLanguage;
  final String? restaurantName;
  final String? cuisineType;
  final List<Dish> dishes;
  final DateTime createdAt;

  const Menu({
    required this.id,
    required this.sourceLanguage,
    this.restaurantName,
    this.cuisineType,
    required this.dishes,
    required this.createdAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        id: json['id'],
        sourceLanguage: json['source_language'] ?? 'unknown',
        restaurantName: json['restaurant_name'],
        cuisineType: json['cuisine_type'],
        dishes: (json['dishes'] as List? ?? [])
            .map((d) => Dish.fromJson(d))
            .toList(),
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );

  bool get allImagesResolved =>
      dishes.every((d) => d.imageStatus == 'ready' || d.imageStatus == 'failed');

  String get autoName {
    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return restaurantName!;
    }
    if (cuisineType != null && cuisineType!.isNotEmpty) {
      return '${cuisineType!} menu';
    }
    return 'Menu';
  }
}

class HistoryEntry {
  final String id;
  final String displayName;
  final int dishCount;
  final DateTime savedAt;
  /// Локальный путь к фото меню которое загрузил пользователь
  final String? menuPhotoPath;
  String? customName;

  HistoryEntry({
    required this.id,
    required this.displayName,
    required this.dishCount,
    required this.savedAt,
    this.menuPhotoPath,
    this.customName,
  });

  String get title => customName?.isNotEmpty == true ? customName! : displayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'dishCount': dishCount,
        'savedAt': savedAt.toIso8601String(),
        'menuPhotoPath': menuPhotoPath,
        'customName': customName,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'],
        displayName: json['displayName'] ?? 'Menu',
        dishCount: json['dishCount'] ?? 0,
        savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
        menuPhotoPath: json['menuPhotoPath'],
        customName: json['customName'],
      );
}
