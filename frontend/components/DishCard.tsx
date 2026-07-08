"use client";

import { useState } from "react";

import { useRouter } from "next/navigation";

import { imageUrl } from "@/lib/api";
import { capture } from "@/lib/posthog";
import { useIsDesktop } from "@/lib/useMediaQuery";
import type { Dish } from "@/lib/types";

import { DishDetailModal } from "./DishDetailModal";

interface Props {
  dish: Dish;
  menuId: string;
  index: number;
  /** "card" = desktop grid tile; "row" = mobile-web list row. */
  variant?: "card" | "row";
}

const POSITIVE_LABELS: Record<string, string> = {
  vegan: "Vegan",
  vegetarian: "Veg",
  healthy: "Healthy",
  low_calorie: "Low-cal",
  spicy: "Spicy",
  sweet: "Sweet",
};

/** First positive dietary tag to show as the single chip, if any. */
function cardChip(dish: Dish): string | null {
  for (const key of Object.keys(POSITIVE_LABELS)) {
    if (dish.dietary_tags?.includes(key)) return POSITIVE_LABELS[key];
  }
  return null;
}

/** Stripe shimmer → AI photo with a ~200ms cross-fade once loaded. */
function DishImage({ dish, className }: { dish: Dish; className?: string }) {
  const [loaded, setLoaded] = useState(false);
  const ready = dish.image_status === "ready" && dish.image_url;
  return (
    <div className={`relative overflow-hidden bg-canvas-alt ${className ?? ""}`}>
      <div className={`absolute inset-0 shimmer ${ready && loaded ? "opacity-0" : ""}`} />
      {ready && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={imageUrl(dish.image_url)}
          alt={dish.name_english || dish.name_original}
          loading="lazy"
          onLoad={() => setLoaded(true)}
          className={`absolute inset-0 h-full w-full object-cover transition-opacity duration-200 ${
            loaded ? "opacity-100" : "opacity-0"
          }`}
        />
      )}
    </div>
  );
}

export function DishCard({ dish, menuId, index, variant = "card" }: Props) {
  const router = useRouter();
  const isDesktop = useIsDesktop();
  const [modalOpen, setModalOpen] = useState(false);

  const hasTranslation =
    dish.name_english && dish.name_english !== dish.name_original;
  const chip = cardChip(dish);
  const title = hasTranslation ? dish.name_english : dish.name_original;

  function open() {
    capture("dish_opened", { menu_id: menuId, dish_name: title, index });
    if (isDesktop) setModalOpen(true);
    else router.push(`/menu/${menuId}/dish/${index}`);
  }

  const modal = modalOpen && (
    <DishDetailModal dish={dish} onClose={() => setModalOpen(false)} />
  );

  if (variant === "row") {
    return (
      <>
        <button
          type="button"
          onClick={open}
          className="flex w-full items-center gap-3 rounded-2xl border border-border bg-surface p-3 text-left shadow-card"
        >
          <DishImage dish={dish} className="h-[60px] w-[60px] shrink-0 rounded-xl" />
          <div className="min-w-0 flex-1">
            <h3 className="truncate text-sm font-bold text-ink">{title}</h3>
            {hasTranslation && (
              <p className="truncate text-[11px] italic text-muted">
                {dish.name_original}
              </p>
            )}
            {chip && (
              <span className="mt-1 inline-block rounded-full bg-success-bg px-2 py-0.5 text-[11px] font-semibold text-success">
                {chip}
              </span>
            )}
          </div>
          {dish.price && (
            <span className="shrink-0 font-display text-sm font-extrabold text-primary">
              {dish.price}
            </span>
          )}
        </button>
        {modal}
      </>
    );
  }

  return (
    <>
      <button
        type="button"
        onClick={open}
        className="rise-in group flex flex-col overflow-hidden rounded-2xl border border-border bg-surface text-left shadow-card transition-shadow hover:shadow-card-hover"
      >
        <DishImage dish={dish} className="h-[150px] w-full" />
        <div className="flex flex-1 flex-col p-4">
          <h3 className="text-sm font-bold leading-snug text-ink">{title}</h3>
          {hasTranslation && (
            <p className="mt-0.5 truncate text-[11px] italic text-muted">
              {dish.name_original}
            </p>
          )}
          <div className="mt-auto flex items-center justify-between pt-3">
            {dish.price ? (
              <span className="font-display text-base font-extrabold text-primary">
                {dish.price}
              </span>
            ) : (
              <span />
            )}
            {chip && (
              <span className="rounded-full bg-success-bg px-2 py-0.5 text-[11px] font-semibold text-success">
                {chip}
              </span>
            )}
          </div>
        </div>
      </button>
      {modal}
    </>
  );
}
