/**
 * Persisted app preferences (localStorage), mirroring the mobile SettingsService.
 *
 * - translationLanguage: the language menus are translated to. Sent with each
 *   scan (see uploadMenu); the backend translates the menu into it.
 * - replyToEmail: the address feedback replies go to; pre-fills the feedback form.
 */
import { DEFAULT_LANGUAGE } from "./languages";

const LANG_KEY = "menumind:translationLanguage";
const EMAIL_KEY = "menumind:replyToEmail";

export function getLanguageCode(): string {
  if (typeof window === "undefined") return DEFAULT_LANGUAGE;
  try {
    return window.localStorage.getItem(LANG_KEY) ?? DEFAULT_LANGUAGE;
  } catch {
    return DEFAULT_LANGUAGE;
  }
}

export function setLanguageCode(code: string): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(LANG_KEY, code);
  } catch {
    // localStorage unavailable — best-effort.
  }
}

export function getReplyToEmail(): string {
  if (typeof window === "undefined") return "";
  try {
    return window.localStorage.getItem(EMAIL_KEY) ?? "";
  } catch {
    return "";
  }
}

export function setReplyToEmail(email: string): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(EMAIL_KEY, email.trim());
  } catch {
    // best-effort
  }
}
