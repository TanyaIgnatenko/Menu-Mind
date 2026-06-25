import { BrandMark } from "./BrandMark";

const ORBIT = ["🍝", "🥗", "🍰", "🍷"];

// Four edge positions around the ring; the ring spins and each item
// counter-rotates (.orbit-item) so the emoji stays upright.
const POS = [
  "left-1/2 top-0 -translate-x-1/2",
  "right-0 top-1/2 -translate-y-1/2",
  "left-1/2 bottom-0 -translate-x-1/2",
  "left-0 top-1/2 -translate-y-1/2",
];

interface Props {
  caption?: string;
  subcaption?: string;
  /** 0–1; omit for an indeterminate-looking near-full bar. */
  progress?: number;
}

/**
 * Hot-Dish loading state — the brand icon at the center of a ring of orbiting
 * dish emojis, a caption, and a primary progress bar. Mirrors the mobile loader.
 */
export function LoadingOrbit({
  caption = "Cooking up your menu",
  subcaption,
  progress,
}: Props) {
  const pct = Math.round(Math.min(Math.max(progress ?? 0.12, 0), 1) * 100);

  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="relative mx-auto h-[220px] w-[220px]">
        <div className="orbit-ring absolute inset-0">
          {ORBIT.map((emoji, i) => (
            <span key={i} className={`absolute ${POS[i]}`}>
              <span className="orbit-item flex h-11 w-11 items-center justify-center rounded-full bg-surface text-xl shadow-card">
                {emoji}
              </span>
            </span>
          ))}
        </div>
        <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
          <BrandMark size={72} className="shadow-float" />
        </div>
      </div>

      <h2 className="mt-8 font-display text-xl font-extrabold tracking-tight text-ink">
        {caption}
      </h2>
      {subcaption && (
        <p className="mt-1 text-sm text-body" aria-live="polite">
          {subcaption}
        </p>
      )}

      <div
        className="mt-5 h-2 w-full max-w-xs overflow-hidden rounded-full bg-primary-tint"
        role="progressbar"
        aria-valuenow={pct}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="h-full rounded-full bg-primary transition-[width] duration-500 ease-out"
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}
