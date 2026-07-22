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
import { createLoan, updateLoan } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { InstallmentFrequency, LenderType, Loan, LoanPayload } from "@/lib/types";

export function LoanFormDialog({
  loan,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  loan?: Loan;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (loan: Loan) => void;
}) {
  const isEdit = !!loan;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [lenderName, setLenderName] = useState(loan?.lender_name ?? "");
  const [lenderType, setLenderType] = useState<LenderType>(loan?.lender_type ?? "BANK");
  const [loanAmount, setLoanAmount] = useState(loan?.loan_amount ?? "");
  const [depositAmount, setDepositAmount] = useState(loan?.deposit_amount ?? "");
  const [interestAmount, setInterestAmount] = useState(loan?.interest_amount ?? "");
  const [totalInstallments, setTotalInstallments] = useState(loan ? String(loan.total_installments) : "");
  const [installmentAmount, setInstallmentAmount] = useState(loan?.installment_amount ?? "");
  const [installmentFrequency, setInstallmentFrequency] = useState<InstallmentFrequency>(
    loan?.installment_frequency ?? "MONTHLY",
  );
  const [startDate, setStartDate] = useState(loan?.start_date ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setLenderName(loan?.lender_name ?? "");
    setLenderType(loan?.lender_type ?? "BANK");
    setLoanAmount(loan?.loan_amount ?? "");
    setDepositAmount(loan?.deposit_amount ?? "");
    setInterestAmount(loan?.interest_amount ?? "");
    setTotalInstallments(loan ? String(loan.total_installments) : "");
    setInstallmentAmount(loan?.installment_amount ?? "");
    setInstallmentFrequency(loan?.installment_frequency ?? "MONTHLY");
    setStartDate(loan?.start_date ?? "");
    setError(null);
  }, [open, loan]);

  const isValid =
    lenderName.trim() && loanAmount && totalInstallments && Number(totalInstallments) > 0 && installmentAmount && startDate;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: LoanPayload = {
        lender_name: lenderName.trim(),
        lender_type: lenderType,
        loan_amount: Number(loanAmount),
        deposit_amount: depositAmount ? Number(depositAmount) : undefined,
        interest_amount: interestAmount ? Number(interestAmount) : undefined,
        total_installments: Number(totalInstallments),
        installment_amount: Number(installmentAmount),
        installment_frequency: installmentFrequency,
        start_date: startDate,
      };
      const saved = loan ? await updateLoan(loan.id, payload) : await createLoan(payload);
      toast.success(isEdit ? "Loan updated." : "Loan added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the loan."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit loan" : "Add loan"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this loan's details." : "Record a new loan from a bank or NGO."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="loan-lender-name">
                Lender Name <span className="text-destructive">*</span>
              </Label>
              <Input
                id="loan-lender-name"
                required
                value={lenderName}
                onChange={(event) => setLenderName(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Lender Type</Label>
              <Select value={lenderType} onValueChange={(value) => setLenderType(value as LenderType)}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="BANK">Bank</SelectItem>
                  <SelectItem value="NGO">NGO</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2">
              <Label htmlFor="loan-amount">
                Loan Amount <span className="text-destructive">*</span>
              </Label>
              <Input
                id="loan-amount"
                type="number"
                min={0}
                step="0.01"
                required
                value={loanAmount}
                onChange={(event) => setLoanAmount(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="loan-deposit-amount">Deposit</Label>
              <Input
                id="loan-deposit-amount"
                type="number"
                min={0}
                step="0.01"
                value={depositAmount}
                onChange={(event) => setDepositAmount(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="loan-interest-amount">Interest</Label>
              <Input
                id="loan-interest-amount"
                type="number"
                min={0}
                step="0.01"
                value={interestAmount}
                onChange={(event) => setInterestAmount(event.target.value)}
              />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2">
              <Label htmlFor="loan-total-installments">
                Installments <span className="text-destructive">*</span>
              </Label>
              <Input
                id="loan-total-installments"
                type="number"
                min={1}
                required
                value={totalInstallments}
                onChange={(event) => setTotalInstallments(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="loan-installment-amount">
                Installment Amt <span className="text-destructive">*</span>
              </Label>
              <Input
                id="loan-installment-amount"
                type="number"
                min={0}
                step="0.01"
                required
                value={installmentAmount}
                onChange={(event) => setInstallmentAmount(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Frequency</Label>
              <Select
                value={installmentFrequency}
                onValueChange={(value) => setInstallmentFrequency(value as InstallmentFrequency)}
              >
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="WEEKLY">Weekly</SelectItem>
                  <SelectItem value="MONTHLY">Monthly</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="loan-start-date">
              Start Date <span className="text-destructive">*</span>
            </Label>
            <Input
              id="loan-start-date"
              type="date"
              required
              value={startDate}
              onChange={(event) => setStartDate(event.target.value)}
            />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting} className="text-white">
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
