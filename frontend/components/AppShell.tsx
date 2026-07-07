import type { ReactNode } from "react";

import Link from "next/link";

import { AppSidebar } from "./AppSidebar";
import { BrandMark } from "./BrandMark";
import { MobileBottomNav } from "./MobileBottomNav";

type NavKey = "scan" | "history";

/**
 * App layout: a persistent left sidebar on desktop (≥ nav breakpoint), and a
 * brand top bar + bottom tab bar on mobile web (like the native app). Pages
 * pass their active nav key and an optional `topBar` (e.g. the restaurant
 * header on the Menu screen).
 */
export function AppShell({
  active,
  topBar,
  children,
}: {
  active: NavKey;
  topBar?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className="min-h-screen bg-canvas-alt">
      <AppSidebar active={active} className="hidden nav:flex" />

      {/* Mobile-web brand bar — Scan/History live in the bottom nav below the
          nav breakpoint; the sidebar takes over at nav+. */}
      <header className="flex h-14 items-center border-b border-border bg-canvas px-4 nav:hidden">
        <Link href="/" className="flex items-center gap-2">
          <BrandMark size={26} />
          <span className="text-base font-extrabold tracking-[-0.01em] text-ink">
            MenuMind
          </span>
        </Link>
      </header>

      <div className="nav:pl-[232px]">
        {topBar}
        <main className="mx-auto w-full max-w-[1340px] px-5 pb-24 pt-6 md:px-8 nav:pb-6">
          {children}
        </main>
      </div>

      <MobileBottomNav active={active} />
    </div>
  );
}
