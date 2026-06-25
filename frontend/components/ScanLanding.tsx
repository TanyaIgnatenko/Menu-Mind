"use client";

import { useEffect, useRef, useState } from "react";

import { Upload } from "lucide-react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { uploadMenu, UploadLimitError } from "@/lib/api";
import { capture } from "@/lib/posthog";
import type { Menu } from "@/lib/types";

import { LoadingOrbit } from "./LoadingOrbit";
import { WebcamCapture } from "./WebcamCapture";

interface Props {
  onUploaded: (menu: Menu) => void;
}

type UploadError =
  | { kind: "limit"; message: string; resetsAt: Date }
  | { kind: "generic"; message: string };

const STAGES = ["Reading menu…", "Translating dishes…", "Generating photos…"];

function formatLocalTime(date: Date): string {
  return date.toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
    timeZoneName: "short",
  });
}

export function ScanLanding({ onUploaded }: Props) {
  const [processing, setProcessing] = useState(false);
  const [stage, setStage] = useState(0);
  const [error, setError] = useState<UploadError | null>(null);
  const [dragActive, setDragActive] = useState(false);
  const [showWebcam, setShowWebcam] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Advance the loader caption while processing.
  useEffect(() => {
    if (!processing) return;
    const id = window.setInterval(
      () => setStage((s) => Math.min(s + 1, STAGES.length - 1)),
      2500,
    );
    return () => window.clearInterval(id);
  }, [processing]);

  async function handleFile(file: File) {
    setError(null);
    setStage(0);
    setProcessing(true);
    try {
      const menu = await uploadMenu(file);
      capture("menu_uploaded", {
        menu_id: menu.id,
        dish_count: menu.dishes.length,
        source_language: menu.source_language ?? "unknown",
        is_cache_hit: false,
      });
      onUploaded(menu);
    } catch (e) {
      if (e instanceof UploadLimitError) {
        capture("rate_limit_hit", { scope: "ip" });
        setError({ kind: "limit", message: e.message, resetsAt: e.resetsAt });
      } else {
        const reason =
          e instanceof Error && e.message.includes("extraction")
            ? "extraction_failed"
            : e instanceof Error && e.message.includes("image")
              ? "invalid_image"
              : "unknown";
        capture("menu_upload_failed", { reason });
        setError({
          kind: "generic",
          message: e instanceof Error ? e.message : "Upload failed",
        });
      }
      setProcessing(false);
    }
  }

  function onInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
    e.target.value = "";
  }

  function onDrop(e: React.DragEvent) {
    e.preventDefault();
    setDragActive(false);
    const file = e.dataTransfer.files?.[0];
    if (file && file.type.startsWith("image/")) handleFile(file);
  }

  if (processing) {
    return (
      <div className="mx-auto max-w-xl">
        <LoadingOrbit caption="Cooking up your menu" subcaption={STAGES[stage]} />
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-[620px]">
      <div className="flex flex-col items-center text-center">
        <span className="rounded-full bg-primary-tint px-3.5 py-1.5 text-xs font-bold text-primary">
          🌍 <span className="hidden nav:inline">Works in </span>40+ languages
        </span>

        {/* Desktop and mobile hero copy per the spec. */}
        <h1 className="mt-5 hidden font-display text-[44px] font-extrabold leading-[1.05] tracking-[-0.04em] text-ink nav:block">
          Translate any menu in seconds
        </h1>
        <h1 className="mt-5 font-display text-[30px] font-extrabold leading-[1.05] tracking-[-0.04em] text-ink nav:hidden">
          Read any menu.
        </h1>

        <p className="mt-3 hidden w-full max-w-md text-[15px] leading-relaxed text-body nav:block">
          Upload a photo of a restaurant menu and get every dish translated —
          with AI images, dietary filters, and nutrition.
        </p>
        <p className="mt-3 w-full max-w-md text-[15px] leading-relaxed text-body nav:hidden">
          Snap a menu and get every dish translated with AI photos.
        </p>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp,image/heic"
          onChange={onInputChange}
          className="hidden"
          aria-label="Upload menu photo"
        />

        {/* Drop-zone */}
        <button
          type="button"
          onClick={() => fileInputRef.current?.click()}
          onDragOver={(e) => {
            e.preventDefault();
            setDragActive(true);
          }}
          onDragLeave={() => setDragActive(false)}
          onDrop={onDrop}
          className={`mt-7 flex w-full flex-col items-center rounded-[22px] border-[2.5px] border-dashed px-6 py-9 transition-colors ${
            dragActive
              ? "border-primary bg-primary-tint"
              : "border-dropzone bg-surface hover:bg-canvas"
          }`}
        >
          <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary-tint nav:h-[72px] nav:w-[72px]">
            <span className="text-[26px] leading-none nav:hidden" aria-hidden="true">
              📷
            </span>
            <Upload className="hidden h-8 w-8 text-primary nav:block" aria-hidden="true" />
          </span>
          <span className="mt-4 font-display text-base font-bold text-ink nav:text-lg">
            <span className="hidden nav:inline">Drag a menu photo here</span>
            <span className="nav:hidden">Tap to take a photo</span>
          </span>
          <span className="mt-1 text-sm text-muted-2">
            <span className="hidden nav:inline">
              or click to browse — JPG, PNG, HEIC up to 20 MB
            </span>
            <span className="nav:hidden">or upload from your library</span>
          </span>
        </button>

        {/* Actions */}
        <div className="mt-5 hidden w-full items-center justify-center gap-3 nav:flex">
          <Button onClick={() => fileInputRef.current?.click()} size="lg" className="gap-2">
            <span aria-hidden="true" className="text-base">📁</span>
            Choose file
          </Button>
          <Button variant="outline" size="lg" className="gap-2" onClick={() => setShowWebcam(true)}>
            <span aria-hidden="true" className="text-base">📷</span>
            Use webcam
          </Button>
        </div>
        <Button
          onClick={() => fileInputRef.current?.click()}
          size="lg"
          className="mt-5 w-full gap-2 nav:hidden"
        >
          <span aria-hidden="true" className="text-base">📷</span>
          Take a Photo
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

      {showWebcam && (
        <WebcamCapture
          onClose={() => setShowWebcam(false)}
          onCapture={(file) => {
            setShowWebcam(false);
            handleFile(file);
          }}
        />
      )}
    </div>
  );
}
