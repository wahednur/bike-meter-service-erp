"use client";

import { FileText } from "lucide-react";
import { useEffect, useState } from "react";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { EmptyState } from "@/components/empty-state";
import { ReportStats } from "@/components/reports/report-stats";
import { Badge } from "@/components/ui/badge";
import { InvoiceStatusBadge } from "@/components/invoice-status-badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getCustomerLedger, listCustomers } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Customer, CustomerLedger } from "@/lib/types";

export function CustomerLedgerTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [customerId, setCustomerId] = useState<number | null>(null);
  const [ledger, setLedger] = useState<CustomerLedger | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listCustomers()
      .then(setCustomers)
      .catch(() => {
        // picker is supplementary - a failure shouldn't block the rest of the tab
      });
  }, []);

  useEffect(() => {
    if (!customerId) {
      setLedger(null);
      return;
    }
    setLedger(null);
    setError(null);
    getCustomerLedger(customerId, { fromDate, toDate })
      .then(setLedger)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this customer's ledger."));
      });
  }, [customerId, fromDate, toDate]);

  const customerOptions: ComboboxOption[] = customers.map((customer) => ({
    value: customer.id,
    label: customer.name,
    description: customer.phone,
  }));

  return (
    <div className="space-y-4">
      <div className="w-72 space-y-1.5">
        <label className="text-xs font-medium text-muted-foreground">Customer</label>
        <Combobox
          options={customerOptions}
          value={customerId}
          onChange={setCustomerId}
          placeholder="Search customers..."
          searchPlaceholder="Search customers..."
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!customerId ? (
        <p className="text-sm text-muted-foreground">Pick a customer to see their ledger.</p>
      ) : !ledger && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : ledger ? (
        <>
          <div className="flex items-center gap-2">
            <h3 className="font-medium">{ledger.customer.name}</h3>
            {ledger.customer.is_red_listed && <Badge variant="destructive">Red-listed</Badge>}
          </div>

          <ReportStats
            items={[
              { label: "Total Billed", value: `৳${ledger.total_billed}` },
              { label: "Total Paid", value: `৳${ledger.total_paid}` },
              { label: "Total Due", value: `৳${ledger.total_due}` },
            ]}
          />

          {ledger.invoices.length === 0 ? (
            <EmptyState icon={FileText} title="No invoices in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Invoice</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                    <TableHead className="text-right">Paid</TableHead>
                    <TableHead className="text-right">Outstanding</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {ledger.invoices.map((invoice) => (
                    <TableRow key={invoice.id}>
                      <TableCell className="font-medium">{invoice.invoice_no}</TableCell>
                      <TableCell>
                        <InvoiceStatusBadge status={invoice.status} />
                      </TableCell>
                      <TableCell className="text-muted-foreground">{invoice.created_date}</TableCell>
                      <TableCell className="text-right">৳{invoice.total_amount}</TableCell>
                      <TableCell className="text-right">৳{invoice.paid_amount}</TableCell>
                      <TableCell className="text-right">৳{invoice.outstanding_amount}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </>
      ) : null}
    </div>
  );
}
