import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/analytics.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Pushed (modal) screen reached from Settings → "Send feedback".
/// Lets the user write a note, attach screenshots, and send it by email — the
/// selected images are uploaded and attached to the feedback email.
class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  static const _maxAttachments = 3;
  static const _maxBytes = 5 * 1024 * 1024; // 5 MB per image

  final _api = ApiService();
  final _settings = SettingsService();
  final _picker = ImagePicker();

  final _messageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageFocus = FocusNode();

  final List<XFile> _attachments = [];
  bool _sending = false;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _messageCtrl.addListener(_onChanged);
    _emailCtrl.addListener(_onChanged);
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final saved = await _settings.getReplyToEmail();
    if (mounted && saved.isNotEmpty) _emailCtrl.text = saved;
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _emailCtrl.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSend =>
      !_sending &&
      _messageCtrl.text.trim().isNotEmpty &&
      _emailRe.hasMatch(_emailCtrl.text.trim());

  Future<void> _addPhoto() async {
    if (_attachments.length >= _maxAttachments) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final len = await picked.length();
    if (len > _maxBytes) {
      if (mounted) _toast('That image is over 5 MB — pick a smaller one.');
      return;
    }
    setState(() => _attachments.add(picked));
  }

  void _removePhoto(XFile file) => setState(() => _attachments.remove(file));

  Future<void> _send() async {
    if (!_canSend) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final email = _emailCtrl.text.trim();
    try {
      await _settings.setReplyToEmail(email); // pre-fill next time
      await _api.submitFeedback(
        message: _messageCtrl.text.trim(),
        replyTo: email,
        attachmentPaths: _attachments.map((x) => x.path).toList(),
        deviceId: Analytics.distinctId,
      );
      if (!mounted) return;
      _toast('Thanks! Your feedback was sent.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _toast(e is ApiException ? e.message : 'Could not send. Please try again.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  const Text(
                    'Found a bug or have an idea? Tell us — we read every note.',
                    style: AppText.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _messageField(),
                  const SizedBox(height: 20),
                  const _Eyebrow('Attachments'),
                  const SizedBox(height: 10),
                  _attachmentsRow(),
                  const SizedBox(height: 20),
                  const _Eyebrow('Reply to'),
                  const SizedBox(height: 10),
                  _emailField(),
                ],
              ),
            ),
            // Send button pinned to the bottom (rides above the keyboard because
            // resizeToAvoidBottomInset shrinks the Scaffold).
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                (bottomInset > 0 ? bottomInset : 16) + 8,
              ),
              child: _sendButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.body),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          const Text('Send feedback', style: AppText.header),
        ],
      ),
    );
  }

  Widget _messageField() {
    return TextField(
      controller: _messageCtrl,
      focusNode: _messageFocus,
      autofocus: true,
      minLines: 6,
      maxLines: null,
      maxLength: 5000,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: "What's on your mind? The more detail, the better we can help...",
        hintStyle: AppText.body.copyWith(color: AppColors.muted),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _attachmentsRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final file in _attachments) _thumb(file),
        if (_attachments.length < _maxAttachments) _addTile(),
      ],
    );
  }

  Widget _addTile() {
    return Semantics(
      button: true,
      label: 'Add photo',
      child: GestureDetector(
        onTap: _addPhoto,
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: AppColors.muted,
            radius: 14,
          ),
          child: const SizedBox(
            width: 72,
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 22, color: AppColors.body),
                SizedBox(height: 2),
                Text(
                  'Add photo',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb(XFile file) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(file.path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Semantics(
              button: true,
              label: 'Remove attachment',
              child: GestureDetector(
                onTap: () => _removePhoto(file),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.canvas, width: 2),
                  ),
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailField() {
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      style: AppText.body,
      decoration: InputDecoration(
        hintText: 'you@example.com',
        hintStyle: AppText.body.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _sendButton() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSend ? _send : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
        child: _sending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Send feedback',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.eyebrow);
}

/// Dashed rounded-rectangle border for the "+ Add photo" tile.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
