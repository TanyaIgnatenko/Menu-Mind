import 'package:flutter/material.dart';

/// Camera glyph per the brand spec: a [color] body with the lens drawn as a
/// transparent HOLE (even-odd fill), so the surface behind it (e.g. the orange
/// tile/button) shows through the aperture — instead of the lens being filled
/// white like the Material camera icon.
///
/// Path data taken from the handoff SVG (24×24 viewBox).
class CameraGlyph extends StatelessWidget {
  final double size;
  final Color color;

  const CameraGlyph({super.key, this.size = 20, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    // Center + SizedBox so the glyph keeps [size] even when the parent imposes
    // tight constraints (e.g. a fixed-size Container with no alignment), instead
    // of stretching to fill the box.
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CameraPainter(color)),
      ),
    );
  }
}

class _CameraPainter extends CustomPainter {
  final Color color;
  const _CameraPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0);

    final path = Path()..fillType = PathFillType.evenOdd;

    // Camera body (with the top viewfinder bump).
    path
      ..moveTo(9, 2)
      ..lineTo(7.17, 4)
      ..lineTo(4, 4)
      ..cubicTo(2.9, 4, 2, 4.9, 2, 6)
      ..lineTo(2, 18)
      ..cubicTo(2, 19.1, 2.9, 20, 4, 20)
      ..lineTo(20, 20)
      ..cubicTo(21.1, 20, 22, 19.1, 22, 18)
      ..lineTo(22, 6)
      ..cubicTo(22, 4.9, 21.1, 4, 20, 4)
      ..lineTo(16.83, 4)
      ..lineTo(15, 2)
      ..close();

    // Lens — a hole, so the background colour shows through (orange aperture).
    path
      ..moveTo(12, 17)
      ..cubicTo(9.24, 17, 7, 14.76, 7, 12)
      ..cubicTo(7, 9.24, 9.24, 7, 12, 7)
      ..cubicTo(14.76, 7, 17, 9.24, 17, 12)
      ..cubicTo(17, 14.76, 14.76, 17, 12, 17)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CameraPainter old) => old.color != color;
}
