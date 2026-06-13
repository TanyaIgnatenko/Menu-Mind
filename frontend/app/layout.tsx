import type { Metadata, Viewport } from "next";
import { Fraunces, Outfit } from "next/font/google";
import { Suspense } from "react";

import { PostHogProvider } from "@/components/PostHogProvider";

import "./globals.css";

const fraunces = Fraunces({
  subsets: ["latin", "latin-ext"],
  style: ["normal", "italic"],
  variable: "--font-fraunces",
});

const outfit = Outfit({
  subsets: ["latin", "latin-ext"],
  variable: "--font-outfit",
});

export const metadata: Metadata = {
  title: "MenuMind",
  description: "Eat with confidence, anywhere in the world.",
};

export const viewport: Viewport = {
  themeColor: "#8E2A4C",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${fraunces.variable} ${outfit.variable} font-sans`}>
        {/*
          Suspense is required around PostHogProvider because it uses
          useSearchParams() internally, which opts the subtree into
          client-side rendering. Without Suspense, Next.js throws a
          build error when pre-rendering static pages.
        */}
        <Suspense>
          <PostHogProvider>{children}</PostHogProvider>
        </Suspense>
      </body>
    </html>
  );
}
