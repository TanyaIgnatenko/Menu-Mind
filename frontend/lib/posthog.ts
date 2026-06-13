/**
 * PostHog analytics — typed event catalogue for MenuMind.
 *
 * All events go through `capture()` so there is one place to add
 * common properties (e.g. app_version) in the future.
 *
 * Usage:
 *   import { capture } from "@/lib/posthog";
 *   capture("menu_uploaded", { dish_count: 19, source_language: "de" });
 */

import posthog from "posthog-js";

// ── Event types ───────────────────────────────────────────────────────────────

export type EventName =
  | "menu_uploaded"
  | "menu_upload_failed"
  | "menu_opened_from_history"
  | "menu_shared"
  | "filter_applied"
  | "filter_cleared"
  | "rate_limit_hit"
  | "time_to_first_image";

export type EventProperties = {
  menu_uploaded: {
    menu_id: string;
    dish_count: number;
    source_language: string;
    is_cache_hit: boolean;
  };
  menu_upload_failed: {
    reason: "rate_limit" | "invalid_image" | "extraction_failed" | "network" | "unknown";
  };
  menu_opened_from_history: {
    menu_id: string;
  };
  menu_shared: {
    menu_id: string;
  };
  filter_applied: {
    filter_id: string;
    filter_label: string;
    filter_group: "needs" | "prefs";
    active_count: number;
  };
  filter_cleared: {
    previous_count: number;
  };
  rate_limit_hit: {
    scope: "ip" | "global";
  };
  time_to_first_image: {
    menu_id: string;
    seconds: number;
    dish_count: number;
  };
};

// ── Typed capture ─────────────────────────────────────────────────────────────

export function capture<E extends EventName>(
  event: E,
  properties: EventProperties[E],
): void {
  // posthog-js is a no-op when not initialised (e.g. SSR), so this is safe.
  posthog.capture(event, properties);
}
