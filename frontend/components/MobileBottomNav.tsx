import Link from "next/link";

import { Camera, History, Settings } from "lucide-react";

import { cn } from "@/lib/utils";

type NavKey = "scan" | "history" | "settings";

const ITEMS: { key: NavKey; label: string; href: string; icon: typeof Camera }[] = [
  { key: "scan", label: "Scan", href: "/", icon: Camera },
  { key: "history", label: "History", href: "/history", icon: History },
  { key: "settings", label: "Settings", href: "/settings", icon: Settings },
];

/**
 * Mobile-web bottom tab bar (Scan / History), mirroring the native app. Hidden
 * on desktop (the sidebar takes over). Active tab shows a filled primary tile.
 */
export function MobileBottomNav({ active }: { active: NavKey }) {
  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-30 border-t border-border bg-canvas pb-[env(safe-area-inset-bottom)] nav:hidden"
      aria-label="Primary"
    >
      <div className="mx-auto flex max-w-md">
        {ITEMS.map(({ key, label, href, icon: Icon }) => {
          const isActive = key === active;
          return (
            <Link
              key={key}
              href={href}
              aria-current={isActive ? "page" : undefined}
              className="flex flex-1 flex-col items-center gap-1 py-2"
            >
              <span
                className={cn(
                  "flex h-9 w-9 items-center justify-center rounded-xl transition-colors",
                  isActive ? "bg-primary text-white" : "text-muted",
                )}
              >
                <Icon className="h-[18px] w-[18px]" aria-hidden="true" />
              </span>
              <span
                className={cn(
                  "text-[11px] font-semibold",
                  isActive ? "text-primary" : "text-muted-2",
                )}
              >
                {label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
