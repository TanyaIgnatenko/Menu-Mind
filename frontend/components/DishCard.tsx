import { Card } from "@/components/ui/card";
import { imageUrl } from "@/lib/api";
import type { Dish } from "@/lib/types";

interface Props {
  dish: Dish;
}

// Mobile: full-width image on top. Desktop: fixed-width image on the left that
// stretches to match the card's height.
const IMAGE_WRAPPER = "h-52 w-full md:h-auto md:min-h-[13rem] md:w-72 md:shrink-0";

function ImageBlock({ dish }: { dish: Dish }) {
  if (dish.image_status === "ready" && dish.image_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return (
      <div className={IMAGE_WRAPPER}>
        <img
          src={imageUrl(dish.image_url)}
          alt={dish.name_english || dish.name_original}
          className="h-full w-full object-cover"
        />
      </div>
    );
  }

  if (dish.image_status === "failed") {
    return (
      <div
        className={`${IMAGE_WRAPPER} flex flex-col items-center justify-center gap-1 bg-destructive/10 p-2 text-center`}
        title={dish.image_error || "Generation failed"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
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
        <span className="line-clamp-2 text-xs leading-tight text-destructive/80">
          {dish.image_error || "Failed"}
        </span>
      </div>
    );
  }

  // pending or generating — animated shimmer
  return <div className={`${IMAGE_WRAPPER} shimmer`} />;
}

export function DishCard({ dish }: Props) {
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-col md:flex-row">
        <ImageBlock dish={dish} />

        <div className="flex flex-1 flex-col p-5">
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1">
              <h3 className="text-lg font-bold">{dish.name_original}</h3>
              {dish.name_english && dish.name_english !== dish.name_original && (
                <p className="text-sm italic text-muted-foreground">
                  {dish.name_english}
                </p>
              )}
            </div>
            {dish.price && (
              <span className="whitespace-nowrap font-medium">{dish.price}</span>
            )}
          </div>

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
            <p className="mt-2 text-xs text-muted-foreground">Size: {dish.size}</p>
          )}
          
        </div>
      </div>
    </Card>
  );
}