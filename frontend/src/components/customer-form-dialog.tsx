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
import { ApiError, createCustomer, updateCustomer } from "@/lib/api";
import type { Customer, CustomerPayload } from "@/lib/types";

export function CustomerFormDialog({
  customer,
  trigger,
  onSaved,
}: {
  customer?: Customer;
  trigger: ReactNode;
  onSaved: (customer: Customer) => void;
}) {
  const isEdit = !!customer;
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(customer?.name ?? "");
  const [phone, setPhone] = useState(customer?.phone ?? "");
  const [address, setAddress] = useState(customer?.address ?? "");
  const [email, setEmail] = useState(customer?.email ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName(customer?.name ?? "");
    setPhone(customer?.phone ?? "");
    setAddress(customer?.address ?? "");
    setEmail(customer?.email ?? "");
    setError(null);
  }, [open, customer]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!name.trim() || !phone.trim()) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: CustomerPayload = {
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        email: email.trim() || null,
      };
      const saved = customer ? await updateCustomer(customer.id, payload) : await createCustomer(payload);
      toast.success(isEdit ? "Customer updated." : "Customer added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to save the customer.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit customer" : "Add customer"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this customer's details." : "Create a new customer record."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="customer-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input id="customer-name" required value={name} onChange={(event) => setName(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="customer-phone">
              Phone <span className="text-destructive">*</span>
            </Label>
            <Input id="customer-phone" required value={phone} onChange={(event) => setPhone(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="customer-address">Address</Label>
            <Input id="customer-address" value={address} onChange={(event) => setAddress(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="customer-email">Email</Label>
            <Input
              id="customer-email"
              type="email"
              value={email ?? ""}
              onChange={(event) => setEmail(event.target.value)}
            />
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
