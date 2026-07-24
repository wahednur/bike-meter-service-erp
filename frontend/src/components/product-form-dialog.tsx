"use client";

import { Pencil, Sparkles } from "lucide-react";
import { useEffect, useRef, useState, type FormEvent, type ReactNode } from "react";
import { toast } from "sonner";

import { ImageUploadField } from "@/components/image-upload-field";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { createProduct, previewProductSku, updateProduct } from "@/lib/api";
import { reportError } from "@/lib/errors";
import { cn } from "@/lib/utils";
import type { ProductItem, ProductPayload, Supplier } from "@/lib/types";

// How long to wait after the user stops typing name/supplier before asking
// the backend for a fresh SKU preview - short enough to feel live, long
// enough not to hammer the endpoint on every keystroke.
const SKU_PREVIEW_DEBOUNCE_MS = 400;

export function ProductFormDialog({
  product,
  suppliers,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  product?: ProductItem;
  suppliers: Supplier[];
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (product: ProductItem) => void;
}) {
  const isEdit = !!product;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [name, setName] = useState(product?.name ?? "");
  const [sku, setSku] = useState(product?.sku ?? "");
  const [manualSku, setManualSku] = useState(false);
  const [skuPreviewLoading, setSkuPreviewLoading] = useState(false);
  const [supplierId, setSupplierId] = useState<number | null>(product?.supplier ?? suppliers[0]?.id ?? null);
  const [salePrice, setSalePrice] = useState(product?.sale_price ?? "");
  const [description, setDescription] = useState(product?.description ?? "");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName(product?.name ?? "");
    setSku(product?.sku ?? "");
    setManualSku(false);
    setSupplierId(product?.supplier ?? suppliers[0]?.id ?? null);
    setSalePrice(product?.sale_price ?? "");
    setDescription(product?.description ?? "");
    setImageFile(null);
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, product]);

  // Live SKU preview while adding a new product (not editing an existing
  // one - its SKU was already assigned) and not manually overridden -
  // see apps.products.services.generate_sku(). Debounced, and guarded
  // against out-of-order responses so a slow earlier request can't
  // clobber a faster later one.
  const previewRequestId = useRef(0);
  useEffect(() => {
    if (!open || isEdit || manualSku) return;
    const trimmedName = name.trim();
    const requestId = ++previewRequestId.current;

    // Everything below runs inside the timeout callback (never synchronously
    // in the effect body) so an incomplete name/supplier just clears the
    // preview on the same debounced cadence instead of flashing immediately.
    const timeoutId = setTimeout(() => {
      if (!trimmedName || !supplierId) {
        setSku("");
        setSkuPreviewLoading(false);
        return;
      }
      setSkuPreviewLoading(true);
      previewProductSku(supplierId, trimmedName)
        .then((result) => {
          if (previewRequestId.current === requestId) setSku(result.sku);
        })
        .catch(() => {
          // Best-effort preview only - leave whatever SKU is currently shown.
        })
        .finally(() => {
          if (previewRequestId.current === requestId) setSkuPreviewLoading(false);
        });
    }, SKU_PREVIEW_DEBOUNCE_MS);

    return () => clearTimeout(timeoutId);
  }, [open, isEdit, manualSku, name, supplierId]);

  const isValid = name.trim() && supplierId && salePrice;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid || !supplierId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: ProductPayload = {
        name: name.trim(),
        // In auto mode, don't send the previewed value at all - it can go
        // stale (e.g. another product created in between), so let
        // generate_sku() run fresh, authoritatively, at save time.
        sku: manualSku ? sku.trim() || undefined : undefined,
        supplier: supplierId,
        sale_price: Number(salePrice),
        description: description.trim(),
        image: imageFile ?? undefined,
      };
      const saved = product ? await updateProduct(product.id, payload) : await createProduct(payload);
      toast.success(isEdit ? "Product updated." : "Product added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the product."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit product" : "Add product"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Update this product's details."
              : "Create a new product. Use \"Add Stock\" afterward to bring in inventory."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="product-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input id="product-name" required value={name} onChange={(event) => setName(event.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="product-sku">SKU {manualSku && <span className="text-destructive">*</span>}</Label>
                <button
                  type="button"
                  onClick={() => setManualSku((prev) => !prev)}
                  className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
                  title={manualSku ? "Switch back to auto-generated SKU" : "Edit SKU manually"}
                >
                  {manualSku ? (
                    <>
                      <Sparkles className="h-3 w-3" /> Auto-generate
                    </>
                  ) : (
                    <>
                      <Pencil className="h-3 w-3" /> Edit manually
                    </>
                  )}
                </button>
              </div>
              <Input
                id="product-sku"
                readOnly={!manualSku}
                placeholder={isEdit || manualSku ? "" : "Enter name & supplier to preview"}
                value={sku}
                onChange={(event) => setSku(event.target.value)}
                className={cn(!manualSku && "bg-muted text-muted-foreground")}
              />
              {!manualSku && (
                <p className="text-xs text-muted-foreground">
                  {isEdit
                    ? "Click \"Edit manually\" to change this product's SKU."
                    : skuPreviewLoading
                      ? "Previewing…"
                      : "Auto-generated from supplier + product name."}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="product-sale-price">
                Sale Price <span className="text-destructive">*</span>
              </Label>
              <Input
                id="product-sale-price"
                type="number"
                min={0}
                step="0.01"
                required
                value={salePrice}
                onChange={(event) => setSalePrice(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label>
              Supplier <span className="text-destructive">*</span>
            </Label>
            <Select
              value={supplierId ? String(supplierId) : undefined}
              onValueChange={(value) => setSupplierId(Number(value))}
              disabled={suppliers.length === 0}
            >
              <SelectTrigger className="w-full">
                <SelectValue placeholder={suppliers.length ? "Select a supplier" : "No suppliers yet"} />
              </SelectTrigger>
              <SelectContent>
                {suppliers.map((supplier) => (
                  <SelectItem key={supplier.id} value={String(supplier.id)}>
                    {supplier.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="product-description">Description</Label>
            <Textarea
              id="product-description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>
          <ImageUploadField existingImageUrl={product?.image} value={imageFile} onChange={setImageFile} />
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
