"use client";

import { ArrowLeft, Paperclip, Pencil, Receipt } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { AddInstallmentPaymentDialog } from "@/components/add-installment-payment-dialog";
import { EmptyState } from "@/components/empty-state";
import { InstallmentDetailDialog } from "@/components/installment-detail-dialog";
import { LoanFormDialog } from "@/components/loan-form-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getLoan, listLoanInstallmentPayments } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Loan, LoanInstallmentPayment } from "@/lib/types";

export default function LoanDetailPage() {
  const params = useParams<{ id: string }>();
  const loanId = Number(params.id);

  const [loan, setLoan] = useState<Loan | null>(null);
  const [payments, setPayments] = useState<LoanInstallmentPayment[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [selectedPayment, setSelectedPayment] = useState<LoanInstallmentPayment | null>(null);

  const load = useCallback(() => {
    Promise.all([getLoan(loanId), listLoanInstallmentPayments(loanId)])
      .then(([loanResult, paymentsResult]) => {
        setLoan(loanResult);
        setPayments(paymentsResult);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this loan."));
      });
  }, [loanId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!loan) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  const installmentProgress =
    loan.total_installments > 0 ? (loan.installments_paid_count / loan.total_installments) * 100 : 0;
  const amountProgress =
    Number(loan.total_payable) > 0 ? (Number(loan.amount_paid_so_far) / Number(loan.total_payable)) * 100 : 0;
  const isSettled = loan.installments_remaining <= 0 || Number(loan.amount_remaining) <= 0;

  return (
    <div className="space-y-4">
      <Link href="/loans" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to loans
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{loan.lender_name}</CardTitle>
            <Badge variant="outline">{loan.lender_type}</Badge>
            {isSettled && (
              <Badge className="border-transparent bg-green-500/10 text-green-600 dark:bg-green-500/20 dark:text-green-400">
                Settled
              </Badge>
            )}
          </div>
          <div className="flex flex-wrap gap-2">
            {!isSettled && (
              <AddInstallmentPaymentDialog
                loan={loan}
                trigger={
                  <Button type="button" size="sm" className="text-white">
                    Record Payment
                  </Button>
                }
                onPaid={load}
              />
            )}
            <LoanFormDialog
              loan={loan}
              trigger={
                <Button type="button" variant="outline" size="sm">
                  <Pencil /> Edit
                </Button>
              }
              onSaved={load}
            />
          </div>
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
            <div>
              <dt className="text-xs text-muted-foreground">Loan Amount</dt>
              <dd>৳{loan.loan_amount}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Deposit</dt>
              <dd>৳{loan.deposit_amount}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Interest</dt>
              <dd>৳{loan.interest_amount}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Total Payable</dt>
              <dd className="font-medium">৳{loan.total_payable}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Installment Amount</dt>
              <dd>৳{loan.installment_amount}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Frequency</dt>
              <dd>{loan.installment_frequency}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Start Date</dt>
              <dd>{loan.start_date}</dd>
            </div>
          </dl>
        </CardContent>
      </Card>

      {!isSettled && loan.next_installment_number != null && (
        <Card>
          <CardHeader>
            <CardTitle>Next Installment</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between text-sm">
              <span className="flex items-center gap-2">
                <span className="font-medium">#{loan.next_installment_number}</span>
                {loan.next_installment_is_overdue && (
                  <Badge variant="destructive" className="text-xs">
                    Overdue
                  </Badge>
                )}
              </span>
              <span className={loan.next_installment_is_overdue ? "text-destructive" : "text-muted-foreground"}>
                ৳{loan.installment_amount} due {loan.next_installment_due_date}
              </span>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Progress</CardTitle>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Installments Paid</span>
              <span className="font-medium">
                {loan.installments_paid_count} / {loan.total_installments} ({loan.installments_remaining} remaining)
              </span>
            </div>
            <Progress value={installmentProgress} />
          </div>
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">Amount Paid</span>
              <span className="font-medium">
                ৳{loan.amount_paid_so_far} / ৳{loan.total_payable} (৳{loan.amount_remaining} remaining)
              </span>
            </div>
            <Progress value={amountProgress} />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Installment Payments</CardTitle>
        </CardHeader>
        <CardContent>
          {payments.length === 0 ? (
            <EmptyState icon={Receipt} title="No installment payments recorded yet" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Installment #</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead className="text-right">Amount Paid</TableHead>
                    <TableHead className="text-right">Attachment</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {payments
                    .slice()
                    .sort((a, b) => a.installment_number - b.installment_number)
                    .map((payment) => (
                      <TableRow
                        key={payment.id}
                        onClick={() => setSelectedPayment(payment)}
                        className="cursor-pointer"
                      >
                        <TableCell className="font-medium">#{payment.installment_number}</TableCell>
                        <TableCell className="text-muted-foreground">{payment.payment_date}</TableCell>
                        <TableCell className="text-right">৳{payment.amount_paid}</TableCell>
                        <TableCell className="text-right">
                          {payment.attachment ? (
                            <a
                              href={payment.attachment}
                              target="_blank"
                              rel="noopener noreferrer"
                              onClick={(event) => event.stopPropagation()}
                              className="inline-flex items-center gap-1 text-primary hover:underline"
                            >
                              <Paperclip className="h-3.5 w-3.5" /> View
                            </a>
                          ) : (
                            <span className="text-muted-foreground">—</span>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <InstallmentDetailDialog
        payment={selectedPayment}
        onOpenChange={(open) => {
          if (!open) setSelectedPayment(null);
        }}
      />
    </div>
  );
}
