import Link from "next/link";

interface Props {
  /** Wraps the wordmark in a link to home (used on inner pages). */
  asLink?: boolean;
}

/** Small dill leaf — the Beet & Cream brand accent next to the wordmark. */
function DillLeaf() {
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 20 20"
      aria-hidden="true"
      className="ml-1.5 inline-block -translate-y-2.5 text-dill"
    >
      <g transform="rotate(-18 10 10)">
        <path
          d="M3 17 C3 9 9 3 17 3 C17 11 11 17 3 17 Z"
          fill="currentColor"
        />
        <path
          d="M5.5 14.5 C8.5 11.5 11.5 8.5 14.5 5.5"
          fill="none"
          stroke="hsl(var(--background))"
          strokeWidth="0.9"
          strokeLinecap="round"
        />
      </g>
    </svg>
  );
}

/** menumind wordmark, lowercase with a dill leaf — Beet & Cream brand mark. */
export function Wordmark({ asLink = false }: Props) {
  const mark = (
    <span className="font-sans text-4xl font-medium tracking-tight text-coral">
      menumind
      <DillLeaf />
    </span>
  );

  return (
    <header className="mb-8">
      <h1 className="leading-none">
        {asLink ? <Link href="/">{mark}</Link> : mark}
      </h1>
      <p className="mt-2 text-muted-foreground">
        Eat with confidence, anywhere in the world.
      </p>
    </header>
  );
}
