import Image from "next/image";

import { cn } from "@/lib/utils";

/**
 * The MenuMind brand icon (camera + plate + 文A on the Hot Dish gradient).
 * Rendered as a rounded square with the spec's ~22% corner radius. Used in the
 * sidebar, headers and the loading-orbit center.
 */
export function BrandMark({
  size = 28,
  className,
}: {
  size?: number;
  className?: string;
}) {
  return (
    <Image
      src="/brand-icon.png"
      alt="MenuMind"
      width={size}
      height={size}
      priority
      className={cn("rounded-[22%]", className)}
    />
  );
}
