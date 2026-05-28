"use client";

import { useState } from "react";

import { Check, Loader2, Pencil, X } from "lucide-react";

import type { HistoryEntry } from "@/lib/history";

interface Props {
  entries: HistoryEntry[];
  openingId: string | null;
  onOpen: (id: string) => void;
  onRemove: (id: string) => void;
  onRename: (id: string, name: string) => void;
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

function titleFor(entry: HistoryEntry): string {
  // Priority: user-set name -> restaurant name -> cuisine fallback -> "Menu"
  return (
    entry.customName ||
    entry.restaurantName ||
    (entry.cuisineType ? `${entry.cuisineType} menu` : "Menu")
  );
}

export function RecentMenus({
  entries,
  openingId,
  onOpen,
  onRemove,
  onRename,
}: Props) {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState("");

  if (entries.length === 0) return null;

  const startEdit = (entry: HistoryEntry) => {
    setEditingId(entry.id);
    setDraft(entry.customName || "");
  };

  const commitEdit = (id: string) => {
    onRename(id, draft);
    setEditingId(null);
    setDraft("");
  };

  const cancelEdit = () => {
    setEditingId(null);
    setDraft("");
  };

  return (
    <section className="mt-8">
      <h2 className="mb-3 text-lg font-semibold">Recent menus</h2>
      <div className="space-y-2">
        {entries.map((entry) => {
          const meta = [
            entry.cuisineType,
            `${entry.dishCount} dishes`,
            formatRelativeTime(entry.savedAt),
          ]
            .filter(Boolean)
            .join(" · ");
          const isOpening = openingId === entry.id;
          const isEditing = editingId === entry.id;

          return (
            <div
              key={entry.id}
              className="flex items-center gap-2 rounded-lg border bg-card p-3"
            >
              {isEditing ? (
                <input
                  autoFocus
                  value={draft}
                  onChange={(e) => setDraft(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") commitEdit(entry.id);
                    if (e.key === "Escape") cancelEdit();
                  }}
                  placeholder="Name this menu"
                  className="min-w-0 flex-1 rounded border bg-background px-2 py-1 text-sm"
                />
              ) : (
                <button
                  onClick={() => onOpen(entry.id)}
                  disabled={isOpening}
                  className="min-w-0 flex-1 text-left disabled:opacity-60"
                >
                  <p className="truncate font-medium">{titleFor(entry)}</p>
                  <p className="truncate text-sm text-muted-foreground">{meta}</p>
                </button>
              )}

              {isEditing ? (
                <>
                  <button
                    onClick={() => commitEdit(entry.id)}
                    aria-label="Save name"
                    className="rounded p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
                  >
                    <Check className="h-4 w-4" />
                  </button>
                  <button
                    onClick={cancelEdit}
                    aria-label="Cancel"
                    className="rounded p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </>
              ) : isOpening ? (
                <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
              ) : (
                <>
                  <button
                    onClick={() => startEdit(entry)}
                    aria-label="Rename"
                    className="rounded p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => onRemove(entry.id)}
                    aria-label="Remove from history"
                    className="rounded p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}