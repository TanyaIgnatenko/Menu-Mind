"use client";

import type { Dish } from "@/lib/types";

type FilterMode = "exclude" | "require";
type FilterGroup = "needs" | "prefs";

interface FilterDef {
  id: string;
  label: string;
  tags: string[]; // filter matches a dish if the dish has ANY of these tags
  mode: FilterMode;
  group: FilterGroup;
}

// Order = display order within each group.
// "needs": restrictions, combined with AND (all must hold).
// "prefs": positive preferences, combined with OR (any match shows the dish).
const FILTERS: FilterDef[] = [
  // --- Dietary needs (AND) ---
  { id: "vegetarian", label: "Vegetarian", tags: ["vegetarian"], mode: "require", group: "needs" },
  { id: "vegan", label: "Vegan", tags: ["vegan"], mode: "require", group: "needs" },
  { id: "no_pork", label: "No pork", tags: ["contains_pork"], mode: "exclude", group: "needs" },
  { id: "no_nuts", label: "No nuts", tags: ["contains_nuts"], mode: "exclude", group: "needs" },
  { id: "no_gluten", label: "No gluten", tags: ["contains_gluten"], mode: "exclude", group: "needs" },
  { id: "no_dairy", label: "No dairy", tags: ["contains_dairy"], mode: "exclude", group: "needs" },
  { id: "no_eggs", label: "No eggs", tags: ["contains_eggs"], mode: "exclude", group: "needs" },
  { id: "no_fish", label: "No fish", tags: ["contains_fish"], mode: "exclude", group: "needs" },
  { id: "no_shellfish", label: "No shellfish", tags: ["contains_shellfish"], mode: "exclude", group: "needs" },
  { id: "no_alcohol", label: "No alcohol", tags: ["contains_alcohol"], mode: "exclude", group: "needs" },
  { id: "no_spicy", label: "No spicy", tags: ["spicy"], mode: "exclude", group: "needs" },
  { id: "no_sweet", label: "No sweet", tags: ["sweet"], mode: "exclude", group: "needs" },
  // --- Preferences (OR) ---
  { id: "spicy", label: "Spicy", tags: ["spicy"], mode: "require", group: "prefs" },
  { id: "sweet", label: "Sweet", tags: ["sweet"], mode: "require", group: "prefs" },
  { id: "chicken", label: "Chicken", tags: ["contains_chicken"], mode: "require", group: "prefs" },
  { id: "beef", label: "Beef", tags: ["contains_beef"], mode: "require", group: "prefs" },
  { id: "pork", label: "Pork", tags: ["contains_pork"], mode: "require", group: "prefs" },
  { id: "turkey", label: "Turkey", tags: ["contains_turkey"], mode: "require", group: "prefs" },
  { id: "fish", label: "Fish", tags: ["contains_fish"], mode: "require", group: "prefs" },
  { id: "seafood", label: "Seafood", tags: ["contains_fish", "contains_shellfish"], mode: "require", group: "prefs" },
  { id: "low_calorie", label: "Low-calorie", tags: ["low_calorie"], mode: "require", group: "prefs" },
];

function dishTags(dish: Dish): string[] {
  return dish.dietary_tags ?? [];
}

function matches(dish: Dish, filter: FilterDef): boolean {
  const tags = dishTags(dish);
  return filter.tags.some((t) => tags.includes(t));
}

/** Filters worth showing for this menu: at least one of their tags occurs in a dish. */
export function availableFilters(dishes: Dish[]): FilterDef[] {
  const present = new Set<string>();
  for (const dish of dishes) {
    for (const tag of dishTags(dish)) present.add(tag);
  }
  return FILTERS.filter((f) => f.tags.some((t) => present.has(t)));
}

/**
 * Apply active filters (by filter id).
 * - "needs" (vegetarian, No pork, ...): every active one must hold (AND)
 * - "prefs" (Chicken, Seafood, ...): dish must match at least one active (OR)
 */
export function filterDishes(dishes: Dish[], activeIds: Set<string>): Dish[] {
  if (activeIds.size === 0) return dishes;

  const active = FILTERS.filter((f) => activeIds.has(f.id));
  const needs = active.filter((f) => f.group === "needs");
  const prefs = active.filter((f) => f.group === "prefs");

  return dishes.filter((dish) => {
    for (const f of needs) {
      if (f.mode === "exclude" && matches(dish, f)) return false;
      if (f.mode === "require" && !matches(dish, f)) return false;
    }

    if (prefs.length > 0) {
      const matchesAny = prefs.some((f) => matches(dish, f));
      if (!matchesAny) return false;
    }

    return true;
  });
}

interface DietaryFiltersProps {
  dishes: Dish[];
  active: Set<string>;
  onToggle: (filterId: string) => void;
  shownCount: number;
}

function ChipRow({
  title,
  filters,
  active,
  onToggle,
}: {
  title: string;
  filters: FilterDef[];
  active: Set<string>;
  onToggle: (id: string) => void;
}) {
  if (filters.length === 0) return null;
  return (
    <div className="space-y-1.5">
      <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
        {title}
      </p>
      <div className="flex flex-wrap gap-2">
        {filters.map((f) => {
          const isActive = active.has(f.id);
          return (
            <button
              key={f.id}
              type="button"
              onClick={() => onToggle(f.id)}
              className={
                "rounded-full border px-3 py-1 text-sm transition-colors " +
                (isActive
                  ? "border-primary bg-primary text-primary-foreground"
                  : "border-input bg-background hover:bg-accent")
              }
            >
              {f.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export function DietaryFilters({
  dishes,
  active,
  onToggle,
  shownCount,
}: DietaryFiltersProps) {
  const available = availableFilters(dishes);
  if (available.length === 0) return null;

  const needs = available.filter((f) => f.group === "needs");
  const prefs = available.filter((f) => f.group === "prefs");

  return (
    <div className="space-y-3">
      <ChipRow title="Dietary needs" filters={needs} active={active} onToggle={onToggle} />
      <ChipRow title="Show me" filters={prefs} active={active} onToggle={onToggle} />
      {active.size > 0 && (
        <p className="text-xs text-muted-foreground">
          Showing {shownCount} of {dishes.length} dishes
        </p>
      )}
      <p className="text-xs text-muted-foreground">
        Tags are AI-generated and may be inaccurate. For serious allergies,
        always verify with the restaurant.
      </p>
    </div>
  );
}