import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/menu.dart';
import '../services/analytics.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/menu_photo_store.dart';
import '../theme/app_theme.dart';
import '../widgets/wordmark.dart';
import '../widgets/stripe_placeholder.dart';
import '../widgets/camera_glyph.dart';
import 'loading_view.dart';
import 'menu_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final _api = ApiService();
  final _history = HistoryService();
  final _picker = ImagePicker();

  bool _loading = false;
  int _stageIndex = 0;
  int? _dishCount;
  Timer? _stageTimer;

  HistoryEntry? _recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stageTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRecent();
  }

  Future<void> _loadRecent() async {
    final entries = await _history.getHistory();
    if (mounted) setState(() => _recent = entries.isNotEmpty ? entries.first : null);
  }

  Future<void> _pick(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;
    Analytics.capture('scan_started', {
      'source': source == ImageSource.camera ? 'camera' : 'gallery',
    });
    await _upload(File(xFile.path));
  }

  /// Coarse reason bucket for a failed scan, from the user-facing message.
  String _failReason(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('too long')) return 'timeout';
    if (m.contains('read the menu')) return 'extraction_failed';
    if (m.contains('connection') || m.contains('internet')) return 'network';
    return 'error';
  }

  Future<void> _upload(File file) async {
    setState(() {
      _loading = true;
      _stageIndex = 0;
      _dishCount = null;
    });

    // Advance the loader caption through the three stages while we wait.
    // Advance the caption through the stages slowly so it doesn't outrun the
    // (deliberately slow) progress bar on the loading screen.
    _stageTimer = Timer.periodic(const Duration(milliseconds: 5000), (_) {
      if (mounted && _stageIndex < 3) setState(() => _stageIndex++);
    });

    try {
      // The server returns a placeholder immediately, then extracts the menu
      // (OCR + translation) in the background. Poll until it's ready — the
      // loading screen stays up meanwhile — so the slow work can't hit the
      // gateway timeout (504).
      Menu menu = await _api.uploadMenu(file, deviceId: Analytics.distinctId);
      final deadline = DateTime.now().add(const Duration(minutes: 4));
      while (menu.extractionPending) {
        if (DateTime.now().isAfter(deadline)) {
          throw ApiException('Processing took too long. Please try again.');
        }
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        try {
          menu = await _api.getMenu(menu.id);
        } catch (_) {
          // Transient poll error — keep retrying until the deadline.
        }
      }
      if (menu.extractionFailed) {
        throw ApiException('Could not read the menu. Try a clearer photo.');
      }

      Analytics.capture('scan_succeeded', {
        'dishes_count': menu.dishes.length,
        if (menu.cuisineType != null && menu.cuisineType!.isNotEmpty)
          'cuisine_type': menu.cuisineType!,
      });

      // image_picker returns a cache file the OS can purge — copy it into the
      // app's documents dir (stored by filename) so the History thumbnail survives.
      final photoName = await MenuPhotoStore.save(file, menu.id);
      await _history.addToHistory(menu, menuPhotoPath: photoName);
      _stageTimer?.cancel();
      if (!mounted) return;
      // Hide the loader before navigating so the Scan screen is ready underneath.
      setState(() {
        _dishCount = menu.dishes.length;
        _loading = false;
      });
      await _openMenu(menu);
      await _loadRecent();
    } catch (e) {
      _stageTimer?.cancel();
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e is ApiException
          ? e.message
          : 'Could not process the menu. Please try again.';
      Analytics.capture('scan_failed', {'reason': _failReason(msg)});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.primaryDeep),
      );
    } finally {
      _stageTimer?.cancel();
    }
  }

  Future<void> _openMenu(Menu menu) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuScreen(menu: menu, api: _api, history: _history),
      ),
    );
  }

  Future<void> _openRecent() async {
    final entry = _recent;
    if (entry == null) return;
    try {
      final menu = await _api.getMenu(entry.id);
      if (!mounted) return;
      await _openMenu(menu);
      await _loadRecent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e'), backgroundColor: AppColors.primaryDeep),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return LoadingView(stageIndex: _stageIndex, dishCount: _dishCount);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wordmark(),
              const SizedBox(height: 20),
              _languagePill(),
              const SizedBox(height: 20),
              const Text('Read any\nmenu.', style: AppText.hero),
              const SizedBox(height: 14),
              const Text(
                'Photograph any restaurant menu and get every dish translated '
                'instantly — with AI-generated photos and nutrition info.',
                style: AppText.body,
              ),
              const SizedBox(height: 26),
              _PrimaryButton(
                icon: const CameraGlyph(size: 20),
                label: 'Take a Photo',
                onTap: () => _pick(ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                icon: Icons.image_outlined,
                label: 'Choose from Gallery',
                onTap: () => _pick(ImageSource.gallery),
              ),
              if (_recent != null) ...[
                const SizedBox(height: 20),
                _RecentCard(entry: _recent!, onTap: _openRecent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _languagePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryTintBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌍', style: TextStyle(fontSize: 14)),
          SizedBox(width: 6),
          Text(
            '40+ languages supported',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.body),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Recent scan card ─────────────────────────────────────────────────────────

class _RecentCard extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  const _RecentCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 48, height: 48, child: _thumb()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RECENT SCAN', style: AppText.eyebrow),
                    const SizedBox(height: 3),
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${entry.dishCount} dishes · ${timeago.format(entry.savedAt)}',
                      style: AppText.meta,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() {
    final file = MenuPhotoStore.resolve(entry.menuPhotoPath);
    if (file != null && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const StripePlaceholder.warm());
    }
    return const StripePlaceholder.warm();
  }
}
