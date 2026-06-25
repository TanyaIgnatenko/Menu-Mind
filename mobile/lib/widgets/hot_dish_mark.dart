import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Brand mark asset: the camera + plate + fork/spoon + 文A motif on the Hot Dish
/// gradient, used for the in-app mark (splash, loader, empty-History hero).
const String _kBrandAsset = 'assets/icon/cam_on_gradient.png';

/// The MenuMind brand mark: the camera + plate + fork/spoon + 文A motif on the
/// brand-gradient squircle (rendered from [_kBrandAsset]). Used for the in-app
/// mark on the splash, loader and empty-History hero.
class HotDishMark extends StatelessWidget {
  /// Edge length in logical pixels.
  final double size;

  /// Squircle corner radius as a fraction of [size] (≈224/1024 in the spec).
  final double cornerFraction;

  /// Drop shadow under the mark (used for the empty-History hero).
  final List<BoxShadow> shadows;

  const HotDishMark({
    super.key,
    required this.size,
    this.cornerFraction = 224 / 1024,
    this.shadows = const [],
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * cornerFraction);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(_kBrandAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Draws the Hot Dish mark in the 1024×1024 design space (then scaled to fit).
///
/// Configurable so the in-app mark and the exported launcher-icon variants
/// (full square, gradient-only background, white foreground) share one source.
class HotDishPainter extends CustomPainter {
  final double cornerFraction;

  /// Draw the gradient squircle + radial highlight.
  final bool drawBackground;

  /// Draw the bowl / steam / sparkle / glyphs.
  final bool drawForeground;

  /// Scale of the mark content within the canvas (1.0 = edge-to-edge design).
  /// Used to inset the Android adaptive foreground into its safe zone.
  final double contentScale;

  const HotDishPainter({
    this.cornerFraction = 224 / 1024,
    this.drawBackground = true,
    this.drawForeground = true,
    this.contentScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Everything below is authored in the 1024×1024 design space, then scaled.
    final s = size.width / 1024.0;
    canvas.save();
    canvas.scale(s);

    const side = 1024.0;
    const rect = Rect.fromLTWH(0, 0, side, side);

    if (drawBackground) {
      final squircle = RRect.fromRectAndRadius(
        rect,
        Radius.circular(side * cornerFraction),
      );
      canvas.save();
      canvas.clipRRect(squircle);
      canvas.drawRect(
        rect,
        Paint()..shader = kBrandGradient.createShader(rect),
      );
      // Soft white radial highlight from the top-left.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(300 / 512 - 1, 200 / 512 - 1),
            radius: 540 / 512,
            colors: [Color(0x4DFFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
      );
      canvas.restore();
    }

    if (drawForeground) {
      if (contentScale != 1.0) {
        canvas.translate(side / 2, side / 2);
        canvas.scale(contentScale);
        canvas.translate(-side / 2, -side / 2);
      }

      // Steam — three strokes at x ≈ 430 / 512 / 594.
      final steam = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(_steamPath(430, 300), steam);
      canvas.drawPath(_steamPath(512, 286), steam);
      canvas.drawPath(_steamPath(594, 300), steam);

      // Bowl.
      final bowl = Path()
        ..moveTo(286, 470)
        ..quadraticBezierTo(512, 426, 738, 470)
        ..quadraticBezierTo(706, 686, 512, 700)
        ..quadraticBezierTo(318, 686, 286, 470)
        ..close();
      canvas.drawPath(bowl, Paint()..color = Colors.white);

      // AI sparkle (top-right).
      final sparkle = Path()
        ..moveTo(760, 360)
        ..relativeQuadraticBezierTo(-14, 56, -64, 70)
        ..relativeQuadraticBezierTo(50, 14, 64, 70)
        ..relativeQuadraticBezierTo(14, -56, 64, -70)
        ..relativeQuadraticBezierTo(-50, -14, -64, -70)
        ..close();
      canvas.drawPath(sparkle, Paint()..color = Colors.white);

      // Translation glyphs 文A on the bowl, terracotta.
      _glyph(canvas, '文', 478, 612, 96, FontWeight.w700,
          fallback: const ['PingFang SC', 'Hiragino Sans GB', 'Noto Sans CJK SC', 'Microsoft YaHei']);
      _glyph(canvas, 'A', 566, 604, 74, FontWeight.w800);
    }

    canvas.restore();
  }

  /// `M x y q 36 -34 0 -68 q -36 -34 0 -68` — a single steam curl.
  Path _steamPath(double x, double y) => Path()
    ..moveTo(x, y)
    ..relativeQuadraticBezierTo(36, -34, 0, -68)
    ..relativeQuadraticBezierTo(-36, -34, 0, -68);

  /// Draws a glyph whose [x] is the horizontal center (SVG text-anchor:middle)
  /// and [y] is the alphabetic baseline (SVG text y).
  void _glyph(
    Canvas canvas,
    String char,
    double x,
    double y,
    double fontSize,
    FontWeight weight, {
    List<String>? fallback,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: AppColors.primaryDeep,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamilyFallback: fallback,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(x - tp.width / 2, y - baseline));
  }

  @override
  bool shouldRepaint(covariant HotDishPainter old) =>
      old.drawBackground != drawBackground ||
      old.drawForeground != drawForeground ||
      old.cornerFraction != cornerFraction ||
      old.contentScale != contentScale;
}
