"use client";

import { useEffect, useRef, useState } from "react";

import { MenuDisplay } from "@/components/MenuDisplay";
import { MenuUpload } from "@/components/MenuUpload";
import { Button } from "@/components/ui/button";
import { getMenu } from "@/lib/api";
import type { Menu } from "@/lib/types";

const POLL_INTERVAL_MS = 2000;
const MAX_POLL_DURATION_MS = 300000; // 5 minutes

function allImagesResolved(menu: Menu): boolean {
  return menu.dishes.every(
    (d) => d.image_status === "ready" || d.image_status === "failed",
  );
}

export default function Home() {
  const [menu, setMenu] = useState<Menu | null>(null);
  const pollTimerRef = useRef<number | null>(null);
  const pollStartRef = useRef<number>(0);

  // Poll for image updates while at least one dish is still pending/generating.
  useEffect(() => {
    if (!menu) {
      return;
    }
    if (allImagesResolved(menu)) {
      return;
    }

    pollStartRef.current = Date.now();
    let cancelled = false;

    async function poll() {
      if (cancelled || !menu) return;
      try {
        const updated = await getMenu(menu.id);
        if (cancelled) return;
        setMenu(updated);
        if (
          allImagesResolved(updated) ||
          Date.now() - pollStartRef.current > MAX_POLL_DURATION_MS
        ) {
          return;
        }
        pollTimerRef.current = window.setTimeout(poll, POLL_INTERVAL_MS);
      } catch {
        // Network blip - retry once after the normal interval
        if (cancelled) return;
        pollTimerRef.current = window.setTimeout(poll, POLL_INTERVAL_MS);
      }
    }

    pollTimerRef.current = window.setTimeout(poll, POLL_INTERVAL_MS);

    return () => {
      cancelled = true;
      if (pollTimerRef.current !== null) {
        window.clearTimeout(pollTimerRef.current);
        pollTimerRef.current = null;
      }
    };
  }, [menu]);

  return (
    <main className="container mx-auto max-w-2xl p-4 py-8">
      <header className="mb-8">
        <h1 className="text-3xl font-bold">MenuMind</h1>
        <p className="text-muted-foreground">
          Eat with confidence, anywhere in the world.
        </p>
      </header>

      {!menu ? (
        <MenuUpload onUploaded={setMenu} />
      ) : (
        <div className="space-y-4">
          <Button variant="outline" onClick={() => setMenu(null)}>
            Upload another menu
          </Button>
          <MenuDisplay menu={menu} />
        </div>
      )}
    </main>
  );
}
