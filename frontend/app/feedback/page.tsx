"use client";

import { useEffect, useMemo, useRef, useState } from "react";

import Link from "next/link";
import { useRouter } from "next/navigation";

import { ArrowLeft, Check, ImagePlus, Send, X } from "lucide-react";

import { AppShell } from "@/components/AppShell";
import { submitFeedback } from "@/lib/api";
import { getDistinctId } from "@/lib/posthog";
import { getReplyToEmail, setReplyToEmail } from "@/lib/settings";

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const MAX_FILES = 3;
const MAX_BYTES = 5 * 1024 * 1024; // 5 MB per image

export default function FeedbackPage() {
  const router = useRouter();
  const [message, setMessage] = useState("");
  const [email, setEmail] = useState("");
  const [files, setFiles] = useState<File[]>([]);
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // localStorage is client-only — read the saved reply-to after mount.
  useEffect(() => {
    setEmail(getReplyToEmail());
  }, []);

  // Object URLs for thumbnails; revoke the previous set whenever files change.
  const previews = useMemo(() => files.map((f) => URL.createObjectURL(f)), [files]);
  useEffect(() => {
    return () => previews.forEach((url) => URL.revokeObjectURL(url));
  }, [previews]);

  const canSend =
    !sending && message.trim().length > 0 && EMAIL_RE.test(email.trim());

  function addFiles(list: FileList | null) {
    if (!list) return;
    setError(null);
    const next = [...files];
    for (const f of Array.from(list)) {
      if (next.length >= MAX_FILES) break;
      if (!f.type.startsWith("image/")) continue;
      if (f.size > MAX_BYTES) {
        setError("Images must be under 5 MB.");
        continue;
      }
      next.push(f);
    }
    setFiles(next.slice(0, MAX_FILES));
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function removeFile(idx: number) {
    setFiles(files.filter((_, i) => i !== idx));
  }

  async function send() {
    if (!canSend) return;
    setSending(true);
    setError(null);
    const replyTo = email.trim();
    try {
      setReplyToEmail(replyTo); // pre-fill next time
      await submitFeedback({
        message: message.trim(),
        replyTo,
        attachments: files,
        deviceId: getDistinctId(),
      });
      setSent(true);
      setTimeout(() => router.push("/settings"), 1200);
    } catch (e) {
      setSending(false);
      setError(e instanceof Error ? e.message : "Could not send. Please try again.");
    }
  }

  return (
    <AppShell active="settings">
      <div className="mx-auto max-w-2xl">
        <Link
          href="/settings"
          className="mb-4 inline-flex h-9 items-center gap-1.5 text-sm font-semibold text-body hover:text-ink"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
          Settings
        </Link>

        <h1 className="font-display text-[26px] font-extrabold tracking-[-0.025em] text-ink">
          Send feedback
        </h1>
        <p className="mt-1 text-sm text-body">
          Found a bug or have an idea? Tell us — we read every note.
        </p>

        {sent ? (
          <div className="mt-6 flex items-center gap-3 rounded-2xl border border-success/30 bg-success-bg p-5">
            <Check className="h-5 w-5 text-success" aria-hidden="true" />
            <p className="text-sm font-semibold text-ink">
              Thanks! Your feedback was sent.
            </p>
          </div>
        ) : (
          <div className="mt-6 space-y-6">
            {/* Message */}
            <div>
              <label
                htmlFor="feedback-message"
                className="mb-2 block text-[11px] font-bold uppercase tracking-widest text-muted-2"
              >
                Message
              </label>
              <textarea
                id="feedback-message"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                rows={6}
                maxLength={5000}
                placeholder="What's on your mind? The more detail, the better we can help..."
                className="w-full resize-y rounded-2xl border border-border bg-surface p-4 text-sm text-ink outline-none placeholder:text-muted focus:border-primary"
              />
            </div>

            {/* Attachments */}
            <div>
              <span className="mb-2 block text-[11px] font-bold uppercase tracking-widest text-muted-2">
                Attachments
              </span>
              <div className="flex flex-wrap gap-3">
                {files.map((file, idx) => (
                  <div key={idx} className="relative h-[72px] w-[72px]">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={previews[idx]}
                      alt={file.name}
                      className="h-full w-full rounded-xl object-cover"
                    />
                    <button
                      type="button"
                      onClick={() => removeFile(idx)}
                      aria-label="Remove attachment"
                      className="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full border-2 border-canvas bg-ink text-white"
                    >
                      <X className="h-3 w-3" aria-hidden="true" />
                    </button>
                  </div>
                ))}
                {files.length < MAX_FILES && (
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="flex h-[72px] w-[72px] flex-col items-center justify-center gap-1 rounded-xl border-2 border-dashed border-muted/60 text-muted transition-colors hover:border-primary hover:text-primary"
                  >
                    <ImagePlus className="h-5 w-5" aria-hidden="true" />
                    <span className="text-[9px] font-semibold">Add photo</span>
                  </button>
                )}
              </div>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                multiple
                onChange={(e) => addFiles(e.target.files)}
                className="hidden"
              />
            </div>

            {/* Reply to */}
            <div>
              <label
                htmlFor="feedback-email"
                className="mb-2 block text-[11px] font-bold uppercase tracking-widest text-muted-2"
              >
                Reply to
              </label>
              <input
                id="feedback-email"
                type="email"
                inputMode="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                className="w-full rounded-xl border border-border bg-surface px-4 py-3 text-sm text-ink outline-none placeholder:text-muted focus:border-primary"
              />
            </div>

            {error && <p className="text-sm font-medium text-allergen">{error}</p>}

            <button
              type="button"
              onClick={send}
              disabled={!canSend}
              className="flex h-[54px] w-full items-center justify-center gap-2 rounded-2xl bg-primary text-sm font-bold text-white transition-opacity disabled:opacity-40"
            >
              <Send className="h-[18px] w-[18px]" aria-hidden="true" />
              {sending ? "Sending…" : "Send feedback"}
            </button>
          </div>
        )}
      </div>
    </AppShell>
  );
}
