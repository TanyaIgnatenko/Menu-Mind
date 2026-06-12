"use client";

import { useCallback, useEffect, useState } from "react";

import Link from "next/link";
import { notFound, useParams } from "next/navigation";

import { MenuDisplay } from "@/components/MenuDisplay";
import { ShareButton } from "@/components/ShareButton";
import { Wordmark } from "@/components/Wordmark";
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
        addToHistory(loaded);
      } catch (e) {
        if (cancelled) return;
        if (e instanceof NotFoundError) {
          setError("not_found");
        } else {
          setError("other");
        }
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
  }, []);

  useMenuPolling(menu, handleUpdate);

  if (error === "not_found") {
    notFound();
  }

  if (error === "other") {
    return (
      <main className="container mx-auto max-w-3xl px-4 py-8 md:py-12">
        <Wordmark asLink />
        <p className="text-sm text-muted-foreground">
          Couldn&apos;t load this menu. Try again later.
        </p>
        <Link href="/">
          <Button variant="outline" className="mt-4">
            Back to home
          </Button>
        </Link>
      </main>
    );
  }

  if (!menu) {
    return (
      <main className="container mx-auto max-w-3xl px-4 py-8 md:py-12">
        <Wordmark asLink />
        <div className="flex items-center gap-3 text-muted-foreground">
          <span className="h-2 w-2 rounded-full bg-coral dot-bounce" />
          <span
            className="h-2 w-2 rounded-full bg-navy dot-bounce"
            style={{ animationDelay: "0.15s" }}
          />
          <span
            className="h-2 w-2 rounded-full bg-gold dot-bounce"
            style={{ animationDelay: "0.3s" }}
          />
          <p className="text-sm">Loading menu...</p>
        </div>
      </main>
    );
  }

  return (
    <main className="container mx-auto max-w-3xl px-4 py-8 md:py-12">
      <Wordmark asLink />

      <div className="space-y-5">
        <div className="flex gap-2">
          <Link href="/">
            <Button variant="outline">Upload another menu</Button>
          </Link>
          <ShareButton menuId={menu.id} />
        </div>
        <MenuDisplay menu={menu} />
      </div>
    </main>
  );
}
