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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { addPayment, ApiError } from "@/lib/api";
import { cleanInvoiceErrorMessage } from "@/lib/invoice-utils";
import type { InvoiceDetail, PaymentMethod } from "@/lib/types";

const PAYMENT_METHODS: { value: PaymentMethod; label: string }[] = [
  { value: "CASH", label: "Cash" },
  { value: "BKASH", label: "bKash" },
  { value: "NAGAD", label: "Nagad" },
  { value: "BANK_TRANSFER", label: "Bank Transfer" },
  { value: "CARD", label: "Card" },
  { value: "OTHER", label: "Other" },
];

export function AddPaymentDialog({
  invoice,
  trigger,
  onPaid,
}: {
  invoice: InvoiceDetail;
  trigger: ReactNode;
  onPaid: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [amount, setAmount] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("CASH");
  const [note, setNote] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const outstanding = Number(invoice.due_amount);

  useEffect(() => {
    if (!open) return;
    setAmount("");
    setPaymentMethod("CASH");
    setNote("");
    setError(null);
  }, [open]);

  const parsedAmount = Number(amount);
  const isValid = amount !== "" && parsedAmount > 0 && parsedAmount <= outstanding;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await addPayment(invoice.id, {
        amount: parsedAmount,
        payment_method: paymentMethod,
        note: note.trim(),
      });
      toast.success("Payment recorded — see the updated per-meter split below.");
      setOpen(false);
      onPaid();
    } catch (err) {
      const message = err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to record the payment.";
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
          <DialogTitle>Add Payment</DialogTitle>
          <DialogDescription>
            Due amount: ৳{invoice.due_amount}. If this payment is less than the total due across meters on this
            invoice, it will be split evenly across them.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="payment-amount">
                Amount <span className="text-destructive">*</span>
              </Label>
              <Input
                id="payment-amount"
                type="number"
                min={0.01}
                max={outstanding}
                step="0.01"
                required
                value={amount}
                onChange={(event) => setAmount(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Method</Label>
              <Select value={paymentMethod} onValueChange={(value) => setPaymentMethod(value as PaymentMethod)}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PAYMENT_METHODS.map((method) => (
                    <SelectItem key={method.value} value={method.value}>
                      {method.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          {amount !== "" && parsedAmount > outstanding && (
            <p className="text-xs text-destructive">Cannot exceed the due amount of ৳{invoice.due_amount}.</p>
          )}
          <div className="space-y-2">
            <Label htmlFor="payment-note">Note</Label>
            <Textarea id="payment-note" value={note} onChange={(event) => setNote(event.target.value)} />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Recording..." : "Record Payment"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
