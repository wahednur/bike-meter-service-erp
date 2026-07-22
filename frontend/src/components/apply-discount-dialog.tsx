"use client";

import { useEffect, useState, type FormEvent, type ReactNode } from "react";
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
import { Textarea } from "@/components/ui/textarea";
import { ApiError, applyDiscount } from "@/lib/api";
import { cleanInvoiceErrorMessage } from "@/lib/invoice-utils";
import type { InvoiceDetail } from "@/lib/types";

/** Admin-only (enforced both by hiding the trigger in the caller and by the
 * server's IsAdmin permission on POST /invoices/{id}/discount/). A fixed BDT
 * amount, never a percentage - see apps.invoices.services.apply_discount(). */
export function ApplyDiscountDialog({
  invoice,
  trigger,
  onApplied,
}: {
  invoice: InvoiceDetail;
  trigger: ReactNode;
  onApplied: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [discountAmount, setDiscountAmount] = useState(invoice.discount_amount);
  const [discountNote, setDiscountNote] = useState(invoice.discount_note);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEdit = Number(invoice.discount_amount) > 0;

  // Gross work total (services + products), reconstructed from what the
  // server already sends: total_amount = gross - discount_amount.
  const grossTotal = Number(invoice.total_amount) + Number(invoice.discount_amount);
  // Tightest bound the server will actually accept: a discount can't drop
  // the total below what's already been paid.
  const maxDiscount = Math.max(0, grossTotal - Number(invoice.paid_amount));

  useEffect(() => {
    if (!open) return;
    setDiscountAmount(invoice.discount_amount);
    setDiscountNote(invoice.discount_note);
    setError(null);
  }, [open, invoice]);

  const parsedAmount = Number(discountAmount);
  const isValid = discountAmount !== "" && parsedAmount >= 0 && parsedAmount <= maxDiscount;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await applyDiscount(invoice.id, {
        discount_amount: parsedAmount,
        discount_note: discountNote.trim(),
      });
      toast.success(isEdit ? "Discount updated." : "Discount applied.");
      setOpen(false);
      onApplied();
    } catch (err) {
      const message = err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to apply the discount.";
      toast.error(message);
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit discount" : "Apply discount"}</DialogTitle>
          <DialogDescription>
            Total work value: ৳{grossTotal.toFixed(2)}. The discount is a fixed BDT amount, not a percentage, and
            can&apos;t drop the total below the ৳{invoice.paid_amount} already paid.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="discount-amount">
              Discount Amount <span className="text-destructive">*</span>
            </Label>
            <Input
              id="discount-amount"
              type="number"
              min={0}
              max={maxDiscount}
              step="0.01"
              required
              value={discountAmount}
              onChange={(event) => setDiscountAmount(event.target.value)}
            />
            {discountAmount !== "" && parsedAmount > maxDiscount && (
              <p className="text-xs text-destructive">Cannot exceed ৳{maxDiscount.toFixed(2)}.</p>
            )}
          </div>
          <div className="space-y-2">
            <Label htmlFor="discount-note">Note</Label>
            <Textarea
              id="discount-note"
              placeholder="Why was this discount given?"
              value={discountNote}
              onChange={(event) => setDiscountNote(event.target.value)}
            />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Saving..." : isEdit ? "Update Discount" : "Apply Discount"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
