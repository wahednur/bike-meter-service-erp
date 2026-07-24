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
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { ApiError, forceCloseInvoice } from "@/lib/api";
import { cleanInvoiceErrorMessage } from "@/lib/invoice-utils";
import type { InvoiceDetail } from "@/lib/types";

/** Admin-only "accept the remaining balance as final" write-off (rule 11).
 * Enforced both by hiding the trigger in the caller and by the server's
 * IsAdmin permission on POST /invoices/{id}/force-close/. Requires a
 * non-blank reason - the resulting waived_amount is recorded (and shown)
 * separately from a discount, never silently zeroed out. */
export function ForceCloseInvoiceDialog({
  invoice,
  trigger,
  onClosed,
}: {
  invoice: InvoiceDetail;
  trigger: ReactNode;
  onClosed: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [note, setNote] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setNote("");
    setError(null);
  }, [open]);

  const isValid = note.trim().length > 0;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await forceCloseInvoice(invoice.id, { note: note.trim() });
      toast.success(`Invoice marked Paid - ৳${invoice.due_amount} waived.`);
      setOpen(false);
      onClosed();
    } catch (err) {
      const message =
        err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to force-close this invoice.";
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
          <DialogTitle>Mark as Paid (Force Close)</DialogTitle>
          <DialogDescription>
            This invoice still has ৳{invoice.due_amount} due. Force-closing accepts that as a final shortfall,
            marks the invoice Paid, and records it as a waived amount - separate from a discount. This still counts
            toward the customer&apos;s red-list shortfall tracking, same as an unpaid balance would.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="force-close-note">
              Reason <span className="text-destructive">*</span>
            </Label>
            <Textarea
              id="force-close-note"
              placeholder="Why is the remaining balance being written off?"
              value={note}
              onChange={(event) => setNote(event.target.value)}
            />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" variant="destructive" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Closing..." : `Waive ৳${invoice.due_amount} & Mark Paid`}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
