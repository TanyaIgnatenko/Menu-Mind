import 'package:flutter/material.dart';
import '../models/language.dart';
import '../theme/app_theme.dart';

/// Presents the translation-language picker as a bottom sheet.
/// Resolves to the chosen language code, or null if dismissed.
Future<String?> showLanguagePicker(
  BuildContext context, {
  required String selectedCode,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LanguagePickerSheet(selectedCode: selectedCode),
  );
}

class _LanguagePickerSheet extends StatefulWidget {
  final String selectedCode;
  const _LanguagePickerSheet({required this.selectedCode});

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppLanguage> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kSupportedLanguages;
    return kSupportedLanguages
        .where((l) =>
            l.name.toLowerCase().contains(q) ||
            l.endonym.toLowerCase().contains(q) ||
            l.code.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Grow with the keyboard so the search field and results stay visible.
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.8;
    final results = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        margin: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle.
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 10),
              child: Text('Translate menus to', style: AppText.header),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: 'Search languages…',
                  hintStyle: AppText.body.copyWith(color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            Flexible(
              child: results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text('No languages match.', style: AppText.body),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final lang = results[i];
                        return _LanguageRow(
                          lang: lang,
                          selected: lang.code == widget.selectedCode,
                          onTap: () => Navigator.pop(context, lang.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${lang.name}, ${lang.endonym}',
      child: Material(
        color: selected ? AppColors.primaryTintBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.name,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primary : AppColors.ink,
                        ),
                      ),
                      if (lang.endonym != lang.name)
                        Text(lang.endonym, style: AppText.meta),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
