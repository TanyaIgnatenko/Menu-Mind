import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import 'stripe_placeholder.dart';

/// Renders a dish's AI-generated photo, distinguishing the pipeline state:
/// - generating → shimmering sand placeholder,
/// - failed → static sand placeholder + a muted "no photo" icon,
/// - ready → the photo, cross-faded in.
class DishImage extends StatelessWidget {
  final Dish dish;
  final ApiService api;

  const DishImage({super.key, required this.dish, required this.api});

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (dish.imageReady) {
      content = CachedNetworkImage(
        key: const ValueKey('ready'),
        imageUrl: api.imageUrl(dish.imageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => const GeneratingPlaceholder(),
        errorWidget: (_, __, ___) => const FailedPlaceholder(),
      );
    } else if (dish.imagePending) {
      content = const GeneratingPlaceholder(key: ValueKey('gen'));
    } else {
      content = const FailedPlaceholder(key: ValueKey('failed'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: content,
    );
  }
}
