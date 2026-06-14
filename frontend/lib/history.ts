import type { Menu } from "./types";

const STORAGE_KEY = "menumind:history";
const MAX_ENTRIES = 20;

export interface HistoryEntry {
  id: string;
  restaurantName: string | null;
  /** Cuisine style from Gemini, e.g. "Italian". Used in autoName. */
  cuisineType: string | null;
  /** Auto-generated fallback name when restaurantName is null. */
  autoName: string;
  dishCount: number;
  savedAt: number;
  customName?: string;
}

// ── Auto-name generation ──────────────────────────────────────────────────────

/** Language code → cuisine adjective for the auto-name. */
const LANGUAGE_CUISINE: Record<string, string> = {
  de: "German",
  it: "Italian",
  fr: "French",
  es: "Spanish",
  pt: "Portuguese",
  ru: "Russian",
  ja: "Japanese",
  zh: "Chinese",
  ko: "Korean",
  ar: "Arabic",
  tr: "Turkish",
  pl: "Polish",
  nl: "Dutch",
  sv: "Swedish",
  el: "Greek",
  th: "Thai",
  vi: "Vietnamese",
  hi: "Indian",
};

/**
 * Build a human-readable fallback name from the menu contents.
 *
 * Priority:
 *   1. First English category name (e.g. "Pasta & Noodles")
 *   2. Cuisine adjective from source_language + "menu" (e.g. "Italian menu")
 *   3. Plain "Menu"
 *
 * Always appends " · N dishes" so the entry is still informative without
 * a restaurant name.
 */
/** Return a time-of-day label for the current local time. */
function timeOfDay(): string {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 11) return "morning";
  if (hour >= 11 && hour < 15) return "lunch";
  if (hour >= 15 && hour < 18) return "afternoon";
  if (hour >= 18 && hour < 23) return "evening";
  return "night";
}

/** Return a short date label: "Today", "Yesterday", or "14 Jun". */
function dateLabel(): string {
  const now = new Date();
  const today = now.toDateString();
  const yesterday = new Date(now.getTime() - 86_400_000).toDateString();
  const saved = new Date().toDateString(); // always "today" when building autoName
  if (saved === today) return "Today";
  if (saved === yesterday) return "Yesterday";
  return now.toLocaleDateString(undefined, { day: "numeric", month: "short" });
}

function buildAutoName(menu: Menu): string {
  const when = `${dateLabel()}, ${timeOfDay()}`;

  // 1. Gemini-generated cuisine type — most accurate.
  if (menu.cuisine_type) {
    return `${menu.cuisine_type} menu · ${when}`;
  }

  // 2. English category name from the first dish.
  const firstDish = menu.dishes[0];
  const firstCategory =
    firstDish?.category_english?.trim() || firstDish?.category?.trim();
  if (firstCategory) {
    return `${firstCategory} · ${when}`;
  }

  // 3. Language-based fallback.
  const lang = menu.source_language?.toLowerCase().split("-")[0] ?? "";
  const cuisine = LANGUAGE_CUISINE[lang];
  if (cuisine) {
    return `${cuisine} menu · ${when}`;
  }

  return `Menu · ${when}`;
}

// ── CRUD ──────────────────────────────────────────────────────────────────────

export function getHistory(): HistoryEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? (parsed as HistoryEntry[]) : [];
  } catch {
    return [];
  }
}

function writeHistory(entries: HistoryEntry[]): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
  } catch {
    // localStorage full or unavailable — history is best-effort, ignore.
  }
}

export function addToHistory(menu: Menu): HistoryEntry[] {
  const entry: HistoryEntry = {
    id: menu.id,
    restaurantName: menu.restaurant_name,
    cuisineType: menu.cuisine_type,
    autoName: buildAutoName(menu),
    dishCount: menu.dishes.length,
    savedAt: Date.now(),
  };
  // Dedup by id (re-uploading the same image returns the same menu id),
  // newest first, capped at MAX_ENTRIES.
  const existing = getHistory().filter((e) => e.id !== menu.id);
  const updated = [entry, ...existing].slice(0, MAX_ENTRIES);
  writeHistory(updated);
  return updated;
}

export function removeFromHistory(id: string): HistoryEntry[] {
  const updated = getHistory().filter((e) => e.id !== id);
  writeHistory(updated);
  return updated;
}

export function renameHistoryEntry(id: string, name: string): HistoryEntry[] {
  const trimmed = name.trim();
  const updated = getHistory().map((e) =>
    e.id === id ? { ...e, customName: trimmed || undefined } : e,
  );
  writeHistory(updated);
  return updated;
}
