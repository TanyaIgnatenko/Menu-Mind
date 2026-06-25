"use client";

import { useEffect, useState } from "react";

/**
 * Subscribe to a CSS media query. Returns false during SSR / first paint
 * (mobile-first), then corrects after mount.
 */
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const mql = window.matchMedia(query);
    setMatches(mql.matches);
    const handler = (e: MediaQueryListEvent) => setMatches(e.matches);
    mql.addEventListener("change", handler);
    return () => mql.removeEventListener("change", handler);
  }, [query]);

  return matches;
}

/** True at the desktop sidebar breakpoint (matches Tailwind's `nav` screen). */
export function useIsDesktop(): boolean {
  return useMediaQuery("(min-width: 860px)");
}
