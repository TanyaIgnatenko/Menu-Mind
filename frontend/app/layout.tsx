import type { Metadata, Viewport } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import { Suspense } from "react";

import { PostHogProvider } from "@/components/PostHogProvider";

import "./globals.css";

const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin", "latin-ext"],
  style: ["normal", "italic"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-jakarta",
});

export const metadata: Metadata = {
  title: "MenuMind",
  description: "Read any menu. Anywhere.",
  applicationName: "MenuMind",
  appleWebApp: {
    capable: true,
    title: "MenuMind",
    statusBarStyle: "default",
  },
  icons: {
    icon: "/icons/icon-192.png",
    apple: "/icons/icon-192.png",
  },
};

export const viewport: Viewport = {
  themeColor: "#F05A28",
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${jakarta.variable} font-sans`}>
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
