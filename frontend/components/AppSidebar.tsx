import Link from "next/link";

import { Camera, History, Settings } from "lucide-react";

import { cn } from "@/lib/utils";

import { BrandMark } from "./BrandMark";

type NavKey = "scan" | "history" | "settings";

interface NavDef {
  key: NavKey;
  label: string;
  href: string;
  icon: typeof Camera;
}

const NAV: NavDef[] = [
  { key: "scan", label: "Scan menu", href: "/", icon: Camera },
  { key: "history", label: "History", href: "/history", icon: History },
  { key: "settings", label: "Settings", href: "/settings", icon: Settings },
];

/**
 * Desktop left sidebar (232px): brand lockup, Scan / History nav, and a
 * "40+ languages" promo card pinned to the bottom. Hidden on mobile web.
 */
export function AppSidebar({
  active,
  className,
}: {
  active: NavKey;
  className?: string;
}) {
  return (
    <aside
      className={cn(
        "fixed left-0 top-0 z-20 flex h-screen w-[232px] flex-col border-r border-border bg-canvas px-4 py-5",
        className,
      )}
    >
      <Link href="/" className="mb-7 flex items-center gap-2.5 px-2">
        <BrandMark size={32} />
        <span className="text-[19px] font-extrabold tracking-[-0.01em] text-ink">
          MenuMind
        </span>
      </Link>

      <nav className="flex flex-col gap-1">
        {NAV.map(({ key, label, href, icon: Icon }) => {
          const isActive = key === active;
          return (
            <Link
              key={key}
              href={href}
              aria-current={isActive ? "page" : undefined}
              className={cn(
                "flex h-11 items-center gap-3 rounded-xl px-3 text-sm font-semibold transition-colors",
                isActive
                  ? "bg-primary-tint text-ink"
                  : "text-body hover:bg-canvas-alt",
              )}
            >
              <Icon
                className={cn(
                  "h-[18px] w-[18px]",
                  isActive ? "text-primary" : "text-muted",
                )}
                aria-hidden="true"
              />
              {label}
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto rounded-2xl border border-border bg-canvas-alt p-4">
        <p className="text-sm font-bold text-ink">🌍 40+ languages</p>
        <p className="mt-1 text-xs leading-relaxed text-body">
          Translate menus from any cuisine, instantly.
        </p>
      </div>
    </aside>
  );
}
