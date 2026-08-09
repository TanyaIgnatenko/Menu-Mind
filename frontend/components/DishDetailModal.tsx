"use client";

import { useEffect, useRef } from "react";

import type { Dish } from "@/lib/types";

import { DishDetailContent } from "./DishDetailContent";

/**
 * Desktop dish-detail modal: centered 820×520 panel over a dimmed/blurred
 * backdrop. Closes on ✕ / backdrop / Esc, traps focus, and restores focus and
 * body scroll on unmount.
 */
export function DishDetailModal({
  dish,
  onClose,
  enrichmentPending = false,
}: {
  dish: Dish;
  onClose: () => void;
  enrichmentPending?: boolean;
}) {
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const prevActive = document.activeElement as HTMLElement | null;
    const panel = panelRef.current;
    panel?.focus();
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") {
        onClose();
        return;
      }
      if (e.key === "Tab" && panel) {
        const focusable = panel.querySelectorAll<HTMLElement>(
          'a[href],button:not([disabled]),input,textarea,select,[tabindex]:not([tabindex="-1"])',
        );
        if (focusable.length === 0) return;
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    }

    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
      prevActive?.focus();
    };
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      role="dialog"
      aria-modal="true"
      aria-label={dish.name_english || dish.name_original}
    >
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />
      <div
        ref={panelRef}
        tabIndex={-1}
        className="relative z-10 flex h-[520px] max-h-[92dvh] w-full max-w-[820px] overflow-hidden rounded-[20px] bg-surface shadow-[0_30px_80px_rgba(0,0,0,0.3)] outline-none"
      >
        <DishDetailContent
          dish={dish}
          variant="modal"
          onClose={onClose}
          enrichmentPending={enrichmentPending}
        />
      </div>
    </div>
  );
}
