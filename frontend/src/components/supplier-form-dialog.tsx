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
import { createSupplier, updateSupplier } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Supplier, SupplierPayload } from "@/lib/types";

export function SupplierFormDialog({
  supplier,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  supplier?: Supplier;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (supplier: Supplier) => void;
}) {
  const isEdit = !!supplier;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [name, setName] = useState(supplier?.name ?? "");
  const [phone, setPhone] = useState(supplier?.phone ?? "");
  const [address, setAddress] = useState(supplier?.address ?? "");
  const [note, setNote] = useState(supplier?.note ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName(supplier?.name ?? "");
    setPhone(supplier?.phone ?? "");
    setAddress(supplier?.address ?? "");
    setNote(supplier?.note ?? "");
    setError(null);
  }, [open, supplier]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!name.trim() || !phone.trim()) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: SupplierPayload = {
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        note: note.trim(),
      };
      const saved = supplier ? await updateSupplier(supplier.id, payload) : await createSupplier(payload);
      toast.success(isEdit ? "Supplier updated." : "Supplier added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the supplier."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit supplier" : "Add supplier"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this supplier's details." : "Create a new supplier record."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="supplier-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input id="supplier-name" required value={name} onChange={(event) => setName(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="supplier-phone">
              Phone <span className="text-destructive">*</span>
            </Label>
            <Input id="supplier-phone" required value={phone} onChange={(event) => setPhone(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="supplier-address">Address</Label>
            <Input id="supplier-address" value={address} onChange={(event) => setAddress(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="supplier-note">Note</Label>
            <Textarea id="supplier-note" value={note} onChange={(event) => setNote(event.target.value)} />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!name.trim() || !phone.trim() || isSubmitting}>
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
