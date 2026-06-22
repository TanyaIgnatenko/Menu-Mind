import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'menumind',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.beet,
                height: 1,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _DillLeaf(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Eat with confidence, anywhere in the world.',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DillLeaf extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 14),
      painter: _LeafPainter(),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dill
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.5, size.height * 0.1,
        size.width * 0.95, size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.7, size.height * 0.85,
        size.width * 0.1, size.height * 0.9,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Прожилка
    final veinPaint = Paint()
      ..color = const Color(0xFFF6EFE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final vein = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.55, size.height * 0.45,
        size.width * 0.85, size.height * 0.2,
      );

    canvas.drawPath(vein, veinPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
