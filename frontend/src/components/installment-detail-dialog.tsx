"use client";

import { FileText, Paperclip } from "lucide-react";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { LoanInstallmentPayment } from "@/lib/types";

const IMAGE_EXTENSIONS = [".png", ".jpg", ".jpeg", ".gif", ".webp"];

function isImageAttachment(url: string): boolean {
  const lower = url.toLowerCase();
  return IMAGE_EXTENSIONS.some((extension) => lower.endsWith(extension));
}

export function InstallmentDetailDialog({
  payment,
  onOpenChange,
}: {
  payment: LoanInstallmentPayment | null;
  onOpenChange: (open: boolean) => void;
}) {
  return (
    <Dialog open={payment !== null} onOpenChange={onOpenChange}>
      <DialogContent>
        {payment && (
          <>
            <DialogHeader>
              <DialogTitle>Installment #{payment.installment_number}</DialogTitle>
              <DialogDescription>Payment details for this installment.</DialogDescription>
            </DialogHeader>
            <dl className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <dt className="text-xs text-muted-foreground">Payment Date</dt>
                <dd>{payment.payment_date}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Amount Paid</dt>
                <dd className="font-medium">৳{payment.amount_paid}</dd>
              </div>
              <div className="col-span-2">
                <dt className="text-xs text-muted-foreground">Recorded</dt>
                <dd>{new Date(payment.created_at).toLocaleString()}</dd>
              </div>
            </dl>
            <div className="space-y-2">
              <p className="text-xs text-muted-foreground">Attachment</p>
              {payment.attachment ? (
                isImageAttachment(payment.attachment) ? (
                  <a href={payment.attachment} target="_blank" rel="noopener noreferrer">
                    {/* Plain <img>, not next/image: served from the Django
                       backend's own origin, not worth allow-listing for a
                       one-off receipt preview. */}
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={payment.attachment}
                      alt={`Installment #${payment.installment_number} receipt`}
                      className="max-h-64 w-full rounded-md border object-contain"
                    />
                  </a>
                ) : (
                  <a
                    href={payment.attachment}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm text-primary hover:underline"
                  >
                    <FileText className="h-4 w-4" /> View receipt (PDF)
                  </a>
                )
              ) : (
                <p className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Paperclip className="h-4 w-4" /> No attachment
                </p>
              )}
            </div>
            <DialogFooter showCloseButton />
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
