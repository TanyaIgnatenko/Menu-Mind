"use client";

import { useState } from "react";

import { Check, Copy, Share2, X } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";

import { Button } from "@/components/ui/button";
import { capture } from "@/lib/posthog";

interface Props {
  menuId: string;
}

export function ShareButton({ menuId }: Props) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);

  const shareUrl =
    typeof window !== "undefined"
      ? `${window.location.origin}/menu/${menuId}`
      : "";

  function handleOpen() {
    setOpen(true);
    capture("menu_shared", { menu_id: menuId });
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
      <Button variant="outline" onClick={handleOpen}>
        <Share2 className="mr-2 h-4 w-4" />
        Share
      </Button>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-navy/60 p-4 backdrop-blur-sm"
          onClick={() => setOpen(false)}
        >
          <div
            className="relative w-full max-w-sm rounded-lg bg-card p-6 shadow-card-hover"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setOpen(false)}
              aria-label="Close"
              className="absolute right-3 top-3 rounded-full p-1.5 text-muted-foreground hover:bg-gold/50 hover:text-navy"
            >
              <X className="h-4 w-4" />
            </button>

            <h2 className="mb-1 font-display text-xl font-semibold text-navy">
              Share this menu
            </h2>
            <p className="mb-4 text-sm text-muted-foreground">
              Scan the QR code or copy the link.
            </p>

            <div className="mb-4 flex justify-center rounded-lg border-2 border-gold bg-white p-4">
              <QRCodeSVG value={shareUrl} size={200} fgColor="#1A1008" />
            </div>

            <div className="flex gap-2">
              <input
                type="text"
                readOnly
                value={shareUrl}
                className="min-w-0 flex-1 rounded-full border border-input bg-background px-4 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
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
