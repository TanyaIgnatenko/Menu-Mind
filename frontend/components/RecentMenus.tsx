"use client";

import { Loader2, X } from "lucide-react";

import type { HistoryEntry } from "@/lib/history";

interface Props {
  entries: HistoryEntry[];
  openingId: string | null;
  onOpen: (id: string) => void;
  onRemove: (id: string) => void;
}

function formatRelativeTime(ts: number): string {
  const seconds = Math.floor((Date.now() - ts) / 1000);
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

export function RecentMenus({ entries, openingId, onOpen, onRemove }: Props) {
  if (entries.length === 0) return null;

  return (
    <section className="mt-8">
      <h2 className="mb-3 text-lg font-semibold">Recent menus</h2>
      <div className="space-y-2">
        {entries.map((entry) => {
          const title = entry.restaurantName || "Menu";
          const meta = [
            entry.cuisineType,
            `${entry.dishCount} dishes`,
            formatRelativeTime(entry.savedAt),
          ]
            .filter(Boolean)
            .join(" · ");
          const isOpening = openingId === entry.id;

          return (
            <div
              key={entry.id}
              className="flex items-center gap-2 rounded-lg border bg-card p-3"
            >
              <button
                onClick={() => onOpen(entry.id)}
                disabled={isOpening}
                className="flex-1 text-left disabled:opacity-60"
              >
                <p className="font-medium">{title}</p>
                <p className="text-sm text-muted-foreground">{meta}</p>
              </button>
              {isOpening ? (
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              ) : (
                <button
                  onClick={() => onRemove(entry.id)}
                  aria-label="Remove from history"
                  className="rounded p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
                >
                  <X className="h-4 w-4" />
                </button>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}