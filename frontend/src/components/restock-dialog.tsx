"use client";

import { useEffect, useMemo, useState, type FormEvent, type ReactNode } from "react";
import { toast } from "sonner";

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
import { restockProduct } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ProductItem } from "@/lib/types";

/** Mirrors apps.products.services.restock_product()'s weighted-average
 * formula exactly (landed unit cost rounded first, then folded into the
 * weighted average, both ROUND_HALF_UP to 2dp) so the preview here matches
 * what the backend will actually persist. */
function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function RestockDialog({
  product,
  trigger,
  onSaved,
}: {
  product: ProductItem;
  trigger: ReactNode;
  onSaved: (product: ProductItem) => void;
}) {
  const [open, setOpen] = useState(false);
  const [quantity, setQuantity] = useState("");
  const [unitPrice, setUnitPrice] = useState("");
  const [extraCosts, setExtraCosts] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setQuantity("");
    setUnitPrice("");
    setExtraCosts("");
    setError(null);
  }, [open]);

  const parsedQuantity = Number(quantity);
  const parsedUnitPrice = Number(unitPrice);
  const parsedExtraCosts = extraCosts ? Number(extraCosts) : 0;
  const isValid = quantity !== "" && parsedQuantity > 0 && unitPrice !== "" && parsedUnitPrice >= 0;

  const preview = useMemo(() => {
    if (!isValid) return null;
    const currentQty = product.current_stock_quantity;
    const currentAvgCost = Number(product.buy_price);
    const landedUnitCost = round2((parsedQuantity * parsedUnitPrice + parsedExtraCosts) / parsedQuantity);
    const combinedQty = currentQty + parsedQuantity;
    const newAvgCost = round2((currentQty * currentAvgCost + parsedQuantity * landedUnitCost) / combinedQty);
    return { landedUnitCost, newAvgCost, newStockQty: combinedQty };
  }, [isValid, parsedQuantity, parsedUnitPrice, parsedExtraCosts, product]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const saved = await restockProduct(product.id, {
        quantity: parsedQuantity,
        unit_price: parsedUnitPrice,
        extra_costs: parsedExtraCosts || undefined,
      });
      toast.success("Stock added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to add stock."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add Stock — {product.name}</DialogTitle>
          <DialogDescription>
            Restocking recalculates the product&apos;s average cost as a weighted average across existing and
            incoming stock.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="restock-quantity">
                Quantity <span className="text-destructive">*</span>
              </Label>
              <Input
                id="restock-quantity"
                type="number"
                min={1}
                required
                value={quantity}
                onChange={(event) => setQuantity(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="restock-unit-price">
                Unit Price <span className="text-destructive">*</span>
              </Label>
              <Input
                id="restock-unit-price"
                type="number"
                min={0}
                step="0.01"
                required
                value={unitPrice}
                onChange={(event) => setUnitPrice(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="restock-extra-costs">Extra Costs (shipping, etc.)</Label>
            <Input
              id="restock-extra-costs"
              type="number"
              min={0}
              step="0.01"
              placeholder="0.00"
              value={extraCosts}
              onChange={(event) => setExtraCosts(event.target.value)}
            />
          </div>

          <div className="rounded-lg border bg-muted/30 p-3 text-sm">
            <p className="mb-2 text-xs font-semibold text-muted-foreground uppercase">Preview</p>
            {!preview ? (
              <p className="text-muted-foreground">Enter a quantity and unit price to see the new average cost.</p>
            ) : (
              <dl className="grid grid-cols-3 gap-3">
                <div>
                  <dt className="text-xs text-muted-foreground">New Stock Qty</dt>
                  <dd className="font-medium">{preview.newStockQty}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Current Avg Cost</dt>
                  <dd className="font-medium">৳{Number(product.buy_price).toFixed(2)}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">New Avg Cost</dt>
                  <dd className="font-semibold text-primary">৳{preview.newAvgCost.toFixed(2)}</dd>
                </div>
              </dl>
            )}
          </div>

          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Adding..." : "Confirm & Add Stock"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
