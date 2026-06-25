"use client";

import { useEffect, useState } from "react";

import Link from "next/link";

import { Trash2 } from "lucide-react";

import { AppShell } from "@/components/AppShell";
import { BrandMark } from "@/components/BrandMark";
import { Button } from "@/components/ui/button";
import { getHistory, removeFromHistory, type HistoryEntry } from "@/lib/history";

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

export default function HistoryPage() {
  const [entries, setEntries] = useState<HistoryEntry[] | null>(null);

  useEffect(() => {
    setEntries(getHistory());
  }, []);

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
          {entries.map((e) => (
            <div
              key={e.id}
              className="group relative rounded-2xl border border-border bg-surface p-5 shadow-card transition-shadow hover:shadow-card-hover"
            >
              <Link href={`/menu/${e.id}`} className="block">
                <p className="truncate pr-6 font-display text-base font-bold text-ink">
                  {e.customName || e.restaurantName || e.autoName}
                </p>
                <p className="mt-1 text-xs text-muted-2">
                  {e.dishCount} {e.dishCount === 1 ? "dish" : "dishes"} ·{" "}
                  {timeAgo(e.savedAt)}
                </p>
              </Link>
              <button
                type="button"
                onClick={() => setEntries(removeFromHistory(e.id))}
                aria-label="Remove from history"
                className="absolute right-3 top-3 flex h-8 w-8 items-center justify-center rounded-lg text-muted opacity-0 transition-opacity hover:bg-canvas-alt hover:text-allergen group-hover:opacity-100"
              >
                <Trash2 className="h-4 w-4" aria-hidden="true" />
              </button>
            </div>
          ))}
        </div>
      )}
    </AppShell>
  );
}
