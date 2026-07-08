"use client";

import { useEffect } from "react";

import { usePathname, useSearchParams } from "next/navigation";
import posthog from "posthog-js";
import { PostHogProvider as PHProvider } from "posthog-js/react";

const POSTHOG_KEY = process.env.NEXT_PUBLIC_POSTHOG_KEY ?? "";
const POSTHOG_HOST = process.env.NEXT_PUBLIC_POSTHOG_HOST ?? "https://eu.i.posthog.com";

/** Initialise PostHog once and track client-side route changes. */
function PostHogInit() {
  const pathname = usePathname();
  const searchParams = useSearchParams();

  useEffect(() => {
    if (!POSTHOG_KEY) return;

    posthog.init(POSTHOG_KEY, {
      api_host: POSTHOG_HOST,
      // Don't fire a pageview on init — we handle it manually below so we
      // capture Next.js client-side navigations too.
      capture_pageview: false,
      // Respect DNT and EU privacy defaults.
      respect_dnt: true,
      // Session replay is off. This stops the web client from recording even if
      // the project toggle is on; also disable it in PostHog project settings
      // (Settings → Session Replay) to stop it at the source for every client.
      disable_session_recording: true,
      // Heatmaps and autocapture remain controlled by the PostHog project settings.
    });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Track pageviews on every client-side route change.
  useEffect(() => {
    if (!POSTHOG_KEY) return;
    posthog.capture("$pageview", {
      $current_url: window.location.href,
    });
  }, [pathname, searchParams]);

  return null;
}

interface Props {
  children: React.ReactNode;
}

/**
 * Wrap the app in the PostHog React context.
 * Must be a Client Component because posthog-js uses browser APIs.
 */
export function PostHogProvider({ children }: Props) {
  if (!POSTHOG_KEY) {
    // No key configured (e.g. local dev without .env.local) — render children
    // without analytics rather than crashing.
    return <>{children}</>;
  }

  return (
    <PHProvider client={posthog}>
      <PostHogInit />
      {children}
    </PHProvider>
  );
}
