"use client";

import { useEffect, useRef } from "react";

import { getMenu } from "./api";
import { capture } from "./posthog";
import type { Menu } from "./types";

const POLL_INTERVAL_MS = 2000;
const MAX_POLL_DURATION_MS = 300000; // 5 minutes

function allImagesResolved(menu: Menu): boolean {
  return menu.dishes.every(
    (d) => d.image_status === "ready" || d.image_status === "failed",
  );
}

function hasFirstImage(menu: Menu): boolean {
  return menu.dishes.some((d) => d.image_status === "ready");
}

/**
 * Polls the menu by ID while any dish image is still pending or generating.
 * Calls `onUpdate` with each fresh menu received. Stops automatically when
 * all images are resolved or after MAX_POLL_DURATION_MS.
 *
 * Also fires a `time_to_first_image` analytics event the first time
 * any dish image becomes ready.
 */
export function useMenuPolling(
  menu: Menu | null,
  onUpdate: (menu: Menu) => void,
): void {
  const pollTimerRef = useRef<number | null>(null);
  const pollStartRef = useRef<number>(0);
  const firstImageCapturedRef = useRef(false);

  useEffect(() => {
    if (!menu) return;
    if (allImagesResolved(menu)) return;

    pollStartRef.current = Date.now();
    firstImageCapturedRef.current = false;
    let cancelled = false;

    async function poll() {
      if (cancelled || !menu) return;
      try {
        const updated = await getMenu(menu.id);
        if (cancelled) return;

        // Fire time_to_first_image exactly once when the first image arrives.
        if (!firstImageCapturedRef.current && hasFirstImage(updated)) {
          firstImageCapturedRef.current = true;
          capture("time_to_first_image", {
            menu_id: updated.id,
            seconds: Math.round((Date.now() - pollStartRef.current) / 1000),
            dish_count: updated.dishes.length,
          });
        }

        onUpdate(updated);

        if (
          allImagesResolved(updated) ||
          Date.now() - pollStartRef.current > MAX_POLL_DURATION_MS
        ) {
          return;
        }
        pollTimerRef.current = window.setTimeout(poll, POLL_INTERVAL_MS);
      } catch {
        // Network blip — retry after the normal interval
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
  }, [menu, onUpdate]);
}
