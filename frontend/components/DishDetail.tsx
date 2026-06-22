"use client";

import { imageUrl } from "@/lib/api";
import type { Dish } from "@/lib/types";

interface Props {
  dish: Dish;
  onClose: () => void;
}

const TAG_LABELS: Record<string, string> = {
  vegan: "Vegan",
  vegetarian: "Vegetarian",
  contains_gluten: "Contains gluten",
  contains_dairy: "Contains dairy",
  contains_nuts: "Contains nuts",
  contains_eggs: "Contains eggs",
  contains_fish: "Contains fish",
  contains_shellfish: "Contains shellfish",
  contains_pork: "Contains pork",
  contains_alcohol: "Contains alcohol",
  contains_chicken: "Contains chicken",
  contains_beef: "Contains beef",
  spicy: "Spicy",
  sweet: "Sweet",
  low_calorie: "Low calorie",
  healthy: "Healthy",
};

function NutritionCard({ dish }: { dish: Dish }) {
  if (!dish.nutrition) return null;
  const { calories, protein_g, carbs_g, fat_g } = dish.nutrition;

  return (
    <div className="rounded-lg border bg-card p-5 shadow-card">
      <h3 className="mb-4 text-xs font-semibold uppercase tracking-widest text-muted-foreground">
        Nutrition · estimated per serving
      </h3>

      {/* Calories */}
      <div className="mb-4 flex items-baseline justify-center gap-1">
        <span className="font-display text-5xl font-bold text-navy">
          {calories}
        </span>
        <span className="text-sm text-muted-foreground">kcal</span>
      </div>

      <div className="mb-4 border-t" />

      {/* Macros */}
      <div className="grid grid-cols-3 divide-x text-center">
        <div className="px-3">
          <p className="font-display text-xl font-bold text-blue-700">
            {protein_g % 1 === 0 ? protein_g : protein_g.toFixed(1)}
            <span className="text-sm font-normal">g</span>
          </p>
          <p className="mt-0.5 text-xs text-muted-foreground">Protein</p>
        </div>
        <div className="px-3">
          <p className="font-display text-xl font-bold text-amber-800">
            {carbs_g % 1 === 0 ? carbs_g : carbs_g.toFixed(1)}
            <span className="text-sm font-normal">g</span>
          </p>
          <p className="mt-0.5 text-xs text-muted-foreground">Carbs</p>
        </div>
        <div className="px-3">
          <p className="font-display text-xl font-bold text-[#5E7D4A]">
            {fat_g % 1 === 0 ? fat_g : fat_g.toFixed(1)}
            <span className="text-sm font-normal">g</span>
          </p>
          <p className="mt-0.5 text-xs text-muted-foreground">Fat</p>
        </div>
      </div>

      <p className="mt-4 text-center text-xs text-muted-foreground">
        AI estimates — may vary. Not for medical use.
      </p>
    </div>
  );
}

export function DishDetail({ dish, onClose }: Props) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Panel */}
      <div className="relative z-10 flex max-h-[92dvh] w-full max-w-lg flex-col overflow-hidden rounded-t-2xl bg-background sm:rounded-2xl">
        {/* Close pill */}
        <div className="flex justify-center pt-3 pb-1">
          <button
            onClick={onClose}
            className="h-1 w-10 rounded-full bg-muted-foreground/30 hover:bg-muted-foreground/50"
            aria-label="Close"
          />
        </div>

        {/* Scrollable content */}
        <div className="overflow-y-auto">
          {/* Hero image */}
          {dish.image_status === "ready" && dish.image_url ? (
            <div className="aspect-[4/3] w-full overflow-hidden">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={imageUrl(dish.image_url)}
                alt={dish.name_english || dish.name_original}
                className="h-full w-full object-cover"
              />
            </div>
          ) : (
            <div className="aspect-[4/3] w-full shimmer" />
          )}

          <div className="space-y-5 p-5">
            {/* Name + price */}
            <div>
              {dish.name_english && dish.name_english !== dish.name_original && (
                <h2 className="font-display text-2xl font-bold leading-tight text-navy">
                  {dish.name_english}
                </h2>
              )}
              <div className="flex items-center gap-2">
                <p
                  className={`font-display italic text-muted-foreground ${
                    dish.name_english && dish.name_english !== dish.name_original
                      ? "text-base"
                      : "text-2xl font-bold not-italic text-navy"
                  }`}
                >
                  {dish.name_original}
                </p>
                {dish.price && (
                  <span className="ml-auto whitespace-nowrap rounded-full bg-coral px-3 py-1 text-sm font-semibold text-white">
                    {dish.price}
                  </span>
                )}
              </div>
              {dish.category_english && (
                <p className="mt-1 text-xs text-muted-foreground">
                  {dish.category_english}
                </p>
              )}
            </div>

            {/* Description */}
            {(dish.description_english || dish.description_original) && (
              <div className="space-y-1">
                <h3 className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">
                  About this dish
                </h3>
                {dish.description_english && (
                  <p className="text-sm leading-relaxed text-foreground">
                    {dish.description_english}
                  </p>
                )}
                {dish.description_original &&
                  dish.description_original !== dish.description_english && (
                    <p className="text-sm italic leading-relaxed text-muted-foreground">
                      {dish.description_original}
                    </p>
                  )}
              </div>
            )}

            {/* Fun facts */}
            {dish.fun_facts && dish.fun_facts.length > 0 && (
              <div className="space-y-3">
                <h3 className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">
                  Did you know?
                </h3>
                <ol className="space-y-2">
                  {dish.fun_facts.map((fact, i) => (
                    <li key={i} className="flex gap-3 text-sm leading-relaxed">
                      <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-coral/10 text-xs font-bold text-coral">
                        {i + 1}
                      </span>
                      <span>{fact}</span>
                    </li>
                  ))}
                </ol>
              </div>
            )}

            {/* Nutrition */}
            <NutritionCard dish={dish} />

            {/* Dietary tags */}
            {dish.dietary_tags && dish.dietary_tags.length > 0 && (
              <div className="space-y-2">
                <h3 className="text-xs font-semibold uppercase tracking-widest text-muted-foreground">
                  Dietary info
                </h3>
                <div className="flex flex-wrap gap-2">
                  {dish.dietary_tags.map((tag) => {
                    const isWarning = tag.startsWith("contains_");
                    return (
                      <span
                        key={tag}
                        className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                          isWarning
                            ? "bg-coral/10 text-coral"
                            : "bg-[#5E7D4A]/10 text-[#5E7D4A]"
                        }`}
                      >
                        {TAG_LABELS[tag] ?? tag}
                      </span>
                    );
                  })}
                </div>
                <p className="text-xs text-muted-foreground">
                  Tags are AI-generated. Always verify allergens with the restaurant.
                </p>
              </div>
            )}

            {/* Bottom padding for safe area */}
            <div className="h-4" />
          </div>
        </div>
      </div>
    </div>
  );
}
