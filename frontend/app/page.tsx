"use client";

import { useEffect, useState } from "react";

import { useRouter } from "next/navigation";

import { AppShell } from "@/components/AppShell";
import { RecentMenus } from "@/components/RecentMenus";
import { ScanLanding } from "@/components/ScanLanding";
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

  return (
    <AppShell active="scan">
      <ScanLanding onUploaded={handleUploaded} />

      {history.length > 0 && (
        <div className="mx-auto mt-10 max-w-[620px]">
          <RecentMenus
            entries={history}
            openingId={null}
            onOpen={(id) => router.push(`/menu/${id}`)}
            onRemove={(id) => setHistory(removeFromHistory(id))}
            onRename={(id, name) => setHistory(renameHistoryEntry(id, name))}
          />
        </div>
      )}
    </AppShell>
  );
}
