/// A menu-translation target language shown in the Settings language picker.
class AppLanguage {
  final String code; // ISO 639-1 (or BCP-47 for regional variants like zh-TW)
  final String name; // English name
  final String endonym; // native name
  final String flag; // representative emoji flag

  const AppLanguage(this.code, this.name, this.endonym, this.flag);
}

/// Translation targets. English is the default; the chosen language is sent with
/// each scan and the backend translates the menu into it. This is a broad,
/// travel-oriented subset of the 100+ languages the model handles — flags are
/// representative (a language isn't a country), so some share a flag or use a
/// common region. Keep in sync with backend `app/services/languages.py`.
const kSupportedLanguages = <AppLanguage>[
  AppLanguage('en', 'English', 'English', '🇬🇧'),
  AppLanguage('es', 'Spanish', 'Español', '🇪🇸'),
  AppLanguage('fr', 'French', 'Français', '🇫🇷'),
  AppLanguage('de', 'German', 'Deutsch', '🇩🇪'),
  AppLanguage('it', 'Italian', 'Italiano', '🇮🇹'),
  AppLanguage('pt', 'Portuguese', 'Português', '🇵🇹'),
  AppLanguage('nl', 'Dutch', 'Nederlands', '🇳🇱'),
  AppLanguage('ru', 'Russian', 'Русский', '🇷🇺'),
  AppLanguage('uk', 'Ukrainian', 'Українська', '🇺🇦'),
  AppLanguage('pl', 'Polish', 'Polski', '🇵🇱'),
  AppLanguage('cs', 'Czech', 'Čeština', '🇨🇿'),
  AppLanguage('sk', 'Slovak', 'Slovenčina', '🇸🇰'),
  AppLanguage('hu', 'Hungarian', 'Magyar', '🇭🇺'),
  AppLanguage('ro', 'Romanian', 'Română', '🇷🇴'),
  AppLanguage('bg', 'Bulgarian', 'Български', '🇧🇬'),
  AppLanguage('el', 'Greek', 'Ελληνικά', '🇬🇷'),
  AppLanguage('tr', 'Turkish', 'Türkçe', '🇹🇷'),
  AppLanguage('sv', 'Swedish', 'Svenska', '🇸🇪'),
  AppLanguage('da', 'Danish', 'Dansk', '🇩🇰'),
  AppLanguage('no', 'Norwegian', 'Norsk', '🇳🇴'),
  AppLanguage('fi', 'Finnish', 'Suomi', '🇫🇮'),
  AppLanguage('is', 'Icelandic', 'Íslenska', '🇮🇸'),
  AppLanguage('hr', 'Croatian', 'Hrvatski', '🇭🇷'),
  AppLanguage('sr', 'Serbian', 'Српски', '🇷🇸'),
  AppLanguage('sl', 'Slovenian', 'Slovenščina', '🇸🇮'),
  AppLanguage('lt', 'Lithuanian', 'Lietuvių', '🇱🇹'),
  AppLanguage('lv', 'Latvian', 'Latviešu', '🇱🇻'),
  AppLanguage('et', 'Estonian', 'Eesti', '🇪🇪'),
  AppLanguage('zh', 'Chinese (Simplified)', '简体中文', '🇨🇳'),
  AppLanguage('zh-TW', 'Chinese (Traditional)', '繁體中文', '🇹🇼'),
  AppLanguage('ja', 'Japanese', '日本語', '🇯🇵'),
  AppLanguage('ko', 'Korean', '한국어', '🇰🇷'),
  AppLanguage('th', 'Thai', 'ไทย', '🇹🇭'),
  AppLanguage('vi', 'Vietnamese', 'Tiếng Việt', '🇻🇳'),
  AppLanguage('id', 'Indonesian', 'Bahasa Indonesia', '🇮🇩'),
  AppLanguage('ms', 'Malay', 'Bahasa Melayu', '🇲🇾'),
  AppLanguage('tl', 'Filipino', 'Filipino', '🇵🇭'),
  AppLanguage('hi', 'Hindi', 'हिन्दी', '🇮🇳'),
  AppLanguage('bn', 'Bengali', 'বাংলা', '🇧🇩'),
  AppLanguage('ta', 'Tamil', 'தமிழ்', '🇮🇳'),
  AppLanguage('te', 'Telugu', 'తెలుగు', '🇮🇳'),
  AppLanguage('ur', 'Urdu', 'اردو', '🇵🇰'),
  AppLanguage('fa', 'Persian', 'فارسی', '🇮🇷'),
  AppLanguage('ar', 'Arabic', 'العربية', '🇸🇦'),
  AppLanguage('he', 'Hebrew', 'עברית', '🇮🇱'),
  AppLanguage('sw', 'Swahili', 'Kiswahili', '🇰🇪'),
  AppLanguage('am', 'Amharic', 'አማርኛ', '🇪🇹'),
  AppLanguage('af', 'Afrikaans', 'Afrikaans', '🇿🇦'),
];

/// The language for [code], falling back to the first entry (English).
AppLanguage languageByCode(String code) => kSupportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => kSupportedLanguages.first,
    );
