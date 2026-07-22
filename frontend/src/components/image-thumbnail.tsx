import { ImageOff } from "lucide-react";

const SIZE_CLASSES = {
  sm: "h-10 w-10 rounded-md",
  md: "h-16 w-16 rounded-lg",
  lg: "h-32 w-32 rounded-lg",
} as const;

const ICON_SIZE_CLASSES = {
  sm: "h-4 w-4",
  md: "h-6 w-6",
  lg: "h-10 w-10",
} as const;

/** A square image-or-placeholder box, used everywhere an item's photo
 * shows up: list-table rows, detail pages, and the live preview in the
 * upload dialogs. Renders a muted ImageOff icon when `src` is empty so
 * "no image yet" never looks like a broken image. */
export function ImageThumbnail({
  src,
  alt,
  size = "md",
}: {
  src?: string | null;
  alt: string;
  size?: "sm" | "md" | "lg";
}) {
  return (
    <div
      className={`flex shrink-0 items-center justify-center overflow-hidden border bg-muted ${SIZE_CLASSES[size]}`}
    >
      {src ? (
        // Plain <img>, not next/image: uploaded images are served from the
        // Django backend's own origin (a different port/domain in dev),
        // and next/image would need that origin allow-listed for no benefit
        // here since these aren't optimized/responsive hero images.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt={alt} className="h-full w-full object-cover" />
      ) : (
        <ImageOff className={`${ICON_SIZE_CLASSES[size]} text-muted-foreground`} />
      )}
    </div>
  );
}
