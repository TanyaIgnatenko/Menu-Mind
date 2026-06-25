import Link from "next/link";

import { Button } from "@/components/ui/button";
import type { Menu } from "@/lib/types";

import { ShareButton } from "./ShareButton";

/**
 * Menu top bar (sticky, surface, bottom border): restaurant name + meta on the
 * left; Share + New scan on the right.
 */
export function TopBar({ menu }: { menu: Menu }) {
  const meta = [
    `${menu.dishes.length} ${menu.dishes.length === 1 ? "dish" : "dishes"}`,
    menu.cuisine_type,
    "translated to English",
  ]
    .filter(Boolean)
    .join(" · ");

  return (
    <div className="sticky top-0 z-10 border-b border-border bg-surface/90 backdrop-blur supports-[backdrop-filter]:bg-surface/75">
      <div className="mx-auto flex max-w-[1340px] items-center gap-3 px-5 py-3.5 md:px-8">
        <div className="min-w-0 flex-1">
          <h1 className="truncate font-display text-xl font-extrabold tracking-[-0.02em] text-ink">
            {menu.restaurant_name || "Menu"}
          </h1>
          <p className="truncate text-xs text-muted-2">{meta}</p>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <ShareButton menuId={menu.id} />
          <Link href="/" className="hidden sm:block">
            <Button>New scan</Button>
          </Link>
        </div>
      </div>
    </div>
  );
}
