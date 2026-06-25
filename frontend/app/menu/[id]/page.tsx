"use client";

import { useCallback, useEffect, useState } from "react";

import Link from "next/link";
import { notFound, useParams } from "next/navigation";

import { AppShell } from "@/components/AppShell";
import { LoadingOrbit } from "@/components/LoadingOrbit";
import { MenuDisplay } from "@/components/MenuDisplay";
import { TopBar } from "@/components/TopBar";
import { Button } from "@/components/ui/button";
import { getMenu, NotFoundError } from "@/lib/api";
import { addToHistory } from "@/lib/history";
import type { Menu } from "@/lib/types";
import { useMenuPolling } from "@/lib/useMenuPolling";

export default function MenuPage() {
  const params = useParams<{ id: string }>();
  const id = params.id;

  const [menu, setMenu] = useState<Menu | null>(null);
  const [error, setError] = useState<"not_found" | "other" | null>(null);

  // Initial load — fetch the menu by id once on mount.
  useEffect(() => {
    let cancelled = false;
    async function load() {
      try {
        const loaded = await getMenu(id);
        if (cancelled) return;
        setMenu(loaded);
        // Don't record a still-extracting menu (0 dishes) — wait until it's
        // ready so the history entry has the real dish count and name.
        if (loaded.status !== "extracting") addToHistory(loaded);
      } catch (e) {
        if (cancelled) return;
        setError(e instanceof NotFoundError ? "not_found" : "other");
      }
    }
    load();
    return () => {
      cancelled = true;
    };
  }, [id]);

  // Stable callback for the polling hook so it doesn't re-subscribe each render.
  const handleUpdate = useCallback((updated: Menu) => {
    setMenu(updated);
    // Record once extraction completes so the history dish count is correct.
    if (updated.status !== "extracting") addToHistory(updated);
  }, []);

  useMenuPolling(menu, handleUpdate);

  if (error === "not_found") notFound();

  if (error === "other") {
    return (
      <AppShell active="scan">
        <div className="mx-auto max-w-lg rounded-2xl border border-border bg-surface p-8 text-center shadow-card">
          <p className="font-display text-lg font-bold text-ink">
            Couldn&apos;t load this menu
          </p>
          <p className="mt-1 text-sm text-body">Try again later.</p>
          <Link href="/">
            <Button variant="outline" className="mt-4">
              Back to scan
            </Button>
          </Link>
        </div>
      </AppShell>
    );
  }

  // Initial fetch or still extracting → the orbit loader (polling refreshes it).
  if (!menu || menu.status === "extracting") {
    return (
      <AppShell active="scan">
        <LoadingOrbit
          caption="Cooking up your menu"
          subcaption={menu ? "Reading & translating dishes…" : "Loading menu…"}
        />
      </AppShell>
    );
  }

  if (menu.status === "failed") {
    return (
      <AppShell active="scan">
        <div className="mx-auto max-w-lg rounded-2xl border border-border bg-surface p-8 text-center shadow-card">
          <p className="font-display text-lg font-bold text-ink">
            Couldn&apos;t read this menu
          </p>
          <p className="mt-1 text-sm text-body">
            The photo may be blurry or not a menu. Try a clearer photo.
          </p>
          <Link href="/">
            <Button className="mt-4">Try another menu</Button>
          </Link>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell active="scan" topBar={<TopBar menu={menu} />}>
      <MenuDisplay menu={menu} />
    </AppShell>
  );
}
