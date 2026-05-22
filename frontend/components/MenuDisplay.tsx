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

  return (
    <div className="space-y-6">
      {menu.restaurant_name && (
        <h2 className="text-2xl font-bold">{menu.restaurant_name}</h2>
      )}

      <p className="text-sm text-muted-foreground">
        Source language: {menu.source_language} · {menu.dishes.length} dishes
      </p>

      {Object.entries(grouped).map(([category, dishes]) => {
        // English translation of the category, taken from the first dish in
        // the group (all dishes in a group share the same category).
        const categoryEnglish = dishes[0]?.category_english ?? "";
        const showEnglish =
          categoryEnglish && categoryEnglish.toLowerCase() !== category.toLowerCase();

        return (
          <section key={category}>
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