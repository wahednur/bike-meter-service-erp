"use client";

import { useEffect, useState, type FormEvent, type ReactNode } from "react";
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
import { createProduct, updateProduct } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ProductItem, ProductPayload, Supplier } from "@/lib/types";

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
    setSupplierId(product?.supplier ?? suppliers[0]?.id ?? null);
    setSalePrice(product?.sale_price ?? "");
    setDescription(product?.description ?? "");
    setImageFile(null);
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, product]);

  const isValid = name.trim() && sku.trim() && supplierId && salePrice;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid || !supplierId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: ProductPayload = {
        name: name.trim(),
        sku: sku.trim(),
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
              <Label htmlFor="product-sku">
                SKU <span className="text-destructive">*</span>
              </Label>
              <Input id="product-sku" required value={sku} onChange={(event) => setSku(event.target.value)} />
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
