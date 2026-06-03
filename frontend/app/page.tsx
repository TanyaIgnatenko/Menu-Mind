"use client";

import { useEffect, useState } from "react";

import { useRouter } from "next/navigation";

import { MenuUpload } from "@/components/MenuUpload";
import { RecentMenus } from "@/components/RecentMenus";
import {
  addToHistory,
  getHistory,
  removeFromHistory,
  renameHistoryEntry,
  type HistoryEntry,
} from "@/lib/history";
import type { Menu } from "@/lib/types";

export default function Home() {
  const router = useRouter();
  const [history, setHistory] = useState<HistoryEntry[]>([]);

  // Load history from localStorage on mount (browser only).
  useEffect(() => {
    setHistory(getHistory());
  }, []);

  function handleUploaded(menu: Menu) {
    // Record in history eagerly so it persists even if navigation fails.
    // The /menu/[id] page also calls addToHistory; dedup by id makes that safe.
    setHistory(addToHistory(menu));
    router.push(`/menu/${menu.id}`);
  }

  function handleOpenFromHistory(id: string) {
    router.push(`/menu/${id}`);
  }

  return (
    <main className="container mx-auto max-w-2xl p-4 py-8">
      <header className="mb-8">
        <h1 className="text-3xl font-bold">MenuMind</h1>
        <p className="text-muted-foreground">
          Eat with confidence, anywhere in the world.
        </p>
      </header>

      <MenuUpload onUploaded={handleUploaded} />
      <RecentMenus
        entries={history}
        openingId={null}
        onOpen={handleOpenFromHistory}
        onRemove={(id) => setHistory(removeFromHistory(id))}
        onRename={(id, name) => setHistory(renameHistoryEntry(id, name))}
      />
    </main>
  );
}