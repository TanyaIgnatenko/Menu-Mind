"use client";

import { useEffect, useState } from "react";

import Link from "next/link";

import { Check, Pencil, Trash2, X } from "lucide-react";

import { AppShell } from "@/components/AppShell";
import { BrandMark } from "@/components/BrandMark";
import { Button } from "@/components/ui/button";
import {
  getHistory,
  removeFromHistory,
  renameHistoryEntry,
  type HistoryEntry,
} from "@/lib/history";

function timeAgo(ts: number): string {
  const s = Math.floor((Date.now() - ts) / 1000);
  if (s < 60) return "just now";
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  if (d < 7) return `${d}d ago`;
  return new Date(ts).toLocaleDateString(undefined, {
    day: "numeric",
    month: "short",
  });
}

function titleFor(e: HistoryEntry): string {
  return e.customName || e.restaurantName || e.autoName || "Menu";
}

export default function HistoryPage() {
  const [entries, setEntries] = useState<HistoryEntry[] | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState("");

  useEffect(() => {
    setEntries(getHistory());
  }, []);

  const startEdit = (e: HistoryEntry) => {
    setEditingId(e.id);
    setDraft(e.customName || "");
  };
  const commitEdit = (id: string) => {
    setEntries(renameHistoryEntry(id, draft));
    setEditingId(null);
    setDraft("");
  };
  const cancelEdit = () => {
    setEditingId(null);
    setDraft("");
  };

  return (
    <AppShell active="history">
      <h1 className="mb-5 font-display text-2xl font-extrabold tracking-tight text-ink">
        History
      </h1>

      {entries === null ? null : entries.length === 0 ? (
        <div className="mx-auto mt-10 max-w-sm rounded-2xl border border-border bg-surface p-10 text-center shadow-card">
          <BrandMark size={56} className="mx-auto shadow-card" />
          <p className="mt-4 font-display text-lg font-bold text-ink">
            No menus yet
          </p>
          <p className="mt-1 text-sm text-body">
            Scan a menu and it&apos;ll show up here.
          </p>
          <Link href="/">
            <Button className="mt-5">Scan a menu</Button>
          </Link>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {entries.map((e) => {
            const isEditing = editingId === e.id;
            return (
              <div
                key={e.id}
                className="relative flex flex-col rounded-2xl border border-border bg-surface p-5 shadow-card transition-shadow hover:shadow-card-hover"
              >
                {/* Actions */}
                <div className="absolute right-3 top-3 flex items-center gap-1">
                  {isEditing ? (
                    <>
                      <button
                        type="button"
                        onClick={() => commitEdit(e.id)}
                        aria-label="Save name"
                        className="flex h-8 w-8 items-center justify-center rounded-lg text-body hover:bg-canvas-alt hover:text-primary"
                      >
                        <Check className="h-4 w-4" aria-hidden="true" />
                      </button>
                      <button
                        type="button"
                        onClick={cancelEdit}
                        aria-label="Cancel"
                        className="flex h-8 w-8 items-center justify-center rounded-lg text-body hover:bg-canvas-alt hover:text-ink"
                      >
                        <X className="h-4 w-4" aria-hidden="true" />
                      </button>
                    </>
                  ) : (
                    <>
                      <button
                        type="button"
                        onClick={() => startEdit(e)}
                        aria-label="Rename"
                        className="flex h-8 w-8 items-center justify-center rounded-lg text-muted hover:bg-canvas-alt hover:text-ink"
                      >
                        <Pencil className="h-4 w-4" aria-hidden="true" />
                      </button>
                      <button
                        type="button"
                        onClick={() => setEntries(removeFromHistory(e.id))}
                        aria-label="Delete from history"
                        className="flex h-8 w-8 items-center justify-center rounded-lg text-muted hover:bg-canvas-alt hover:text-allergen"
                      >
                        <Trash2 className="h-4 w-4" aria-hidden="true" />
                      </button>
                    </>
                  )}
                </div>

                {isEditing ? (
                  <div className="pr-16">
                    <input
                      autoFocus
                      value={draft}
                      onChange={(ev) => setDraft(ev.target.value)}
                      onKeyDown={(ev) => {
                        if (ev.key === "Enter") commitEdit(e.id);
                        if (ev.key === "Escape") cancelEdit();
                      }}
                      placeholder="Name this menu"
                      className="w-full rounded-lg border border-input bg-background px-2.5 py-1.5 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    />
                    <p className="mt-1 text-xs text-muted-2">
                      {e.dishCount} {e.dishCount === 1 ? "dish" : "dishes"} ·{" "}
                      {timeAgo(e.savedAt)}
                    </p>
                  </div>
                ) : (
                  <Link href={`/menu/${e.id}`} className="block pr-16">
                    <p className="truncate font-display text-base font-bold text-ink">
                      {titleFor(e)}
                    </p>
                    <p className="mt-1 text-xs text-muted-2">
                      {e.dishCount} {e.dishCount === 1 ? "dish" : "dishes"} ·{" "}
                      {timeAgo(e.savedAt)}
                    </p>
                  </Link>
                )}
              </div>
            );
          })}
        </div>
      )}
    </AppShell>
  );
}
