/**
 * Menu-translation target languages shown in the Settings picker.
 *
 * Kept in sync with the mobile picker (mobile/lib/models/language.dart) and the
 * backend name map (backend/app/services/languages.py). The chosen code is sent
 * with each scan; the backend translates the menu into it. Flags are
 * representative (a language isn't a country).
 */
export interface AppLanguage {
  code: string; // ISO 639-1 (or BCP-47 for regional variants like zh-TW)
  name: string; // English name
  endonym: string; // native name
  flag: string; // representative emoji flag
}

export const SUPPORTED_LANGUAGES: AppLanguage[] = [
  { code: "en", name: "English", endonym: "English", flag: "🇬🇧" },
  { code: "es", name: "Spanish", endonym: "Español", flag: "🇪🇸" },
  { code: "fr", name: "French", endonym: "Français", flag: "🇫🇷" },
  { code: "de", name: "German", endonym: "Deutsch", flag: "🇩🇪" },
  { code: "it", name: "Italian", endonym: "Italiano", flag: "🇮🇹" },
  { code: "pt", name: "Portuguese", endonym: "Português", flag: "🇵🇹" },
  { code: "nl", name: "Dutch", endonym: "Nederlands", flag: "🇳🇱" },
  { code: "ru", name: "Russian", endonym: "Русский", flag: "🇷🇺" },
  { code: "uk", name: "Ukrainian", endonym: "Українська", flag: "🇺🇦" },
  { code: "pl", name: "Polish", endonym: "Polski", flag: "🇵🇱" },
  { code: "cs", name: "Czech", endonym: "Čeština", flag: "🇨🇿" },
  { code: "sk", name: "Slovak", endonym: "Slovenčina", flag: "🇸🇰" },
  { code: "hu", name: "Hungarian", endonym: "Magyar", flag: "🇭🇺" },
  { code: "ro", name: "Romanian", endonym: "Română", flag: "🇷🇴" },
  { code: "bg", name: "Bulgarian", endonym: "Български", flag: "🇧🇬" },
  { code: "el", name: "Greek", endonym: "Ελληνικά", flag: "🇬🇷" },
  { code: "tr", name: "Turkish", endonym: "Türkçe", flag: "🇹🇷" },
  { code: "sv", name: "Swedish", endonym: "Svenska", flag: "🇸🇪" },
  { code: "da", name: "Danish", endonym: "Dansk", flag: "🇩🇰" },
  { code: "no", name: "Norwegian", endonym: "Norsk", flag: "🇳🇴" },
  { code: "fi", name: "Finnish", endonym: "Suomi", flag: "🇫🇮" },
  { code: "is", name: "Icelandic", endonym: "Íslenska", flag: "🇮🇸" },
  { code: "hr", name: "Croatian", endonym: "Hrvatski", flag: "🇭🇷" },
  { code: "sr", name: "Serbian", endonym: "Српски", flag: "🇷🇸" },
  { code: "sl", name: "Slovenian", endonym: "Slovenščina", flag: "🇸🇮" },
  { code: "lt", name: "Lithuanian", endonym: "Lietuvių", flag: "🇱🇹" },
  { code: "lv", name: "Latvian", endonym: "Latviešu", flag: "🇱🇻" },
  { code: "et", name: "Estonian", endonym: "Eesti", flag: "🇪🇪" },
  { code: "zh", name: "Chinese (Simplified)", endonym: "简体中文", flag: "🇨🇳" },
  { code: "zh-TW", name: "Chinese (Traditional)", endonym: "繁體中文", flag: "🇹🇼" },
  { code: "ja", name: "Japanese", endonym: "日本語", flag: "🇯🇵" },
  { code: "ko", name: "Korean", endonym: "한국어", flag: "🇰🇷" },
  { code: "th", name: "Thai", endonym: "ไทย", flag: "🇹🇭" },
  { code: "vi", name: "Vietnamese", endonym: "Tiếng Việt", flag: "🇻🇳" },
  { code: "id", name: "Indonesian", endonym: "Bahasa Indonesia", flag: "🇮🇩" },
  { code: "ms", name: "Malay", endonym: "Bahasa Melayu", flag: "🇲🇾" },
  { code: "tl", name: "Filipino", endonym: "Filipino", flag: "🇵🇭" },
  { code: "hi", name: "Hindi", endonym: "हिन्दी", flag: "🇮🇳" },
  { code: "bn", name: "Bengali", endonym: "বাংলা", flag: "🇧🇩" },
  { code: "ta", name: "Tamil", endonym: "தமிழ்", flag: "🇮🇳" },
  { code: "te", name: "Telugu", endonym: "తెలుగు", flag: "🇮🇳" },
  { code: "ur", name: "Urdu", endonym: "اردو", flag: "🇵🇰" },
  { code: "fa", name: "Persian", endonym: "فارسی", flag: "🇮🇷" },
  { code: "ar", name: "Arabic", endonym: "العربية", flag: "🇸🇦" },
  { code: "he", name: "Hebrew", endonym: "עברית", flag: "🇮🇱" },
  { code: "sw", name: "Swahili", endonym: "Kiswahili", flag: "🇰🇪" },
  { code: "am", name: "Amharic", endonym: "አማርኛ", flag: "🇪🇹" },
  { code: "af", name: "Afrikaans", endonym: "Afrikaans", flag: "🇿🇦" },
];

export const DEFAULT_LANGUAGE = "en";

/** The language for `code`, falling back to English. */
export function languageByCode(code: string): AppLanguage {
  return (
    SUPPORTED_LANGUAGES.find((l) => l.code === code) ?? SUPPORTED_LANGUAGES[0]
  );
}
