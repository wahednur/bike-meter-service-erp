"use client";

import { Upload } from "lucide-react";
import { useEffect, useMemo, useRef, type ChangeEvent } from "react";

import { ImageThumbnail } from "@/components/image-thumbnail";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";

/** File input + live preview for the Meter/Service/Product add/edit
 * dialogs. Fully controlled: the parent owns `value` (the newly picked
 * file, if any) so it resets for free alongside the dialog's other form
 * state on open/close. `existingImageUrl` is the item's already-saved
 * image (editing) - shown until the user picks a replacement. */
export function ImageUploadField({
  label = "Image",
  existingImageUrl,
  value,
  onChange,
}: {
  label?: string;
  existingImageUrl?: string | null;
  value: File | null;
  onChange: (file: File | null) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);

  // Pure derivation (useMemo), not state - createObjectURL is cheap and
  // synchronous. The effect below only ever revokes; it never calls setState,
  // so cleaning up the previous URL can't trigger a cascading re-render.
  const objectUrl = useMemo(() => (value ? URL.createObjectURL(value) : null), [value]);

  useEffect(() => {
    return () => {
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [objectUrl]);

  const previewUrl = objectUrl ?? existingImageUrl ?? null;

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    onChange(event.target.files?.[0] ?? null);
  }

  return (
    <div className="space-y-2">
      <Label>{label}</Label>
      <div className="flex items-center gap-3">
        <ImageThumbnail src={previewUrl} alt="" size="md" />
        <div className="flex flex-col gap-1">
          <Button type="button" variant="outline" size="sm" onClick={() => inputRef.current?.click()}>
            <Upload /> {previewUrl ? "Change Image" : "Upload Image"}
          </Button>
          <input ref={inputRef} type="file" accept="image/*" className="hidden" onChange={handleFileChange} />
        </div>
      </div>
    </div>
  );
}
