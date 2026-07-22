"use client";

import { Wallet } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { DatePickerButton } from "@/components/date-picker-button";
import { EmptyState } from "@/components/empty-state";
import { ListPagination } from "@/components/list-pagination";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listCustomers, listPayments } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Customer, InvoicePayment } from "@/lib/types";

const PAGE_SIZE = 15;

const PAYMENT_METHOD_LABELS: Record<InvoicePayment["payment_method"], string> = {
  CASH: "Cash",
  BKASH: "bKash",
  NAGAD: "Nagad",
  BANK_TRANSFER: "Bank Transfer",
  CARD: "Card",
  OTHER: "Other",
};

export default function PaymentsPage() {
  const [payments, setPayments] = useState<InvoicePayment[] | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  const [customerId, setCustomerId] = useState<number | null>(null);
  const [dateFrom, setDateFrom] = useState<string | undefined>(undefined);
  const [dateTo, setDateTo] = useState<string | undefined>(undefined);

  const loadPayments = useCallback(() => {
    listPayments({
      customer: customerId ?? undefined,
      dateFrom,
      dateTo,
    })
      .then(setPayments)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load payments."));
      });
  }, [customerId, dateFrom, dateTo]);

  useEffect(() => {
    setPage(1);
    loadPayments();
  }, [loadPayments]);

  useEffect(() => {
    listCustomers()
      .then(setCustomers)
      .catch(() => {
        // customer names/filter are supplementary - a failure here shouldn't
        // block viewing the payments list itself
      });
  }, []);

  const customerOptions: ComboboxOption[] = customers.map((customer) => ({
    value: customer.id,
    label: customer.name,
    description: customer.phone,
  }));

  const totalPages = Math.max(1, Math.ceil((payments?.length ?? 0) / PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const pageItems = (payments ?? []).slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);
  const totalAmount = (payments ?? []).reduce((sum, payment) => sum + Number(payment.amount), 0);

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold">Payments</h1>
        <p className="text-sm text-muted-foreground">Every payment received across all invoices.</p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="w-64 space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">Customer</label>
          <Combobox
            options={customerOptions}
            value={customerId}
            onChange={setCustomerId}
            allowClear
            placeholder="All customers"
            searchPlaceholder="Search customers..."
          />
        </div>
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">From</label>
          <DatePickerButton value={dateFrom} onChange={setDateFrom} placeholder="Any" />
        </div>
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">To</label>
          <DatePickerButton value={dateTo} onChange={setDateTo} placeholder="Any" />
        </div>
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!payments && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : payments && payments.length === 0 ? (
        <EmptyState icon={Wallet} title="No payments match these filters" />
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Invoice</TableHead>
                  <TableHead>Customer</TableHead>
                  <TableHead>Method</TableHead>
                  <TableHead>Note</TableHead>
                  <TableHead className="text-right">Amount</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.map((payment) => (
                  <TableRow key={payment.id} className="cursor-pointer">
                    <TableCell className="text-muted-foreground">
                      <Link href={`/invoices/${payment.invoice}`} className="block">
                        {new Date(payment.payment_date).toLocaleString()}
                      </Link>
                    </TableCell>
                    <TableCell className="font-medium">
                      <Link href={`/invoices/${payment.invoice}`} className="block">
                        {payment.invoice_no}
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Link href={`/invoices/${payment.invoice}`} className="block">
                        {payment.customer_name}
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Link href={`/invoices/${payment.invoice}`} className="block">
                        <Badge variant="outline">{PAYMENT_METHOD_LABELS[payment.payment_method]}</Badge>
                      </Link>
                    </TableCell>
                    <TableCell className="max-w-xs truncate text-muted-foreground">
                      <Link href={`/invoices/${payment.invoice}`} className="block">
                        {payment.note || "—"}
                      </Link>
                    </TableCell>
                    <TableCell className="text-right font-medium">
                      <Link href={`/invoices/${payment.invoice}`} className="block">
                        ৳{payment.amount}
                      </Link>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              Total: <span className="font-medium text-foreground">৳{totalAmount.toFixed(2)}</span>
            </p>
            <ListPagination
              page={currentPage}
              totalPages={totalPages}
              totalCount={payments?.length ?? 0}
              onPageChange={setPage}
            />
          </div>
        </>
      )}
    </div>
  );
}
