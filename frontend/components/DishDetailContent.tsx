"use client";

import { useState } from "react";

import { X } from "lucide-react";

import { imageUrl } from "@/lib/api";
import type { Dish } from "@/lib/types";

const TAG_LABELS: Record<string, string> = {
  vegan: "Vegan",
  vegetarian: "Vegetarian",
  healthy: "Healthy",
  low_calorie: "Low-calorie",
  spicy: "Spicy",
  sweet: "Sweet",
  contains_gluten: "⚠ Gluten",
  contains_dairy: "⚠ Dairy",
  contains_nuts: "⚠ Nuts",
  contains_eggs: "⚠ Egg",
  contains_fish: "⚠ Fish",
  contains_shellfish: "⚠ Shellfish",
  contains_pork: "⚠ Pork",
  contains_alcohol: "⚠ Alcohol",
  contains_chicken: "Chicken",
  contains_beef: "Beef",
};

function DetailImage({ dish }: { dish: Dish }) {
  const [loaded, setLoaded] = useState(false);
  const ready = dish.image_status === "ready" && dish.image_url;

  return (
    <div className="relative h-52 w-full shrink-0 overflow-hidden bg-canvas-alt md:h-auto md:w-[360px]">
      <div className={`absolute inset-0 shimmer ${ready && loaded ? "opacity-0" : ""}`} />
      {ready && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={imageUrl(dish.image_url)}
          alt={dish.name_english || dish.name_original}
          onLoad={() => setLoaded(true)}
          className={`absolute inset-0 h-full w-full object-cover transition-opacity duration-200 ${
            loaded ? "opacity-100" : "opacity-0"
          }`}
        />
      )}
    </div>
  );
}

function NutritionTiles({ dish }: { dish: Dish }) {
  if (!dish.nutrition) return null;
  const { calories, protein_g, carbs_g, fat_g } = dish.nutrition;
  const fmt = (n: number) => (n % 1 === 0 ? n : n.toFixed(1));
  const tiles = [
    { value: `${calories}`, unit: "kcal", text: "text-primary", bg: "bg-primary-tint" },
    { value: `${fmt(protein_g)}g`, unit: "protein", text: "text-success", bg: "bg-success-bg" },
    { value: `${fmt(carbs_g)}g`, unit: "carbs", text: "text-caution", bg: "bg-caution-bg" },
    { value: `${fmt(fat_g)}g`, unit: "fat", text: "text-category", bg: "bg-category-bg" },
  ];
  return (
    <div className="grid grid-cols-4 gap-2">
      {tiles.map((t) => (
        <div key={t.unit} className={`rounded-xl px-2 py-3 text-center ${t.bg}`}>
          <p className={`font-display text-lg font-extrabold leading-none ${t.text}`}>
            {t.value}
          </p>
          <p className="mt-1 text-[11px] font-medium text-body">{t.unit}</p>
        </div>
      ))}
    </div>
  );
}

/**
 * Shared dish-detail body. `variant="modal"` shows the ✕ close button; both
 * variants lay the photo beside the info on desktop and stack on mobile.
 */
export function DishDetailContent({
  dish,
  variant = "page",
  onClose,
  enrichmentPending = false,
}: {
  dish: Dish;
  variant?: "modal" | "page";
  onClose?: () => void;
  /** The second-pass enrichment (about + nutrition) may still be arriving —
   * show shimmer placeholders for those sections until it does. */
  enrichmentPending?: boolean;
}) {
  const tags = dish.dietary_tags ?? [];
  const allergens = tags.filter((t) => t.startsWith("contains_"));
  const positive = tags.filter((t) => !t.startsWith("contains_"));
  const hasTranslation =
    dish.name_english && dish.name_english !== dish.name_original;

  return (
    <div className="flex h-full flex-col overflow-hidden md:flex-row">
      <DetailImage dish={dish} />

      <div className="relative flex-1 overflow-y-auto p-6">
        {variant === "modal" && onClose && (
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="absolute right-4 top-4 flex h-9 w-9 items-center justify-center rounded-full bg-canvas-alt text-body hover:bg-border"
          >
            <X className="h-4 w-4" aria-hidden="true" />
          </button>
        )}

        {dish.category_english && (
          <span className="inline-block rounded-full bg-category-bg px-2.5 py-1 text-[11px] font-bold uppercase tracking-wide text-category">
            {dish.category_english}
          </span>
        )}

        <h2 className="mt-3 pr-10 font-display text-[30px] font-extrabold leading-[1.1] tracking-[-0.025em] text-ink">
          {hasTranslation ? dish.name_english : dish.name_original}
        </h2>
        {hasTranslation && (
          <p className="mt-0.5 text-sm italic text-muted">{dish.name_original}</p>
        )}

        {dish.price && (
          <p className="mt-2 font-display text-[26px] font-extrabold text-primary">
            {dish.price}
          </p>
        )}

        {(dish.description_english || dish.description_original) && (
          <div className="mt-2 space-y-0.5">
            {dish.description_english && (
              <p className="text-sm leading-relaxed text-body">
                {dish.description_english}
              </p>
            )}
            {dish.description_original &&
              dish.description_original !== dish.description_english && (
                <p className="text-sm italic leading-relaxed text-muted">
                  {dish.description_original}
                </p>
              )}
          </div>
        )}

        {dish.about ? (
          <div className="mt-4 space-y-1.5">
            <h3 className="text-[11px] font-bold uppercase tracking-widest text-muted-2">
              About this dish
            </h3>
            <p className="text-sm leading-relaxed text-body">{dish.about}</p>
          </div>
        ) : enrichmentPending ? (
          <div className="mt-4 space-y-1.5">
            <h3 className="text-[11px] font-bold uppercase tracking-widest text-muted-2">
              About this dish
            </h3>
            <div className="space-y-2 pt-1" aria-hidden="true">
              <div className="shimmer h-3 w-full rounded" />
              <div className="shimmer h-3 w-full rounded" />
              <div className="shimmer h-3 w-2/3 rounded" />
            </div>
          </div>
        ) : null}

        {tags.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {allergens.map((t) => (
              <span
                key={t}
                className="rounded-full bg-allergen-bg px-2.5 py-1 text-xs font-semibold text-allergen"
              >
                {TAG_LABELS[t] ?? t}
              </span>
            ))}
            {positive.map((t) => (
              <span
                key={t}
                className="rounded-full bg-success-bg px-2.5 py-1 text-xs font-semibold text-success"
              >
                {TAG_LABELS[t] ?? t}
              </span>
            ))}
          </div>
        )}

        {dish.nutrition ? (
          <>
            <div className="mt-5">
              <NutritionTiles dish={dish} />
            </div>
            <p className="mt-5 text-[11px] text-muted-2">
              AI estimates — may vary. For allergies, verify with the restaurant.
            </p>
          </>
        ) : enrichmentPending ? (
          <div className="mt-5 grid grid-cols-4 gap-2" aria-hidden="true">
            {[0, 1, 2, 3].map((i) => (
              <div key={i} className="shimmer h-[62px] rounded-xl" />
            ))}
          </div>
        ) : null}
      </div>
    </div>
  );
}
