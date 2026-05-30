"use client";

import type { Menu } from "@/lib/types";

import { DishCard } from "./DishCard";

interface Props {
  menu: Menu;
}

export function MenuDisplay({ menu }: Props) {
  const grouped = menu.dishes.reduce<Record<string, typeof menu.dishes>>(
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
        <h2 className="text-2xl font-bold">{menu.restaurant_name}</h2>
      )}

      <p className="text-sm text-muted-foreground">
        Source language: {menu.source_language} · {menu.dishes.length} dishes
      </p>

      {/* Sticky category navigation — only when there is more than one category */}
      {categories.length > 1 && (
        <nav className="sticky top-0 z-10 -mx-4 border-b bg-background/95 px-4 py-2 backdrop-blur supports-[backdrop-filter]:bg-background/80">
          <div className="flex gap-2 overflow-x-auto whitespace-nowrap pb-1">
            {categories.map((category, index) => (
              <button
                key={category}
                onClick={() => scrollToCategory(index)}
                className="shrink-0 rounded-full border bg-card px-3 py-1 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
              >
                {category}
              </button>
            ))}
          </div>
        </nav>
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
            <div className="mb-3">
              <h3 className="text-lg font-semibold">{category}</h3>
              {showEnglish && (
                <p className="text-sm italic text-muted-foreground">
                  {categoryEnglish}
                </p>
              )}
            </div>
            <div className="space-y-2">
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