import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app preferences (shared_preferences), same plain-service pattern as
/// [HistoryService].
///
/// - `translationLanguage`: the language menus should be translated to. NOTE:
///   the backend currently always translates to English — this choice is stored
///   and shown in the UI, but does not yet change the translation output.
/// - `replyToEmail`: the address feedback replies go to; pre-fills the Send
///   Feedback form next time.
const _kLang = 'menumind:translationLanguage';
const _kEmail = 'menumind:replyToEmail';

const defaultLanguageCode = 'en';

class SettingsService {
  Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLang) ?? defaultLanguageCode;
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, code);
  }

  Future<String> getReplyToEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail) ?? '';
  }

  Future<void> setReplyToEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email.trim());
  }
}
