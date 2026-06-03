"use client";

import { useState } from "react";

import { Check, Copy, Share2, X } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";

import { Button } from "@/components/ui/button";

interface Props {
  menuId: string;
}

export function ShareButton({ menuId }: Props) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  // Build the shareable URL from the current origin so it works on both
  // localhost and prod (Vercel) without any config.
  const shareUrl =
    typeof window !== "undefined"
      ? `${window.location.origin}/menu/${menuId}`
      : "";

  async function handleClick() {
    // Try native share first (mobile devices, some desktop browsers).
    // Falls back to opening the modal with QR + copy link.
    if (typeof navigator !== "undefined" && navigator.share) {
      try {
        await navigator.share({
          title: "MenuMind",
          text: "Check out this menu on MenuMind",
          url: shareUrl,
        });
        return;
      } catch (e) {
        // User cancelled or share failed — fall through to modal.
        // AbortError is normal (user cancelled), don't log noisily.
        if ((e as Error).name !== "AbortError") {
          console.warn("navigator.share failed:", e);
        }
        // If the user cancelled deliberately, don't open the modal —
        // they made a choice. Only open if share was unsupported/failed.
        if ((e as Error).name === "AbortError") return;
      }
    }
    setOpen(true);
  }

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (e) {
      console.warn("Clipboard write failed:", e);
    }
  }

  return (
    <>
      <Button variant="outline" onClick={handleClick}>
        <Share2 className="mr-2 h-4 w-4" />
        Share
      </Button>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          onClick={() => setOpen(false)}
        >
          <div
            className="relative w-full max-w-sm rounded-xl bg-card p-6 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setOpen(false)}
              aria-label="Close"
              className="absolute right-3 top-3 rounded p-1 text-muted-foreground hover:bg-accent hover:text-foreground"
            >
              <X className="h-4 w-4" />
            </button>

            <h2 className="mb-1 text-lg font-semibold">Share this menu</h2>
            <p className="mb-4 text-sm text-muted-foreground">
              Scan the QR code or copy the link.
            </p>

            <div className="mb-4 flex justify-center rounded-lg bg-white p-4">
              <QRCodeSVG value={shareUrl} size={200} />
            </div>

            <div className="flex gap-2">
              <input
                type="text"
                readOnly
                value={shareUrl}
                className="min-w-0 flex-1 rounded border bg-background px-3 py-2 text-sm"
                onClick={(e) => (e.target as HTMLInputElement).select()}
              />
              <Button onClick={handleCopy} variant="outline" size="sm">
                {copied ? (
                  <>
                    <Check className="mr-1 h-4 w-4" />
                    Copied
                  </>
                ) : (
                  <>
                    <Copy className="mr-1 h-4 w-4" />
                    Copy
                  </>
                )}
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}