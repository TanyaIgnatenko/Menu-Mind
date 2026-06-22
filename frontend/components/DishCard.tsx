"use client";

import { useState } from "react";
import { AlertCircle } from "lucide-react";

import { imageUrl } from "@/lib/api";
import type { Dish } from "@/lib/types";
import { DishDetail } from "./DishDetail";

interface Props {
  dish: Dish;
}

const IMAGE_WRAPPER = "aspect-[4/3] w-full";

function ImageBlock({ dish }: { dish: Dish }) {
  if (dish.image_status === "ready" && dish.image_url) {
    return (
      <div className={`${IMAGE_WRAPPER} overflow-hidden`}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={imageUrl(dish.image_url)}
          alt={dish.name_english || dish.name_original}
          loading="lazy"
          className="h-full w-full object-cover transition-transform duration-300 hover:scale-[1.03]"
        />
      </div>
    );
  }

  if (dish.image_status === "failed") {
    return (
      <div
        className={`${IMAGE_WRAPPER} flex flex-col items-center justify-center gap-1 bg-muted p-3 text-center`}
        title={dish.image_error || "Generation failed"}
      >
        <AlertCircle className="h-5 w-5 text-coral/70" aria-hidden="true" />
        <span className="line-clamp-2 text-xs leading-tight text-muted-foreground">
          No image for this dish
        </span>
      </div>
    );
  }

  return <div className={`${IMAGE_WRAPPER} shimmer`} />;
}

export function DishCard({ dish }: Props) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <article
        className="rise-in overflow-hidden rounded-lg bg-card shadow-card transition-shadow hover:shadow-card-hover cursor-pointer"
        onClick={() => setOpen(true)}
      >
        <ImageBlock dish={dish} />

        <div className="flex flex-col p-5">
          {/* Name + price with leader dots */}
          <div className="flex items-baseline gap-2">
            <h3 className="font-display text-lg font-semibold leading-snug text-navy">
              {dish.name_original}
            </h3>
            {dish.price && (
              <>
                <span className="price-leader" aria-hidden="true" />
                <span className="whitespace-nowrap font-display font-semibold text-navy">
                  {dish.price}
                </span>
              </>
            )}
          </div>

          {dish.name_english && dish.name_english !== dish.name_original && (
            <p className="mt-0.5 font-display text-sm italic text-muted-foreground">
              {dish.name_english}
            </p>
          )}

          {dish.description_original && (
            <div className="mt-2 space-y-1">
              <p className="text-sm leading-relaxed">
                {dish.description_original}
              </p>
              {dish.description_english &&
                dish.description_english !== dish.description_original && (
                  <p className="text-sm italic leading-relaxed text-muted-foreground">
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

          {/* Hint to tap */}
          <p className="mt-3 text-xs text-muted-foreground/60">
            Tap for details, nutrition & fun facts →
          </p>
        </div>
      </article>

      {open && <DishDetail dish={dish} onClose={() => setOpen(false)} />}
    </>
  );
}
