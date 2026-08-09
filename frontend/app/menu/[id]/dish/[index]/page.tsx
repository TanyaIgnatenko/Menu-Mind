"use client";

import { useCallback, useEffect, useState } from "react";

import Link from "next/link";
import { notFound, useParams } from "next/navigation";

import { ArrowLeft } from "lucide-react";

import { AppShell } from "@/components/AppShell";
import { DishDetailContent } from "@/components/DishDetailContent";
import { LoadingOrbit } from "@/components/LoadingOrbit";
import { getMenu, NotFoundError } from "@/lib/api";
import type { Menu } from "@/lib/types";
import { useMenuPolling } from "@/lib/useMenuPolling";

/**
 * Full-page dish detail (mobile web). On desktop a dish opens as a modal from
 * the grid; this route is the deep-linkable / mobile equivalent.
 */
export default function DishPage() {
  const params = useParams<{ id: string; index: string }>();
  const id = params.id;
  const dishIndex = Number.parseInt(params.index, 10);

  const [menu, setMenu] = useState<Menu | null>(null);
  const [missing, setMissing] = useState(false);

  useEffect(() => {
    let cancelled = false;
    getMenu(id)
      .then((m) => !cancelled && setMenu(m))
      .catch((e) => {
        if (!cancelled) setMissing(e instanceof NotFoundError);
      });
    return () => {
      cancelled = true;
    };
  }, [id]);

  // Keep streaming image updates for this dish.
  useMenuPolling(
    menu,
    useCallback((m: Menu) => setMenu(m), []),
  );

  if (missing) notFound();

  const dish = menu?.dishes[dishIndex];
  // Enrichment (about + nutrition) may still be streaming while the menu isn't
  // fully settled — show shimmer placeholders for those sections until it lands.
  const enrichmentPending = menu
    ? menu.status === "extracting" ||
      menu.dishes.some(
        (d) => d.image_status !== "ready" && d.image_status !== "failed",
      )
    : false;

  return (
    <AppShell active="scan">
      <div className="mx-auto max-w-2xl">
        <Link
          href={`/menu/${id}`}
          className="mb-4 inline-flex h-9 items-center gap-1.5 text-sm font-semibold text-body hover:text-ink"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Back to menu
        </Link>

        {!menu ? (
          <LoadingOrbit caption="Loading dish…" />
        ) : dish ? (
          <div className="overflow-hidden rounded-2xl border border-border bg-surface shadow-card">
            <DishDetailContent
              dish={dish}
              variant="page"
              enrichmentPending={enrichmentPending}
            />
          </div>
        ) : (
          <div className="rounded-2xl border border-border bg-surface p-8 text-center shadow-card">
            <p className="font-display text-lg font-bold text-ink">
              Dish not found
            </p>
            <Link
              href={`/menu/${id}`}
              className="mt-2 inline-block text-sm font-semibold text-primary hover:underline"
            >
              Back to menu
            </Link>
          </div>
        )}
      </div>
    </AppShell>
  );
}
