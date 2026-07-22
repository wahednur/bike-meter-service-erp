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
import { addInstallmentPayment } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Loan, LoanInstallmentPayment } from "@/lib/types";

function todayDateKey(): string {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function AddInstallmentPaymentDialog({
  loan,
  trigger,
  onPaid,
}: {
  loan: Loan;
  trigger: ReactNode;
  onPaid: () => void;
}) {
  const [open, setOpen] = useState(false);
  const suggestedInstallment = Math.min(loan.installments_paid_count + 1, loan.total_installments);
  const [installmentNumber, setInstallmentNumber] = useState(String(suggestedInstallment));
  const [amountPaid, setAmountPaid] = useState(loan.installment_amount);
  const [paymentDate, setPaymentDate] = useState(todayDateKey());
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const amountRemaining = Number(loan.amount_remaining);

  useEffect(() => {
    if (!open) return;
    setInstallmentNumber(String(suggestedInstallment));
    setAmountPaid(loan.installment_amount);
    setPaymentDate(todayDateKey());
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, loan]);

  const parsedInstallmentNumber = Number(installmentNumber);
  const parsedAmount = Number(amountPaid);
  const isValid =
    parsedInstallmentNumber >= 1 &&
    parsedInstallmentNumber <= loan.total_installments &&
    amountPaid !== "" &&
    parsedAmount > 0 &&
    parsedAmount <= amountRemaining &&
    paymentDate;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const saved: LoanInstallmentPayment = await addInstallmentPayment({
        loan: loan.id,
        amount_paid: parsedAmount,
        payment_date: paymentDate,
        installment_number: parsedInstallmentNumber,
      });
      toast.success(`Installment #${saved.installment_number} recorded.`);
      setOpen(false);
      onPaid();
    } catch (err) {
      setError(reportError(err, "Failed to record the installment payment."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Record Installment Payment</DialogTitle>
          <DialogDescription>
            {loan.lender_name} — {loan.installments_remaining} installment(s) remaining, ৳{loan.amount_remaining} left
            to pay.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="installment-number">
                Installment # <span className="text-destructive">*</span>
              </Label>
              <Input
                id="installment-number"
                type="number"
                min={1}
                max={loan.total_installments}
                required
                value={installmentNumber}
                onChange={(event) => setInstallmentNumber(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="installment-amount-paid">
                Amount Paid <span className="text-destructive">*</span>
              </Label>
              <Input
                id="installment-amount-paid"
                type="number"
                min={0.01}
                max={amountRemaining}
                step="0.01"
                required
                value={amountPaid}
                onChange={(event) => setAmountPaid(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="installment-payment-date">
              Payment Date <span className="text-destructive">*</span>
            </Label>
            <Input
              id="installment-payment-date"
              type="date"
              required
              value={paymentDate}
              onChange={(event) => setPaymentDate(event.target.value)}
            />
          </div>
          {amountPaid !== "" && parsedAmount > amountRemaining && (
            <p className="text-xs text-destructive">Cannot exceed the remaining balance of ৳{loan.amount_remaining}.</p>
          )}
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting} className="text-white">
              {isSubmitting ? "Recording..." : "Record Payment"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
