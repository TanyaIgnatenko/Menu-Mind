"use client";

import { useRef, useState } from "react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { uploadMenu } from "@/lib/api";
import type { Menu } from "@/lib/types";

import { LoadingState } from "./LoadingState";

interface Props {
  onUploaded: (menu: Menu) => void;
}

export function MenuUpload({ onUploaded }: Props) {
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function handleFile(file: File) {
    setError(null);
    setIsUploading(true);

    try {
      const menu = await uploadMenu(file);
      onUploaded(menu);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setIsUploading(false);
    }
  }

  function onChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
  }

  if (isUploading) {
    return <LoadingState />;
  }

  return (
    <Card className="border-2 border-dashed p-8">
      <div className="text-center">
        <p className="mb-6 text-muted-foreground">
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
          disabled={isUploading}
          size="lg"
        >
          Choose photo
        </Button>

        {error && (
          <Alert variant="destructive" className="mt-6 text-left">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}
      </div>
    </Card>
  );
}
