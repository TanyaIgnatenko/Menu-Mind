"use client";

import { useEffect, useState } from "react";

import Link from "next/link";

import { ChevronRight, MessageSquare } from "lucide-react";

import { AppShell } from "@/components/AppShell";
import { LanguagePicker } from "@/components/LanguagePicker";
import { DEFAULT_LANGUAGE, languageByCode } from "@/lib/languages";
import { getLanguageCode, setLanguageCode } from "@/lib/settings";

const APP_VERSION = "1.1";

export default function SettingsPage() {
  const [langCode, setLangCode] = useState(DEFAULT_LANGUAGE);
  const [pickerOpen, setPickerOpen] = useState(false);

  // localStorage is client-only — read after mount to avoid hydration mismatch.
  useEffect(() => {
    setLangCode(getLanguageCode());
  }, []);

  function choose(code: string) {
    setLanguageCode(code);
    setLangCode(code);
    setPickerOpen(false);
  }

  const lang = languageByCode(langCode);

  return (
    <AppShell active="settings">
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-6 font-display text-[28px] font-extrabold tracking-[-0.035em] text-ink">
          Settings
        </h1>

        {/* Translate menus to */}
        <h2 className="mb-2 pl-1 text-[11px] font-bold uppercase tracking-widest text-muted-2">
          Translate menus to
        </h2>
        <button
          type="button"
          onClick={() => setPickerOpen(true)}
          className="flex w-full items-center gap-3.5 rounded-2xl border border-border bg-surface p-4 text-left shadow-card transition-colors hover:border-primary/40"
        >
          <span className="text-2xl" aria-hidden="true">
            {lang.flag}
          </span>
          <span className="min-w-0 flex-1">
            <span className="block text-sm font-bold text-ink">{lang.name}</span>
            <span className="block text-[11px] text-muted">
              Dish names, descriptions &amp; details
            </span>
          </span>
          <ChevronRight className="h-5 w-5 shrink-0 text-muted" aria-hidden="true" />
        </button>

        {/* Support */}
        <h2 className="mb-2 mt-8 pl-1 text-[11px] font-bold uppercase tracking-widest text-muted-2">
          Support
        </h2>
        <Link
          href="/feedback"
          className="flex w-full items-center gap-3.5 rounded-2xl border border-border bg-surface p-4 text-left shadow-card transition-colors hover:border-primary/40"
        >
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary-tint">
            <MessageSquare className="h-[18px] w-[18px] text-primary" aria-hidden="true" />
          </span>
          <span className="flex-1 text-sm font-bold text-ink">Send feedback</span>
          <ChevronRight className="h-5 w-5 shrink-0 text-muted" aria-hidden="true" />
        </Link>

        <p className="mt-10 text-center text-xs text-muted">MenuMind v{APP_VERSION}</p>
      </div>

      {pickerOpen && (
        <LanguagePicker
          selectedCode={langCode}
          onSelect={choose}
          onClose={() => setPickerOpen(false)}
        />
      )}
    </AppShell>
  );
}
