import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/hot_dish_mark.dart';

/// Branded full-screen loader shown while a menu is processed. Four dishes orbit
/// the Hot Dish mark (the metaphor for dishes being pulled out of the menu) while
/// the progress bar advances and the caption swaps per stage.
///
/// Pure Flutter (controllers + AnimatedBuilder), per the Hot Dish brand spec:
/// bg fade-in 400ms · orbit 3.4s linear loop · mark pop 700ms easeOutBack then a
/// 1.2s breathe loop (after 1s) · progress fastOutSlowIn.
class LoadingView extends StatefulWidget {
  /// 0 = reading, 1 = translating, 2 = generating, 3 = almost ready.
  final int stageIndex;

  /// Dish count, woven into the translating caption when known.
  final int? dishCount;

  const LoadingView({super.key, required this.stageIndex, this.dishCount});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with TickerProviderStateMixin {
  late final AnimationController _bg; // whole-screen fade-in
  late final AnimationController _orbit; // continuous ring rotation
  late final AnimationController _entry; // center mark pop-in
  late final AnimationController _pulse; // center mark breathing
  late final AnimationController _prog; // progress bar fill

  late final Animation<double> _popScale;
  late final Animation<double> _popOpacity;
  late final Animation<double> _breathe;

  Timer? _pulseTimer;

  // Progress is time-based and asymptotic: it eases toward (but never reaches)
  // [_progressCap], decelerating, so it can't outrun the real (unknown-length)
  // processing and never looks "done" prematurely.
  static const _progressBase = 0.08; // starting fill
  static const _progressCap = 0.90; // asymptote (never completes on screen)
  static const _progressTauSec = 16.0; // time constant — bigger = slower creep
  static const _progressSpanSec = 180.0; // controller span (headroom)

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _orbit = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    // Pop: 0 → 1.18 → 1.0. The overshoot lives in the TweenSequence itself, so
    // the driving curve must stay within [0,1] — easeOutBack would push the
    // sequence's t past 1.0 and trip TweenSequence's `assert(t <= 1.0)`.
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.18), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut));
    _popOpacity = CurvedAnimation(parent: _entry, curve: const Interval(0.0, 0.6));
    _breathe = Tween(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    // Breathe starts 1s after the pop, then loops forever.
    _pulseTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) _pulse.repeat(reverse: true);
    });

    _prog = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 180), // == _progressSpanSec
    )..forward();
  }

  /// Asymptotic fill: base + span·(1 − e^(−t/τ)) — fast at first, then slows,
  /// approaching [_progressCap] without ever reaching it.
  double _progressValue() {
    final elapsed = _prog.value * _progressSpanSec;
    return _progressBase +
        (_progressCap - _progressBase) * (1 - math.exp(-elapsed / _progressTauSec));
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    for (final c in [_bg, _orbit, _entry, _pulse, _prog]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _caption {
    switch (widget.stageIndex) {
      case 0:
        return 'Reading menu…';
      case 1:
        final n = widget.dishCount;
        return n != null ? 'Translating $n dishes…' : 'Translating dishes…';
      case 2:
        return 'Generating photos…';
      default:
        return 'Almost ready…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _bg, curve: Curves.ease),
        child: Stack(
          children: [
            // Soft radial glow behind the orbit (from the design background).
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.16),
                    radius: 0.9,
                    colors: [AppColors.primary.withOpacity(0.07), Colors.transparent],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _orbitMark(),
                  const SizedBox(height: 40),
                  const Text(
                    'Cooking up your menu',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _caption,
                      key: ValueKey(_caption),
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _progressBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orbitMark() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating ring of dishes (they orbit + spin with the ring, as on web).
          RotationTransition(
            turns: _orbit,
            child: const SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(alignment: Alignment.topCenter, child: _DishBubble('🍝')),
                  Align(alignment: Alignment.bottomCenter, child: _DishBubble('🥗')),
                  Align(alignment: Alignment.centerLeft, child: _DishBubble('🍰')),
                  Align(alignment: Alignment.centerRight, child: _DishBubble('🍷')),
                ],
              ),
            ),
          ),
          // Center Hot Dish mark: pop-in × breathe. Centered by the Stack, so the
          // scale never drifts off-center.
          AnimatedBuilder(
            animation: Listenable.merge([_entry, _pulse]),
            builder: (_, child) => Opacity(
              opacity: _popOpacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _popScale.value * _breathe.value,
                child: child,
              ),
            ),
            child: const HotDishMark(size: 86),
          ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Container(
      width: 220,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFF2E7DC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedBuilder(
        animation: _prog,
        builder: (_, __) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _progressValue().clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _DishBubble extends StatelessWidget {
  final String emoji;
  const _DishBubble(this.emoji);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x1F000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
