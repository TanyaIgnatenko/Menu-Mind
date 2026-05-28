import type { Menu } from "./types";

const STORAGE_KEY = "menumind:history";
const MAX_ENTRIES = 20;

export interface HistoryEntry {
  id: string;
  restaurantName: string | null;
  dishCount: number;
  cuisineType: string;
  savedAt: number;
}

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
    dishCount: menu.dishes.length,
    cuisineType: menu.cuisine_type ?? "",
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