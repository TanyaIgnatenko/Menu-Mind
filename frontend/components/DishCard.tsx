import { Card, CardContent } from "@/components/ui/card";
import { imageUrl } from "@/lib/api";
import type { Dish } from "@/lib/types";

interface Props {
  dish: Dish;
}

function ImageBlock({ dish }: { dish: Dish }) {
  if (dish.image_status === "ready" && dish.image_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return (
      <img
        src={imageUrl(dish.image_url)}
        alt={dish.name_english || dish.name_original}
        className="h-24 w-24 flex-shrink-0 rounded-md object-cover"
      />
    );
  }

  if (dish.image_status === "failed") {
    return (
      <div
        className="flex h-24 w-24 flex-shrink-0 flex-col items-center justify-center gap-1 rounded-md border border-destructive/30 bg-destructive/10 p-2 text-center"
        title={dish.image_error || "Generation failed"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="text-destructive/70"
        >
          <circle cx="12" cy="12" r="10" />
          <line x1="12" y1="8" x2="12" y2="12" />
          <line x1="12" y1="16" x2="12.01" y2="16" />
        </svg>
        <span className="line-clamp-2 text-[10px] leading-tight text-destructive/80">
          {dish.image_error || "Failed"}
        </span>
      </div>
    );
  }

  // pending or generating - animated shimmer
  return (
    <div className="shimmer h-24 w-24 flex-shrink-0 rounded-md" />
  );
}

export function DishCard({ dish }: Props) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex items-start gap-4">
          <ImageBlock dish={dish} />

          <div className="flex flex-1 items-start justify-between gap-4">
            <div className="flex-1">
              <h3 className="font-semibold">{dish.name_original}</h3>
              {dish.name_english && dish.name_english !== dish.name_original && (
                <p className="text-sm italic text-muted-foreground">
                  {dish.name_english}
                </p>
              )}

              {dish.description_original && (
                <div className="mt-2 space-y-1">
                  <p className="text-sm">{dish.description_original}</p>
                  {dish.description_english &&
                    dish.description_english !== dish.description_original && (
                      <p className="text-sm italic text-muted-foreground">
                        {dish.description_english}
                      </p>
                    )}
                </div>
              )}

              {dish.size && (
                <p className="mt-2 text-xs text-muted-foreground">
                  Size: {dish.size}
                </p>
              )}
            </div>

            {dish.price && (
              <span className="whitespace-nowrap font-medium">{dish.price}</span>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
