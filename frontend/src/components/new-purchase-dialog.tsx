"use client";

import { Plus, X } from "lucide-react";
import { useEffect, useMemo, useState, type FormEvent, type ReactNode } from "react";
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
import { Textarea } from "@/components/ui/textarea";
import { createPurchase } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { CreatePurchaseLineItemPayload, ProductItem, Supplier } from "@/lib/types";

/** Mirrors apps.products.services.compute_purchase_line_shares()'s
 * ROUND_HALF_UP-at-2dp rounding exactly, so this preview matches what the
 * backend will actually persist. Same trick as RestockDialog's round2(). */
function round2(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

interface LineDraft {
  key: number;
  productId: number | null;
  quantity: string;
  unitPrice: string;
}

let nextLineKey = 1;
function emptyLine(): LineDraft {
  return { key: nextLineKey++, productId: null, quantity: "1", unitPrice: "" };
}

interface ComputedLine {
  line: LineDraft;
  product: ProductItem | null;
  quantity: number;
  unitPrice: number;
  subtotal: number;
  extraShare: number;
  landedUnitCost: number;
}

/** Proportional split of sharedExtraCosts across `lines` by each line's
 * subtotal share (quantity * unitPrice) - identical algorithm to
 * apps.products.services.compute_purchase_line_shares(): the last line
 * absorbs the rounding remainder so shares always sum exactly. */
function computeLineShares(lines: { quantity: number; unitPrice: number }[], sharedExtraCosts: number): number[] {
  if (lines.length === 0) return [];
  const subtotals = lines.map((l) => l.quantity * l.unitPrice);
  const totalSubtotal = subtotals.reduce((sum, s) => sum + s, 0);

  const shares: number[] = [];
  let remaining = round2(sharedExtraCosts);
  lines.forEach((_line, index) => {
    const isLast = index === lines.length - 1;
    let share: number;
    if (totalSubtotal <= 0) {
      share = isLast ? remaining : round2(sharedExtraCosts / lines.length);
    } else if (isLast) {
      share = remaining;
    } else {
      share = round2((sharedExtraCosts * subtotals[index]) / totalSubtotal);
    }
    remaining = round2(remaining - share);
    shares.push(share);
  });
  return shares;
}

export function NewPurchaseDialog({
  suppliers,
  products,
  trigger,
  onSaved,
}: {
  suppliers: Supplier[];
  products: ProductItem[];
  trigger: ReactNode;
  onSaved: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [supplierId, setSupplierId] = useState<number | null>(null);
  const [purchaseDate, setPurchaseDate] = useState("");
  const [sharedExtraCosts, setSharedExtraCosts] = useState("");
  const [note, setNote] = useState("");
  const [lines, setLines] = useState<LineDraft[]>([emptyLine()]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setSupplierId(null);
    setPurchaseDate(new Date().toISOString().slice(0, 10));
    setSharedExtraCosts("");
    setNote("");
    setLines([emptyLine()]);
    setError(null);
  }, [open]);

  const productOptions: ComboboxOption[] = products.map((product) => ({
    value: product.id,
    label: product.name,
    description: `${product.sku} · ${product.current_stock_quantity} in stock`,
  }));

  function updateLine(key: number, patch: Partial<LineDraft>) {
    setLines((prev) => prev.map((line) => (line.key === key ? { ...line, ...patch } : line)));
  }

  function addLine() {
    setLines((prev) => [...prev, emptyLine()]);
  }

  function removeLine(key: number) {
    setLines((prev) => (prev.length > 1 ? prev.filter((line) => line.key !== key) : prev));
  }

  const computedLines: ComputedLine[] = useMemo(() => {
    const parsed = lines.map((line) => ({
      quantity: Number(line.quantity) || 0,
      unitPrice: Number(line.unitPrice) || 0,
    }));
    const shares = computeLineShares(parsed, Number(sharedExtraCosts) || 0);

    return lines.map((line, index) => {
      const quantity = parsed[index].quantity;
      const unitPrice = parsed[index].unitPrice;
      const subtotal = quantity * unitPrice;
      const extraShare = shares[index] ?? 0;
      const landedUnitCost = quantity > 0 ? round2((subtotal + extraShare) / quantity) : 0;
      return {
        line,
        product: products.find((product) => product.id === line.productId) ?? null,
        quantity,
        unitPrice,
        subtotal,
        extraShare,
        landedUnitCost,
      };
    });
  }, [lines, products, sharedExtraCosts]);

  const isValid =
    !!supplierId &&
    purchaseDate !== "" &&
    lines.every((line) => line.productId !== null && Number(line.quantity) > 0 && line.unitPrice !== "" && Number(line.unitPrice) >= 0) &&
    new Set(lines.map((line) => line.productId)).size === lines.length;

  const hasDuplicateProducts = new Set(lines.map((line) => line.productId)).size !== lines.length;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid || !supplierId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const line_items: CreatePurchaseLineItemPayload[] = lines.map((line) => ({
        product: line.productId as number,
        quantity: Number(line.quantity),
        unit_price: Number(line.unitPrice),
      }));
      await createPurchase({
        supplier: supplierId,
        purchase_date: purchaseDate,
        shared_extra_costs: sharedExtraCosts ? Number(sharedExtraCosts) : undefined,
        note: note.trim() || undefined,
        line_items,
      });
      toast.success("Purchase recorded — stock and cost updated for every product.");
      setOpen(false);
      onSaved();
    } catch (err) {
      setError(reportError(err, "Failed to record the purchase."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>New Purchase</DialogTitle>
          <DialogDescription>
            Record one supplier trip covering several products at once. A shared delivery/packaging cost is split
            proportionally across the products by their value share, then every product is restocked exactly like a
            regular restock.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label>
                Supplier <span className="text-destructive">*</span>
              </Label>
              <Combobox
                options={suppliers.map((supplier) => ({ value: supplier.id, label: supplier.name }))}
                value={supplierId}
                onChange={setSupplierId}
                placeholder="Search suppliers..."
                searchPlaceholder="Search suppliers..."
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="purchase-date">
                Purchase Date <span className="text-destructive">*</span>
              </Label>
              <Input
                id="purchase-date"
                type="date"
                required
                value={purchaseDate}
                onChange={(event) => setPurchaseDate(event.target.value)}
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>
                Products <span className="text-destructive">*</span>
              </Label>
              <Button type="button" variant="outline" size="sm" onClick={addLine}>
                <Plus /> Add product line
              </Button>
            </div>
            <div className="space-y-2">
              {lines.map((line) => (
                <div key={line.key} className="grid grid-cols-[1fr_5rem_6rem_2rem] items-end gap-2">
                  <div className="space-y-1">
                    {line.key === lines[0].key && <Label className="text-xs">Product</Label>}
                    <Combobox
                      options={productOptions}
                      value={line.productId}
                      onChange={(value) => updateLine(line.key, { productId: value })}
                      placeholder="Search products..."
                      searchPlaceholder="Search products..."
                    />
                  </div>
                  <div className="space-y-1">
                    {line.key === lines[0].key && <Label className="text-xs">Qty</Label>}
                    <Input
                      type="number"
                      min={1}
                      value={line.quantity}
                      onChange={(event) => updateLine(line.key, { quantity: event.target.value })}
                    />
                  </div>
                  <div className="space-y-1">
                    {line.key === lines[0].key && <Label className="text-xs">Unit Price</Label>}
                    <Input
                      type="number"
                      min={0}
                      step="0.01"
                      value={line.unitPrice}
                      onChange={(event) => updateLine(line.key, { unitPrice: event.target.value })}
                    />
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon-sm"
                    disabled={lines.length === 1}
                    onClick={() => removeLine(line.key)}
                    aria-label="Remove product line"
                  >
                    <X />
                  </Button>
                </div>
              ))}
            </div>
            {hasDuplicateProducts && (
              <p className="text-xs text-destructive">
                The same product is selected on more than one line — pick each product only once (add its full
                quantity on a single line instead).
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="shared-extra-costs">Shared Extra Costs (delivery, packaging, etc.)</Label>
            <Input
              id="shared-extra-costs"
              type="number"
              min={0}
              step="0.01"
              placeholder="0.00"
              value={sharedExtraCosts}
              onChange={(event) => setSharedExtraCosts(event.target.value)}
            />
          </div>

          <div className="rounded-lg border bg-muted/30 p-3 text-sm">
            <p className="mb-2 text-xs font-semibold text-muted-foreground uppercase">Preview</p>
            <div className="space-y-2">
              {computedLines.map((computed) => (
                <div key={computed.line.key} className="grid grid-cols-4 gap-2 text-xs">
                  <div className="truncate font-medium text-foreground">{computed.product?.name ?? "—"}</div>
                  <div className="text-muted-foreground">Subtotal: ৳{computed.subtotal.toFixed(2)}</div>
                  <div className="text-muted-foreground">Delivery share: ৳{computed.extraShare.toFixed(2)}</div>
                  <div className="font-semibold text-primary">Landed cost: ৳{computed.landedUnitCost.toFixed(2)}</div>
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="purchase-note">Note</Label>
            <Textarea id="purchase-note" value={note} onChange={(event) => setNote(event.target.value)} />
          </div>

          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Recording..." : "Confirm & Record Purchase"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
