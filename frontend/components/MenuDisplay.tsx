"use client";

import { useMemo, useState } from "react";

import type { Menu } from "@/lib/types";

import { DietaryFilters, filterDishes } from "./DietaryFilters";
import { DishCard } from "./DishCard";

interface Props {
  menu: Menu;
}

export function MenuDisplay({ menu }: Props) {
  const [activeFilters, setActiveFilters] = useState<Set<string>>(new Set());

  const toggleFilter = (filterId: string) => {
    setActiveFilters((prev) => {
      const next = new Set(prev);
      if (next.has(filterId)) {
        next.delete(filterId);
      } else {
        next.add(filterId);
      }
      return next;
    });
  };

  const filteredDishes = useMemo(
    () => filterDishes(menu.dishes, activeFilters),
    [menu.dishes, activeFilters],
  );

  const grouped = filteredDishes.reduce<Record<string, typeof menu.dishes>>(
    (acc, dish) => {
      const cat = dish.category || "Other";
      if (!acc[cat]) acc[cat] = [];
      acc[cat].push(dish);
      return acc;
    },
    {},
  );

  const categories = Object.keys(grouped);

  const scrollToCategory = (index: number) => {
    document
      .getElementById(`category-${index}`)
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <div className="space-y-6">
      {menu.restaurant_name && (
        <h2 className="font-display text-2xl font-bold text-navy md:text-3xl">
          {menu.restaurant_name}
        </h2>
      )}

      <p className="text-sm text-muted-foreground">
        Source language: {menu.source_language} · {menu.dishes.length} dishes
      </p>

      <DietaryFilters
        dishes={menu.dishes}
        active={activeFilters}
        onToggle={toggleFilter}
        shownCount={filteredDishes.length}
      />

      {/* Sticky category navigation — only when there is more than one category */}
      {categories.length > 1 && (
        <nav className="sticky top-0 z-10 -mx-4 border-b border-border/70 bg-background/90 px-4 py-2.5 backdrop-blur supports-[backdrop-filter]:bg-background/75">
          <div className="flex gap-2 overflow-x-auto whitespace-nowrap pb-1">
            {categories.map((category, index) => (
              <button
                key={category}
                onClick={() => scrollToCategory(index)}
                className="shrink-0 rounded-full border border-navy/20 bg-card px-3.5 py-1.5 text-sm font-medium text-navy transition-colors hover:border-coral hover:text-coral"
              >
                {category}
              </button>
            ))}
          </div>
        </nav>
      )}

      {filteredDishes.length === 0 && activeFilters.size > 0 && (
        <div className="rounded-lg border-2 border-dashed border-gold bg-gold/20 p-8 text-center">
          <p className="font-display text-lg text-navy">
            No dishes match the selected filters.
          </p>
          <button
            type="button"
            onClick={() => setActiveFilters(new Set())}
            className="mt-3 text-sm font-semibold text-coral underline-offset-4 hover:underline"
          >
            Clear filters
          </button>
        </div>
      )}

      {categories.map((category, index) => {
        const dishes = grouped[category];
        // English translation of the category, taken from the first dish in
        // the group (all dishes in a group share the same category).
        const categoryEnglish = dishes[0]?.category_english ?? "";
        const showEnglish =
          categoryEnglish && categoryEnglish.toLowerCase() !== category.toLowerCase();

        return (
          <section key={category} id={`category-${index}`} className="scroll-mt-20">
            <div className="mb-4">
              <h3 className="font-display text-xl font-semibold text-navy">
                {category}
              </h3>
              {showEnglish && (
                <p className="font-display text-sm italic text-muted-foreground">
                  {categoryEnglish}
                </p>
              )}
              <div
                className="mt-2 h-1 w-10 rounded-full bg-coral"
                aria-hidden="true"
              />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              {dishes.map((dish, i) => (
                <DishCard key={`${category}-${i}`} dish={dish} />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}
