"use client";

import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { toast } from "sonner";

import { Combobox, type ComboboxOption } from "@/components/combobox";
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
import { addProductLine, ApiError, updateProductLine } from "@/lib/api";
import { cleanInvoiceErrorMessage } from "@/lib/invoice-utils";
import type { InvoiceProductLine, ProductItem } from "@/lib/types";

function ErrorBanner({ message }: { message: string | null }) {
  if (!message) return null;
  return <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{message}</p>;
}

/** Add-or-edit dialog for one InvoiceProductLine - same reuse pattern as
 * ServiceLineDialog. Editing can't change which product a line is for
 * (only quantity/price); the product field renders disabled, pre-filled. */
export function ProductLineDialog({
  invoiceId,
  products,
  productLine,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  invoiceId: number;
  products: ProductItem[];
  productLine?: InvoiceProductLine;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: () => void;
}) {
  const isEdit = !!productLine;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;

  const [productId, setProductId] = useState<number | null>(null);
  const [quantity, setQuantity] = useState("1");
  const [price, setPrice] = useState("");
  const [priceEdited, setPriceEdited] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const selectedProduct = products.find((product) => product.id === productId) ?? null;
  const defaultPrice = selectedProduct?.sale_price;

  useEffect(() => {
    if (!open) return;
    if (productLine) {
      setProductId(productLine.product);
      setQuantity(String(productLine.quantity));
      setPrice(productLine.price_charged);
      setPriceEdited(true);
    } else {
      setProductId(null);
      setQuantity("1");
      setPrice("");
      setPriceEdited(false);
    }
    setError(null);
  }, [open, productLine]);

  useEffect(() => {
    if (isEdit || priceEdited) return;
    setPrice(defaultPrice ?? "");
  }, [isEdit, priceEdited, defaultPrice]);

  const productOptions: ComboboxOption[] = products.map((product) => ({
    value: product.id,
    label: product.name,
    description: `${product.sku} · ${product.current_stock_quantity} in stock`,
  }));

  const parsedQuantity = Number(quantity);
  const isValid = !!productId && quantity !== "" && parsedQuantity >= 1 && price !== "";

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid || !productId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const priceNumber = price === "" ? null : Number(price);
      if (isEdit && productLine) {
        await updateProductLine(invoiceId, productLine.id, {
          quantity: parsedQuantity,
          price_charged: priceNumber,
        });
        toast.success("Product updated.");
      } else {
        await addProductLine(invoiceId, {
          product: productId,
          quantity: parsedQuantity,
          price_charged: priceNumber,
        });
        toast.success("Product added.");
      }
      setOpen(false);
      onSaved();
    } catch (err) {
      const message =
        err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to save the product.";
      toast.error(message);
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit product" : "Add a product"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this line's quantity or price." : "Search for a product to add to this invoice."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Product <span className="text-destructive">*</span>
            </Label>
            <Combobox
              options={productOptions}
              value={productId}
              onChange={(value) => {
                setProductId(value);
                setPriceEdited(false);
              }}
              disabled={isEdit}
              placeholder="Search products..."
              searchPlaceholder="Search products..."
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="product-line-quantity">
                Quantity <span className="text-destructive">*</span>
              </Label>
              <Input
                id="product-line-quantity"
                type="number"
                min={1}
                value={quantity}
                onChange={(event) => setQuantity(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="product-line-price">
                Price <span className="text-destructive">*</span>
              </Label>
              <Input
                id="product-line-price"
                type="number"
                min={0}
                step="0.01"
                value={price}
                onChange={(event) => {
                  setPrice(event.target.value);
                  setPriceEdited(true);
                }}
              />
            </div>
          </div>
          <p className="text-xs text-muted-foreground">
            Price defaults to the product&apos;s own sale price - edit to charge something else.
          </p>
          <ErrorBanner message={error} />
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Saving..." : isEdit ? "Save changes" : "Add product"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
