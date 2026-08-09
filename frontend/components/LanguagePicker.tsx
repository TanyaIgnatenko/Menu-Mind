"use client";

import { useEffect, useMemo, useRef, useState } from "react";

import { Check, Search } from "lucide-react";

import { SUPPORTED_LANGUAGES } from "@/lib/languages";
import { cn } from "@/lib/utils";

/**
 * Modal language picker with search, mirroring the mobile bottom-sheet. Resolves
 * by calling `onSelect(code)`; closes on ✕ / backdrop / Esc.
 */
export function LanguagePicker({
  selectedCode,
  onSelect,
  onClose,
}: {
  selectedCode: string;
  onSelect: (code: string) => void;
  onClose: () => void;
}) {
  const [query, setQuery] = useState("");
  const panelRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [onClose]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return SUPPORTED_LANGUAGES;
    return SUPPORTED_LANGUAGES.filter(
      (l) =>
        l.name.toLowerCase().includes(q) ||
        l.endonym.toLowerCase().includes(q) ||
        l.code.toLowerCase().includes(q),
    );
  }, [query]);

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal="true"
      aria-label="Translate menus to"
    >
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div
        ref={panelRef}
        className="relative z-10 flex max-h-[80dvh] w-full max-w-md flex-col overflow-hidden rounded-t-3xl bg-canvas shadow-[0_30px_80px_rgba(0,0,0,0.3)] sm:rounded-3xl"
      >
        <div className="px-6 pb-3 pt-5">
          <h2 className="font-display text-lg font-extrabold text-ink">
            Translate menus to
          </h2>
        </div>
        <div className="px-4 pb-2">
          <div className="flex items-center gap-2 rounded-xl border border-border bg-surface px-3">
            <Search className="h-4 w-4 text-muted" aria-hidden="true" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search languages…"
              aria-label="Search languages"
              autoFocus
              className="h-11 flex-1 bg-transparent text-sm text-ink outline-none placeholder:text-muted"
            />
          </div>
        </div>
        <ul className="flex-1 overflow-y-auto px-3 pb-4">
          {filtered.length === 0 ? (
            <li className="px-3 py-8 text-center text-sm text-body">
              No languages match.
            </li>
          ) : (
            filtered.map((lang) => {
              const selected = lang.code === selectedCode;
              return (
                <li key={lang.code}>
                  <button
                    type="button"
                    onClick={() => onSelect(lang.code)}
                    aria-current={selected ? "true" : undefined}
                    className={cn(
                      "flex w-full items-center gap-3.5 rounded-xl px-3 py-2.5 text-left transition-colors",
                      selected ? "bg-primary-tint" : "hover:bg-canvas-alt",
                    )}
                  >
                    <span className="text-[22px]" aria-hidden="true">
                      {lang.flag}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span
                        className={cn(
                          "block text-sm font-bold",
                          selected ? "text-primary" : "text-ink",
                        )}
                      >
                        {lang.name}
                      </span>
                      {lang.endonym !== lang.name && (
                        <span className="block text-[11px] text-muted">
                          {lang.endonym}
                        </span>
                      )}
                    </span>
                    {selected && (
                      <Check className="h-5 w-5 shrink-0 text-primary" aria-hidden="true" />
                    )}
                  </button>
                </li>
              );
            })
          )}
        </ul>
      </div>
    </div>
  );
}
