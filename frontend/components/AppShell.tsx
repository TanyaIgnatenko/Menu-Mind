import type { ReactNode } from "react";

import Link from "next/link";

import { History } from "lucide-react";

import { AppSidebar } from "./AppSidebar";
import { BrandMark } from "./BrandMark";

type NavKey = "scan" | "history";

/**
 * App layout: a persistent left sidebar on desktop (≥ nav breakpoint) and a
 * compact brand top bar on mobile web. Pages pass their active nav key and an
 * optional `topBar` (e.g. the restaurant header on the Menu screen).
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

      {/* Mobile-web brand bar — replaces the sidebar below the nav breakpoint. */}
      <header className="flex h-14 items-center justify-between border-b border-border bg-canvas px-4 nav:hidden">
        <Link href="/" className="flex items-center gap-2">
          <BrandMark size={26} />
          <span className="text-base font-extrabold tracking-[-0.01em] text-ink">
            MenuMind
          </span>
        </Link>
        <Link
          href="/history"
          aria-label="History"
          aria-current={active === "history" ? "page" : undefined}
          className="flex h-11 w-11 items-center justify-center rounded-xl text-body hover:bg-canvas-alt"
        >
          <History className="h-5 w-5" aria-hidden="true" />
        </Link>
      </header>

      <div className="nav:pl-[232px]">
        {topBar}
        <main className="mx-auto w-full max-w-[1340px] px-5 py-6 md:px-8">
          {children}
        </main>
      </div>
    </div>
  );
}
