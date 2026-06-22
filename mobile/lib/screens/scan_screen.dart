import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/menu.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/wordmark.dart';
import 'menu_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _api = ApiService();
  final _history = HistoryService();
  final _picker = ImagePicker();
  bool _loading = false;
  // Текущий индекс фазы загрузки (0-3)
  int _phaseIndex = 0;
  Timer? _phaseTimer;

  // Фазы с текстом — меняются каждые 3 секунды
  static const _phases = [
    'Reading the menu…',
    'Translating dishes…',
    'Generating food photos…',
    'Almost ready…',
  ];

  Future<void> _pick(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;
    await _upload(File(xFile.path));
  }

  Future<void> _upload(File file) async {
    setState(() {
      _loading = true;
      _phaseIndex = 0;
    });

    // Таймер меняет фазы каждые 3 секунды
    _phaseTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _phaseIndex < _phases.length - 1) {
        setState(() => _phaseIndex++);
      }
    });

    try {
      final menu = await _api.uploadMenu(file);
      // Передаём путь к оригинальному фото меню для превью в истории
      await _history.addToHistory(menu, menuPhotoPath: file.path);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, __) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: MenuScreen(menu: menu, api: _api, history: _history),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.beet,
        ),
      );
    } finally {
      _phaseTimer?.cancel();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _LoadingView(phaseIndex: _phaseIndex);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Wordmark(),
              const Spacer(),
              _uploadZone(),
              const SizedBox(height: 24),
              _button(Icons.photo_library_outlined, 'Choose from gallery',
                  () => _pick(ImageSource.gallery)),
              const SizedBox(height: 12),
              _button(Icons.camera_alt_outlined, 'Take a photo',
                  () => _pick(ImageSource.camera)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadZone() {
    return GestureDetector(
      onTap: () => _pick(ImageSource.gallery),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.beet.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDDE5CE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: AppColors.dill, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload a photo of any menu',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.deepBeet,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Works in any language',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

// ── Экран загрузки ────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final int phaseIndex;

  static const _phases = [
    'Reading the menu…',
    'Translating dishes…',
    'Generating food photos…',
    'Almost ready…',
  ];

  const _LoadingView({required this.phaseIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _BouncingDots(),
            const SizedBox(height: 32),
            // Текст меняется с анимацией
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _phases[phaseIndex.clamp(0, _phases.length - 1)],
                key: ValueKey(phaseIndex),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepBeet,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Прогресс-индикатор — четыре точки
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final isActive = i <= phaseIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.beet
                        : AppColors.beet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Три прыгающих точки (три цвета как во фронтенде) ─────────────────────────

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  static const _dotColors = [
    Color(0xFF8E2A4C),
    Color(0xFF5A1C32),
    Color(0xFFDDE5CE),
  ];
  static const _delays = [0, 150, 300];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _translateAnims;
  late List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      ),
    );

    _translateAnims = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -6.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: -6.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      ]).animate(c);
    }).toList();

    _opacityAnims = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.6, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.6)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(tween: ConstantTween(0.6), weight: 20),
      ]).animate(c);
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) _controllers[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _translateAnims[i].value),
            child: Opacity(
              opacity: _opacityAnims[i].value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _dotColors[i],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
