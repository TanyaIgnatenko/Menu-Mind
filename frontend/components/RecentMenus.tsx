"use client";

import { useState } from "react";

import { Check, Loader2, Pencil, X } from "lucide-react";

import { capture } from "@/lib/posthog";
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
  return entry.customName || entry.restaurantName || "Menu";
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
    <section className="mt-10">
      <h2 className="mb-3 font-display text-xl font-semibold text-navy">
        Recent menus
      </h2>
      <div className="space-y-2">
        {entries.map((entry) => {
          const meta = [
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
              className="flex items-center gap-2 rounded-lg bg-card p-3.5 shadow-card transition-shadow hover:shadow-card-hover"
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
                  className="min-w-0 flex-1 rounded-md border border-input bg-background px-2.5 py-1.5 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                />
              ) : (
                <button
                  onClick={() => {
                    capture("menu_opened_from_history", { menu_id: entry.id });
                    onOpen(entry.id);
                  }}
                  disabled={isOpening}
                  className="min-w-0 flex-1 text-left disabled:opacity-60"
                >
                  <p className="truncate font-medium text-navy">
                    {titleFor(entry)}
                  </p>
                  <p className="truncate text-sm text-muted-foreground">{meta}</p>
                </button>
              )}

              {isEditing ? (
                <>
                  <button
                    onClick={() => commitEdit(entry.id)}
                    aria-label="Save name"
                    className="rounded-full p-1.5 text-muted-foreground hover:bg-gold/50 hover:text-navy"
                  >
                    <Check className="h-4 w-4" />
                  </button>
                  <button
                    onClick={cancelEdit}
                    aria-label="Cancel"
                    className="rounded-full p-1.5 text-muted-foreground hover:bg-gold/50 hover:text-navy"
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
                    className="rounded-full p-1.5 text-muted-foreground hover:bg-gold/50 hover:text-navy"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
                  <button
                    onClick={() => onRemove(entry.id)}
                    aria-label="Remove from history"
                    className="rounded-full p-1.5 text-muted-foreground hover:bg-coral/15 hover:text-coral"
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
