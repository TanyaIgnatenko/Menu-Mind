import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';

/// Splash screen — логотип появляется с bounce анимацией (1.5 сек),
/// затем плавно переходит на AppShell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Контроллеры ───────────────────────────────────────────────────────────
  late final AnimationController _bounceCtrl;
  late final AnimationController _fadeCtrl;

  // ── Анимации ──────────────────────────────────────────────────────────────
  late final Animation<double> _translateY; // подъём вилки
  late final Animation<double> _opacity;    // появление логотипа
  late final Animation<double> _taglineOpacity; // слоган появляется позже

  @override
  void initState() {
    super.initState();

    // Bounce — 900ms, такой же ритм как у трёх точек
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Fade out убран — мгновенный переход
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: Duration.zero,
    );

    // translateY: начинает снизу (+40px), поднимается до -6px (перелёт),
    // возвращается на 0 — классический bounce
    _translateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 40.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_bounceCtrl);

    // Логотип появляется в первые 50% bounce
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Слоган появляется в конце bounce
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceCtrl,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // exitFade убран — переход без затухания

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Небольшая пауза перед стартом
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Bounce анимация логотипа
    await _bounceCtrl.forward();
    if (!mounted) return;

    // Держим логотип 2500ms
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Fade out и переход
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AppShell(key: appShellKey),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceCtrl, _fadeCtrl]),
      builder: (_, __) => Scaffold(
          backgroundColor: AppColors.cream,
          body: Center(
            child: Transform.translate(
              offset: Offset(0, _translateY.value),
              child: Opacity(
                opacity: _opacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Иконка — вилка + строки (упрощённая версия логотипа)
                    _SplashIcon(),
                    const SizedBox(height: 20),
                    // Wordmark
                    const Text(
                      'menumind',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.beet,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Слоган появляется с задержкой
                    Opacity(
                      opacity: _taglineOpacity.value,
                      child: const Text(
                        'Eat with confidence, anywhere in the world.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }
}

/// Мини-версия иконки E для splash
class _SplashIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.beet,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.beet.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(painter: _IconPainter()),
    );
  }
}

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cream = const Color(0xFFF6EFE7);
    final dillGreen = const Color(0xFF5E7D4A);
    final creamMuted = cream.withOpacity(0.70);
    final creamFaint = cream.withOpacity(0.45);

    final thinePaint = Paint()
      ..color = cream
      ..strokeWidth = size.width * 0.046
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ── 4 зубца ──────────────────────────────────────────────────────
    final tineXs = [0.185, 0.275, 0.365, 0.455];
    final tineTop = size.height * 0.12;
    final tineMid = size.height * 0.34;

    for (final x in tineXs) {
      canvas.drawLine(
        Offset(size.width * x, tineTop),
        Offset(size.width * x, tineMid),
        thinePaint,
      );
    }

    // ── Поперечина (bridge) ──────────────────────────────────────────
    final bridgePath = Path()
      ..moveTo(size.width * 0.185, tineMid)
      ..quadraticBezierTo(
        size.width * 0.185, size.height * 0.44,
        size.width * 0.320, size.height * 0.46,
      )
      ..quadraticBezierTo(
        size.width * 0.455, size.height * 0.44,
        size.width * 0.455, tineMid,
      );
    canvas.drawPath(bridgePath, thinePaint);

    // ── Ручка ────────────────────────────────────────────────────────
    final handlePaint = Paint()
      ..color = cream
      ..strokeWidth = size.width * 0.054
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.320, size.height * 0.46),
      Offset(size.width * 0.320, size.height * 0.83),
      handlePaint,
    );

    // ── Строки меню ──────────────────────────────────────────────────
    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.068;

    linePaint.color = cream;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.22),
      Offset(size.width * 0.88, size.height * 0.22),
      linePaint,
    );

    linePaint.color = creamMuted;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.40),
      Offset(size.width * 0.84, size.height * 0.40),
      linePaint,
    );

    linePaint.color = creamFaint;
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.58),
      Offset(size.width * 0.80, size.height * 0.58),
      linePaint,
    );

    // ── Листик укропа ────────────────────────────────────────────────
    final leafPaint = Paint()
      ..color = dillGreen
      ..style = PaintingStyle.fill;

    final leafPath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.65, size.height * 0.68,
        size.width * 0.88, size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.78, size.height * 0.90,
        size.width * 0.50, size.height * 0.80,
      )
      ..close();
    canvas.drawPath(leafPath, leafPaint);

    // Прожилка листика
    final veinPaint = Paint()
      ..color = cream.withOpacity(0.40)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final veinPath = Path()
      ..moveTo(size.width * 0.52, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.68, size.height * 0.72,
        size.width * 0.86, size.height * 0.76,
      );
    canvas.drawPath(veinPath, veinPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
