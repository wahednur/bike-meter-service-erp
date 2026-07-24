"use client";

import { useState, type FormEvent, type ReactNode } from "react";

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

/** Admin-only "unlock" gate for editing a Paid/force-closed invoice (rule
 * 14). This invoice is normally locked; entering a reason here doesn't
 * change anything by itself - it's forwarded to whichever edit/replace/
 * delete the Admin performs next (see the "Editing unlocked" banner and
 * onUnlocked in the invoice detail page), each of which is itself
 * Admin-only and reason-required on the server too. */
export function EditPaidInvoiceDialog({ trigger, onUnlocked }: { trigger: ReactNode; onUnlocked: (reason: string) => void }) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");

  const isValid = reason.trim().length > 0;

  function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    onUnlocked(reason.trim());
    setOpen(false);
    setReason("");
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit Paid Invoice</DialogTitle>
          <DialogDescription>
            This invoice is Paid and normally locked. Enter a reason to unlock editing for the rest of this
            session - every change you make will be logged with this reason and who made it.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="edit-paid-reason">
              Reason <span className="text-destructive">*</span>
            </Label>
            <Textarea
              id="edit-paid-reason"
              placeholder="Why does this Paid invoice need to change?"
              value={reason}
              onChange={(event) => setReason(event.target.value)}
            />
          </div>
          <DialogFooter>
            <Button type="submit" disabled={!isValid}>
              Unlock Editing
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
