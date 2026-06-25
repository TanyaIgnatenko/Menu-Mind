import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/hot_dish_mark.dart';

/// Launch splash — the branded animation from the Hot Dish brand page.
///
/// The Hot Dish mark appears immediately (no entrance bounce) and gently floats
/// up and down — that float is driven by `flutter_animate`. Everything else is
/// hand-rolled: the wordmark and tagline rise, four language pills rise into
/// place with fixed tilts, and loading dots pulse left→right; then it fades into
/// the app shell. One entry controller (3000ms) drives the entrances; a separate
/// loop controller drives the dot pulse.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entry; // staggered entrance (3000ms)
  late final AnimationController _dotLoop; // loading-dot pulse

  late final Animation<double> _wordOpacity;
  late final Animation<double> _wordSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _dotsAppear;
  late final List<Animation<double>> _pillRise;
  late final List<Animation<double>> _pillFade;

  static const _markSize = 120.0;
  static const _entryMs = 3000.0;

  // Loading-dot timing — see _run() for how this sets the splash length.
  static const _dotsAppearMs = 2450;
  static const _dotPeriodMs = 1300;
  // Total splash length (entry start → navigate). Target ~4.6s.
  static const _totalSplashMs = 5000;

  // Orange glow, exactly per spec: drop-shadow(0 18px 36px rgba(240,90,40,.42)).
  // Cast by the mark's ~22% squircle so it follows the icon silhouette.
  static const _glow = [
    BoxShadow(color: Color(0x6BF05A28), blurRadius: 36, offset: Offset(0, 18)),
  ];

  static const _pills = <_PillSpec>[
    _PillSpec('日本語', Alignment(-0.76, -0.42), -9, 13, 1650),
    _PillSpec('한국어', Alignment(0.80, -0.48), 8, 13, 1800),
    _PillSpec('العربية', Alignment(-0.60, 0.16), 6, 12, 1950),
    _PillSpec('中文', Alignment(0.66, 0.10), -8, 12, 2100),
  ];

  // Build an Interval from absolute start/duration in milliseconds.
  Interval _at(double startMs, double durMs) =>
      Interval(startMs / _entryMs, ((startMs + durMs) / _entryMs).clamp(0.0, 1.0));

  @override
  void initState() {
    super.initState();

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // (The icon has no entrance animation — it's present from the first frame
    // and only floats, via flutter_animate in build().)

    // Wordmark + tagline rise (hb-up): translateY 18px → 0 + fade, 550ms.
    _wordSlide = Tween<double>(begin: 18, end: 0)
        .animate(CurvedAnimation(parent: _entry, curve: _at(950, 550).withCurve(Curves.easeOut)));
    _wordOpacity = CurvedAnimation(parent: _entry, curve: _at(950, 400));
    _taglineSlide = Tween<double>(begin: 18, end: 0)
        .animate(CurvedAnimation(parent: _entry, curve: _at(1380, 550).withCurve(Curves.easeOut)));
    _taglineOpacity = CurvedAnimation(parent: _entry, curve: _at(1380, 400));

    // Pills rise (hb-up): translateY 16px → 0 + fade, staggered, fixed tilt.
    _pillRise = [
      for (final p in _pills)
        Tween<double>(begin: 16, end: 0)
            .animate(CurvedAnimation(parent: _entry, curve: _at(p.delayMs, 500).withCurve(Curves.easeOut))),
    ];
    _pillFade = [
      for (final p in _pills) CurvedAnimation(parent: _entry, curve: _at(p.delayMs, 380)),
    ];

    // Dots container fades in at 2.45s.
    _dotsAppear = CurvedAnimation(parent: _entry, curve: _at(_dotsAppearMs.toDouble(), 350));

    _dotLoop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _dotPeriodMs),
    );

    _run();
  }

  Future<void> _run() async {
    // Start the choreography on the first rendered frame so the bounce is seen.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _dotLoop.repeat();
    await _entry.forward();
    if (!mounted) return;
    // Hold until the total splash length is reached, then leave.
    final holdMs = (_totalSplashMs - _entryMs).round();
    if (holdMs > 0) await Future.delayed(Duration(milliseconds: holdMs));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AppShell(key: appShellKey),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _dotLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Language pills rise into place around the mark.
          for (var i = 0; i < _pills.length; i++)
            _LangPill(spec: _pills[i], rise: _pillRise[i], fade: _pillFade[i]),

          // Mark: present immediately, gently floats up/down (flutter_animate).
          Center(
            child: const HotDishMark(size: _markSize, shadows: _glow)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -9, duration: 1600.ms, curve: Curves.easeInOut),
          ),

          // Wordmark + tagline rise and fade in below the mark.
          Center(
            child: Transform.translate(
              offset: const Offset(0, _markSize / 2 + 56),
              child: AnimatedBuilder(
                animation: _entry,
                builder: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _wordOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _wordSlide.value),
                        child: const Text(
                          'MenuMind',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.04 * 36,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: _taglineOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _taglineSlide.value),
                        child: const Text(
                          'Read any menu. Anywhere.',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pulsing loading dots near the bottom (wave travels left → right).
          Positioned(
            left: 0,
            right: 0,
            bottom: 104,
            child: AnimatedBuilder(
              animation: Listenable.merge([_entry, _dotLoop]),
              builder: (_, __) => Opacity(
                opacity: _dotsAppear.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    // 150ms stagger (150/1300 ≈ 0.115); subtract so the leftmost
                    // dot leads and the pulse travels left → right.
                    final phase = (_dotLoop.value - i * 0.115) % 1.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.scale(
                        scale: _dotScale(phase),
                        child: Opacity(
                          opacity: _dotOpacity(phase),
                          child: const SizedBox(
                            width: 9,
                            height: 9,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // mm-dot: rest scale .55 / opacity .25, peaking 1.1 / 1.0 at ~35% of the cycle,
  // holding the resting state across 70%–100% so the wave stays crisp.
  double _dotPulse(double t) {
    if (t >= 0.7) return 0.0;
    final x = t < 0.35 ? t / 0.35 : 1 - (t - 0.35) / 0.35;
    return Curves.easeInOut.transform(x.clamp(0.0, 1.0));
  }

  double _dotScale(double t) => 0.55 + 0.55 * _dotPulse(t);
  double _dotOpacity(double t) => 0.25 + 0.75 * _dotPulse(t);
}

class _PillSpec {
  final String text;
  final Alignment align;
  final double rotationDeg;
  final double fontSize;
  final double delayMs; // entry start delay
  const _PillSpec(this.text, this.align, this.rotationDeg, this.fontSize, this.delayMs);
}

class _LangPill extends StatelessWidget {
  final _PillSpec spec;
  final Animation<double> rise;
  final Animation<double> fade;
  const _LangPill({required this.spec, required this.rise, required this.fade});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: spec.align,
      child: AnimatedBuilder(
        animation: Listenable.merge([rise, fade]),
        builder: (_, child) => Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, rise.value), child: child),
        ),
        child: Transform.rotate(
          angle: spec.rotationDeg * math.pi / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(color: Color(0x1C000000), blurRadius: 18, offset: Offset(0, 4)),
              ],
            ),
            child: Text(
              spec.text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: spec.fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compose a curve onto an [Interval] (the interval gates timing, the curve
/// shapes the eased value within it).
extension on Interval {
  Interval withCurve(Curve curve) => Interval(begin, end, curve: curve);
}
