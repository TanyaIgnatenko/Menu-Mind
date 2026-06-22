import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/dish_screen.dart';

class DishCard extends StatelessWidget {
  final Dish dish;
  final ApiService api;

  const DishCard({super.key, required this.dish, required this.api});

  void _openPhoto(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoViewer(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DishScreen(dish: dish, api: api),
        ),
      ),
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото блюда
          GestureDetector(
            onTap: dish.imageReady ? () => _openPhoto(context, api.imageUrl(dish.imageUrl!)) : null,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _buildImage(),
              ),
            ),
          ),
          // Информация
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        dish.nameOriginal,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBeet,
                        ),
                      ),
                    ),
                    if (dish.price.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const _PriceDots(),
                      const SizedBox(width: 8),
                      Text(
                        dish.price,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBeet,
                        ),
                      ),
                    ],
                  ],
                ),
                if (dish.nameEnglish.isNotEmpty && dish.nameEnglish != dish.nameOriginal) ...[
                  const SizedBox(height: 2),
                  Text(
                    dish.nameEnglish,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (dish.descriptionEnglish.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    dish.descriptionEnglish,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Color(0xFF3D3D3D),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildImage() {
    if (dish.imageReady) {
      return CachedNetworkImage(
        imageUrl: api.imageUrl(dish.imageUrl!),
        fit: BoxFit.cover,
        placeholder: (_, __) => _shimmer(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    if (dish.imagePending) return _shimmer();
    return _placeholder();
  }

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: const Color(0xFFEDE5DC),
        highlightColor: const Color(0xFFF6EFE7),
        child: Container(color: const Color(0xFFEDE5DC)),
      );

  Widget _placeholder() => Container(
        color: const Color(0xFFEDE5DC),
        child: const Center(
          child: Icon(Icons.no_food_outlined, color: AppColors.textMuted, size: 32),
        ),
      );
}

class _PriceDots extends StatelessWidget {
  const _PriceDots();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dotChar = '. ';
          const style = TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: AppColors.textMuted,
          );
          final tp = TextPainter(
            text: const TextSpan(text: dotChar, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          final count = (constraints.maxWidth / tp.width).floor();
          return Text(
            dotChar * count,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.clip,
          );
        },
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const CircularProgressIndicator(color: AppColors.beet),
            errorWidget: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
