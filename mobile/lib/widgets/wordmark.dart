import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'camera_glyph.dart';

/// Scan-screen header lockup: a plain camera glyph in a primary rounded square
/// + the "MenuMind" wordmark. Per the spec this in-context "take a photo" cue
/// deliberately uses a camera glyph, NOT the Hot Dish brand mark.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const CameraGlyph(size: 20),
        ),
        const SizedBox(width: 8),
        const Text(
          'MenuMind',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 18,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
