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
import { createExpense, updateExpense } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Expense, ExpenseCategory, ExpensePayload } from "@/lib/types";

const CATEGORY_OPTIONS: { value: ExpenseCategory; label: string }[] = [
  { value: "RENT", label: "Rent" },
  { value: "ELECTRICITY", label: "Electricity" },
  { value: "TRANSPORT", label: "Transport" },
  { value: "MISC", label: "Misc" },
];

export function ExpenseFormDialog({
  expense,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  expense?: Expense;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (expense: Expense) => void;
}) {
  const isEdit = !!expense;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [category, setCategory] = useState<ExpenseCategory>(expense?.category ?? "MISC");
  const [amount, setAmount] = useState(expense?.amount ?? "");
  const [date, setDate] = useState(expense?.date ?? "");
  const [note, setNote] = useState(expense?.note ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setCategory(expense?.category ?? "MISC");
    setAmount(expense?.amount ?? "");
    setDate(expense?.date ?? "");
    setNote(expense?.note ?? "");
    setError(null);
  }, [open, expense]);

  const isValid = amount && Number(amount) > 0 && date;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: ExpensePayload = {
        category,
        amount: Number(amount),
        date,
        note: note.trim() || undefined,
      };
      const saved = expense ? await updateExpense(expense.id, payload) : await createExpense(payload);
      toast.success(isEdit ? "Expense updated." : "Expense added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the expense."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit expense" : "Add expense"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this expense's details." : "Record a new shop expense."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label>Category</Label>
              <Select value={category} onValueChange={(value) => setCategory(value as ExpenseCategory)}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORY_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="expense-amount">
                Amount <span className="text-destructive">*</span>
              </Label>
              <Input
                id="expense-amount"
                type="number"
                min={0}
                step="0.01"
                required
                value={amount}
                onChange={(event) => setAmount(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="expense-date">
              Date <span className="text-destructive">*</span>
            </Label>
            <Input id="expense-date" type="date" required value={date} onChange={(event) => setDate(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="expense-note">Note</Label>
            <Textarea id="expense-note" value={note} onChange={(event) => setNote(event.target.value)} />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
