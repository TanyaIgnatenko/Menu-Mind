"use client";

import { useMemo, useState } from "react";

import { capture } from "@/lib/posthog";
import type { Dish, Menu } from "@/lib/types";

import { DishCard } from "./DishCard";

interface Props {
  menu: Menu;
}

type FilterMode = "require" | "exclude";
interface FilterDef {
  id: string;
  label: string;
  emoji: string;
  tags: string[];
  mode: FilterMode;
}

// The six dietary chips from the spec's filter bar (with the spec emojis).
const FILTERS: FilterDef[] = [
  { id: "vegetarian", label: "Vegetarian", emoji: "🥗", tags: ["vegetarian"], mode: "require" },
  { id: "vegan", label: "Vegan", emoji: "🌱", tags: ["vegan"], mode: "require" },
  { id: "gluten_free", label: "Gluten-free", emoji: "🌾", tags: ["contains_gluten"], mode: "exclude" },
  { id: "spicy", label: "Spicy", emoji: "🌶️", tags: ["spicy"], mode: "require" },
  { id: "sweet", label: "Sweet", emoji: "🍯", tags: ["sweet"], mode: "require" },
  { id: "healthy", label: "Healthy", emoji: "💪", tags: ["healthy", "low_calorie"], mode: "require" },
];

function matches(dish: Dish, f: FilterDef): boolean {
  const tags = dish.dietary_tags ?? [];
  return f.tags.some((t) => tags.includes(t));
}

interface DishRef {
  dish: Dish;
  index: number;
}

export function MenuDisplay({ menu }: Props) {
  const [active, setActive] = useState<Set<string>>(new Set());

  const indexed: DishRef[] = useMemo(
    () => menu.dishes.map((dish, index) => ({ dish, index })),
    [menu.dishes],
  );

  // Only offer a chip when at least one dish makes it meaningful.
  const availableFilters = useMemo(() => {
    const present = new Set<string>();
    for (const { dish } of indexed)
      for (const t of dish.dietary_tags ?? []) present.add(t);
    return FILTERS.filter((f) => f.tags.some((t) => present.has(t)));
  }, [indexed]);

  const filtered = useMemo(() => {
    if (active.size === 0) return indexed;
    const on = FILTERS.filter((f) => active.has(f.id));
    return indexed.filter(({ dish }) =>
      on.every((f) =>
        f.mode === "require" ? matches(dish, f) : !matches(dish, f),
      ),
    );
  }, [indexed, active]);

  const grouped = useMemo(() => {
    const map = new Map<string, DishRef[]>();
    for (const ref of filtered) {
      const cat = ref.dish.category || "Dishes";
      if (!map.has(cat)) map.set(cat, []);
      map.get(cat)!.push(ref);
    }
    return Array.from(map.entries());
  }, [filtered]);

  function toggle(f: FilterDef) {
    const activating = !active.has(f.id);
    capture("filter_applied", {
      filter_id: f.id,
      filter_label: f.label,
      filter_group: f.mode === "exclude" ? "needs" : "prefs",
      active_count: active.size + (activating ? 1 : -1),
    });
    setActive((prev) => {
      const next = new Set(prev);
      if (next.has(f.id)) next.delete(f.id);
      else next.add(f.id);
      return next;
    });
  }

  return (
    <div className="space-y-6">
      {/* Filter bar */}
      {availableFilters.length > 0 && (
        <div className="flex flex-wrap items-center gap-2">
          <span className="mr-1 text-[11px] font-bold uppercase tracking-widest text-muted-2">
            Filter
          </span>
          {availableFilters.map((f) => {
            const isActive = active.has(f.id);
            return (
              <button
                key={f.id}
                type="button"
                aria-pressed={isActive}
                onClick={() => toggle(f)}
                className={`rounded-full border px-3.5 py-1.5 text-[13px] font-semibold transition-colors ${
                  isActive
                    ? "border-success bg-success text-white"
                    : "border-border bg-surface text-ink hover:border-success/60"
                }`}
              >
                <span aria-hidden="true">{f.emoji}</span> {f.label}
              </button>
            );
          })}
          {active.size > 0 && (
            <button
              type="button"
              onClick={() => setActive(new Set())}
              className="ml-1 text-[13px] font-semibold text-primary underline-offset-4 hover:underline"
            >
              Clear
            </button>
          )}
        </div>
      )}

      {filtered.length === 0 && (
        <div className="rounded-2xl border border-dashed border-border bg-surface p-10 text-center">
          <p className="font-display text-lg font-bold text-ink">
            No dishes match these filters
          </p>
          <button
            type="button"
            onClick={() => setActive(new Set())}
            className="mt-2 text-sm font-semibold text-primary hover:underline"
          >
            Clear filters
          </button>
        </div>
      )}

      {grouped.map(([category, refs]) => (
        <section key={category}>
          <div className="mb-4">
            <h2 className="font-display text-xl font-extrabold tracking-tight text-ink">
              {category}
            </h2>
            <div className="mt-1.5 h-1 w-9 rounded-full bg-primary" aria-hidden="true" />
          </div>
          {/* Mobile web: single-column dish rows */}
          <div className="flex flex-col gap-3 nav:hidden">
            {refs.map(({ dish, index }) => (
              <DishCard
                key={index}
                dish={dish}
                menuId={menu.id}
                index={index}
                variant="row"
              />
            ))}
          </div>
          {/* Desktop: responsive grid (2 → 3 → 4 columns) */}
          <div className="hidden gap-4 nav:grid nav:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {refs.map(({ dish, index }) => (
              <DishCard
                key={index}
                dish={dish}
                menuId={menu.id}
                index={index}
                variant="card"
              />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
