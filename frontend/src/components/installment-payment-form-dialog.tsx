"use client";

import { Paperclip, X } from "lucide-react";
import { useEffect, useState, type ChangeEvent, type FormEvent, type ReactNode } from "react";
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
import { addInstallmentPayment, updateInstallmentPayment } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Loan, LoanInstallmentPayment } from "@/lib/types";

// Attachments are meant to be a quick receipt photo/scan, not document
// storage. Mirrors MAX_ATTACHMENT_SIZE_BYTES in apps.loans.serializers on
// the backend - images get compressed under 50KB server-side after upload.
const MAX_ATTACHMENT_SIZE_BYTES = 300 * 1024;

function todayDateKey(): string {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function InstallmentPaymentFormDialog({
  loan,
  payment,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  loan: Loan;
  /** Pass an existing payment to edit it in place; omit to record a new one. */
  payment?: LoanInstallmentPayment;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: () => void;
}) {
  const isEdit = !!payment;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;

  const suggestedInstallment = Math.min(loan.installments_paid_count + 1, loan.total_installments);
  const [installmentNumber, setInstallmentNumber] = useState(
    String(payment?.installment_number ?? suggestedInstallment),
  );
  const [amountPaid, setAmountPaid] = useState<number | string>(payment?.amount_paid ?? loan.installment_amount);
  const [paymentDate, setPaymentDate] = useState(payment?.payment_date ?? todayDateKey());
  const [attachment, setAttachment] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // A payment being edited is already counted in loan.amount_remaining, so
  // its own current amount has to be added back before checking the new
  // amount against the budget - otherwise re-saving the same value would
  // look like an overpayment.
  const amountRemaining = Number(loan.amount_remaining) + (payment ? Number(payment.amount_paid) : 0);

  useEffect(() => {
    if (!open) return;
    setInstallmentNumber(String(payment?.installment_number ?? suggestedInstallment));
    setAmountPaid(payment?.amount_paid ?? loan.installment_amount);
    setPaymentDate(payment?.payment_date ?? todayDateKey());
    setAttachment(null);
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, loan, payment]);

  const attachmentTooLarge = attachment !== null && attachment.size > MAX_ATTACHMENT_SIZE_BYTES;

  function handleAttachmentChange(event: ChangeEvent<HTMLInputElement>) {
    setAttachment(event.target.files?.[0] ?? null);
  }

  const parsedInstallmentNumber = Number(installmentNumber);
  const parsedAmount = Number(amountPaid);
  const isValid =
    parsedInstallmentNumber >= 1 &&
    parsedInstallmentNumber <= loan.total_installments &&
    amountPaid !== "" &&
    parsedAmount > 0 &&
    parsedAmount <= amountRemaining &&
    paymentDate &&
    !attachmentTooLarge;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const saved: LoanInstallmentPayment = isEdit
        ? await updateInstallmentPayment(payment.id, {
            amount_paid: parsedAmount,
            payment_date: paymentDate,
            installment_number: parsedInstallmentNumber,
            attachment: attachment ?? undefined,
          })
        : await addInstallmentPayment({
            loan: loan.id,
            amount_paid: parsedAmount,
            payment_date: paymentDate,
            installment_number: parsedInstallmentNumber,
            attachment: attachment ?? undefined,
          });
      toast.success(
        isEdit ? `Installment #${saved.installment_number} updated.` : `Installment #${saved.installment_number} recorded.`,
      );
      setOpen(false);
      onSaved();
    } catch (err) {
      setError(
        reportError(err, isEdit ? "Failed to update the installment payment." : "Failed to record the installment payment."),
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Installment Payment" : "Record Installment Payment"}</DialogTitle>
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
            <p className="text-xs text-destructive">Cannot exceed the remaining balance of ৳{amountRemaining}.</p>
          )}
          <div className="space-y-2">
            <Label htmlFor="installment-attachment">Attachment (optional)</Label>
            {attachment ? (
              <div className="flex items-center justify-between rounded-md border px-3 py-2 text-sm">
                <span className="flex items-center gap-2 truncate">
                  <Paperclip className="h-4 w-4 shrink-0 text-muted-foreground" />
                  <span className="truncate">{attachment.name}</span>
                </span>
                <button
                  type="button"
                  onClick={() => setAttachment(null)}
                  className="shrink-0 text-muted-foreground hover:text-foreground"
                  aria-label="Remove attachment"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
            ) : (
              <Input
                id="installment-attachment"
                type="file"
                accept="image/*,application/pdf"
                onChange={handleAttachmentChange}
              />
            )}
            <p className="text-xs text-muted-foreground">
              {isEdit && payment?.attachment
                ? "Receipt photo or PDF, under 300KB. Leave empty to keep the current attachment."
                : "Receipt photo or PDF, under 300KB. Photos are compressed automatically after upload."}
            </p>
            {attachmentTooLarge && (
              <p className="text-xs text-destructive">
                {attachment!.name} is {Math.ceil(attachment!.size / 1024)}KB — must be under 300KB.
              </p>
            )}
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting} className="text-white">
              {isSubmitting ? "Saving..." : isEdit ? "Save Changes" : "Record Payment"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
