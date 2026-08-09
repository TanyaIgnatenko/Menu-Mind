import 'package:flutter/material.dart';
import '../app_version.dart';
import '../models/language.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_picker.dart';
import 'send_feedback_screen.dart';

/// The app's third tab: translation-language preference + the entry point to
/// Send Feedback, plus the app version footer.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  String _langCode = defaultLanguageCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code = await _settings.getLanguageCode();
    if (mounted) setState(() => _langCode = code);
  }

  Future<void> _pickLanguage() async {
    final picked = await showLanguagePicker(context, selectedCode: _langCode);
    if (picked == null || picked == _langCode) return;
    await _settings.setLanguageCode(picked);
    if (!mounted) return;
    setState(() => _langCode = picked);
    // Applies to the next scan (already-saved menus keep their language).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your next scan will be translated to ${languageByCode(picked).name}.'),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageByCode(_langCode);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.035 * 28,
                  color: AppColors.ink,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  const _SectionLabel('Translate menus to'),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    title: lang.name,
                    subtitle: 'Dish names, descriptions & details',
                    onTap: _pickLanguage,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('Support'),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    leading: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTintBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    title: 'Send feedback',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SendFeedbackScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: Text(
                  'MenuMind v$kAppVersion',
                  style: AppText.meta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text.toUpperCase(), style: AppText.eyebrow),
    );
  }
}

/// A tappable settings row: leading widget · title (+ optional subtitle) · chevron.
class _SettingsRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.meta),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
