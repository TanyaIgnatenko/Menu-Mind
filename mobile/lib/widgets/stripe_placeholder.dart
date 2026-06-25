import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Diagonal-stripe placeholder standing in for an AI-generated food photo
/// (matches the `repeating-linear-gradient(135deg, …)` mocks in the handoff).
class StripePlaceholder extends StatelessWidget {
  final Color stripeA;
  final Color stripeB;

  /// Optional centered label, e.g. "AI:\nBruschetta" on thumbnails.
  final Widget? child;

  const StripePlaceholder({
    super.key,
    this.stripeA = const Color(0xFFFEE5C2),
    this.stripeB = const Color(0xFFF5D4A8),
    this.child,
  });

  /// Warmer pasta/neutral tone used for primi & hero shots.
  const StripePlaceholder.warm({super.key, this.child})
      : stripeA = const Color(0xFFFFF0DC),
        stripeB = const Color(0xFFF5E4C0);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StripePainter(stripeA, stripeB),
      child: child == null ? null : Center(child: child),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color a;
  final Color b;
  const _StripePainter(this.a, this.b);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);

    // 135° stripes: 4px band of B every 8px, drawn perpendicular to the diagonal.
    final paint = Paint()
      ..color = b
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const step = 8.0;
    final diag = size.width + size.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double d = -size.height; d < diag; d += step) {
      // Lines going down-right (135° banding).
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) =>
      old.a != a || old.b != b;
}

/// Placeholder shown while a dish photo is being AI-generated: a warm sand block
/// with a white shimmer band sweeping across it (the "loading" cue).
///
/// Matches the CSS spec — base #F3E7D8, white highlight, ~100° band, 1.6s linear
/// loop — via the `shimmer` package (a ShaderMask sliding a gradient, GPU-cheap).
class GeneratingPlaceholder extends StatelessWidget {
  const GeneratingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: const Duration(milliseconds: 1600),
      baseColor: const Color(0xFFF3E7D8),
      highlightColor: Colors.white,
      // Opaque fill for the shimmer's ShaderMask to sweep over; corners are
      // clipped by the caller (list thumb ClipRRect / hero is full-bleed).
      child: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
    );
  }
}

/// Placeholder shown when generation failed (or there's no photo): the same warm
/// sand block, static (no shimmer, so it clearly reads as "not loading"), with a
/// muted "no photo" icon.
class FailedPlaceholder extends StatelessWidget {
  final bool large;
  const FailedPlaceholder({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3E7D8),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: large ? 40 : 24,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
