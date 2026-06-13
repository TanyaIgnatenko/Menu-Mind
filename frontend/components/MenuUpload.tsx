"use client";

import { useRef, useState } from "react";

import { Camera } from "lucide-react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { uploadMenu, UploadLimitError } from "@/lib/api";
import type { Menu } from "@/lib/types";

import { LoadingState } from "./LoadingState";

interface Props {
  onUploaded: (menu: Menu) => void;
}

/** Format a UTC Date as a friendly local time string, e.g. "3:00 AM" or "10:00". */
function formatLocalTime(date: Date): string {
  return date.toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  });
}

type UploadError =
  | { kind: "limit"; message: string; resetsAt: Date }
  | { kind: "generic"; message: string };

export function MenuUpload({ onUploaded }: Props) {
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<UploadError | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function handleFile(file: File) {
    setError(null);
    setIsUploading(true);

    try {
      const menu = await uploadMenu(file);
      onUploaded(menu);
    } catch (e) {
      if (e instanceof UploadLimitError) {
        setError({ kind: "limit", message: e.message, resetsAt: e.resetsAt });
      } else {
        setError({
          kind: "generic",
          message: e instanceof Error ? e.message : "Upload failed",
        });
      }
    } finally {
      setIsUploading(false);
    }
  }

  function onChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
    // Reset input so the same file can be re-selected after an error.
    e.target.value = "";
  }

  if (isUploading) {
    return <LoadingState />;
  }

  return (
    <div className="rounded-lg border-2 border-dashed border-coral/40 bg-card p-8 shadow-card transition-colors hover:border-coral/70">
      <div className="flex flex-col items-center text-center">
        <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-gold/60">
          <Camera className="h-7 w-7 text-navy" aria-hidden="true" />
        </div>

        <p className="mb-6 max-w-xs text-muted-foreground">
          Upload a photo of any menu to translate and understand it.
        </p>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={onChange}
          className="hidden"
          aria-label="Upload menu photo"
        />

        <Button
          onClick={() => fileInputRef.current?.click()}
          disabled={isUploading || error?.kind === "limit"}
          size="lg"
        >
          Choose photo
        </Button>

        {error && (
          <Alert variant="destructive" className="mt-6 text-left">
            <AlertDescription>
              {error.kind === "limit" ? (
                <>
                  <span className="font-semibold">Daily limit reached.</span>{" "}
                  {error.message} Resets at{" "}
                  <span className="font-semibold">
                    {formatLocalTime(error.resetsAt)}
                  </span>
                  .
                </>
              ) : (
                error.message
              )}
            </AlertDescription>
          </Alert>
        )}
      </div>
    </div>
  );
}
