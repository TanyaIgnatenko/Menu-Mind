"use client";

import { useEffect, useRef, useState } from "react";

import { Camera, X } from "lucide-react";

import { Button } from "@/components/ui/button";

interface Props {
  onCapture: (file: File) => void;
  onClose: () => void;
}

/**
 * Full-screen webcam capture. Streams the rear/most-available camera via
 * getUserMedia, grabs a still frame to a JPEG File on "Capture", and hands it
 * back. Closes on ✕ / Esc / backdrop.
 */
export function WebcamCapture({ onCapture, onClose }: Props) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function start() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "environment" },
          audio: false,
        });
        if (cancelled) {
          stream.getTracks().forEach((t) => t.stop());
          return;
        }
        streamRef.current = stream;
        if (videoRef.current) videoRef.current.srcObject = stream;
      } catch {
        if (!cancelled) setError("Couldn't access the camera. Check permissions.");
      }
    }
    start();

    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);

    return () => {
      cancelled = true;
      document.removeEventListener("keydown", onKey);
      streamRef.current?.getTracks().forEach((t) => t.stop());
    };
  }, [onClose]);

  function capture() {
    const video = videoRef.current;
    if (!video) return;
    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.drawImage(video, 0, 0);
    canvas.toBlob(
      (blob) => {
        if (!blob) return;
        onCapture(new File([blob], "webcam.jpg", { type: "image/jpeg" }));
      },
      "image/jpeg",
      0.9,
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-black/80 p-4"
      role="dialog"
      aria-modal="true"
      aria-label="Take a photo with your camera"
      onClick={onClose}
    >
      <div
        className="relative w-full max-w-2xl overflow-hidden rounded-2xl bg-black"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Close camera"
          className="absolute right-3 top-3 z-10 flex h-11 w-11 items-center justify-center rounded-full bg-black/50 text-white hover:bg-black/70"
        >
          <X className="h-5 w-5" aria-hidden="true" />
        </button>

        {error ? (
          <div className="flex aspect-video items-center justify-center p-8 text-center text-sm text-white">
            {error}
          </div>
        ) : (
          <video
            ref={videoRef}
            autoPlay
            playsInline
            muted
            className="aspect-video w-full object-cover"
          />
        )}
      </div>

      {!error && (
        <Button
          onClick={(e) => {
            e.stopPropagation();
            capture();
          }}
          size="lg"
          className="mt-5 gap-2"
        >
          <Camera className="h-5 w-5" aria-hidden="true" />
          Capture
        </Button>
      )}
    </div>
  );
}
