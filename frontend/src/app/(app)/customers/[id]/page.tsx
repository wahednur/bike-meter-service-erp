"use client";

import { ArrowLeft, Pencil, Receipt } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { CustomerFormDialog } from "@/components/customer-form-dialog";
import { EmptyState } from "@/components/empty-state";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getCustomer, getCustomerLedger } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Customer, CustomerLedger, InvoiceStatus } from "@/lib/types";

function statusBadgeVariant(status: InvoiceStatus): "secondary" | "destructive" | "outline" {
  switch (status) {
    case "PAID":
      // Not "default" - Badge's default variant (bg-primary text-primary-foreground)
      // is low-contrast in dark mode (see button.tsx's comment on the same
      // broken --primary-foreground token). "secondary" is already used for
      // "good standing" elsewhere on this page and reads safely in both themes.
      return "secondary";
    case "PARTIAL":
      return "secondary";
    case "CANCELLED":
      return "outline";
    default:
      return "destructive"; // UNPAID
  }
}

function CustomerLedgerCard({ ledger }: { ledger: CustomerLedger }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Customer Ledger</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <dl className="grid grid-cols-3 gap-3 text-sm">
          <div>
            <dt className="text-xs text-muted-foreground">Total Billed</dt>
            <dd className="text-lg font-semibold">৳{ledger.total_billed}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Total Paid</dt>
            <dd className="text-lg font-semibold">৳{ledger.total_paid}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Total Due</dt>
            <dd className="text-lg font-semibold">৳{ledger.total_due}</dd>
          </div>
        </dl>

        {ledger.invoices.length === 0 ? (
          <EmptyState icon={Receipt} title="No invoices yet" />
        ) : (
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Invoice</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                  <TableHead className="text-right">Paid</TableHead>
                  <TableHead className="text-right">Outstanding</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {ledger.invoices.map((invoice) => (
                  <TableRow key={invoice.id}>
                    <TableCell className="font-medium">{invoice.invoice_no}</TableCell>
                    <TableCell className="text-muted-foreground">{invoice.created_date}</TableCell>
                    <TableCell>
                      <Badge variant={statusBadgeVariant(invoice.status)}>{invoice.status}</Badge>
                    </TableCell>
                    <TableCell className="text-right">৳{invoice.total_amount}</TableCell>
                    <TableCell className="text-right">
                      ৳{invoice.paid_amount}
                      {Number(invoice.waived_amount) > 0 && (
                        <p className="text-xs font-medium text-amber-700 dark:text-amber-400">
                          Waived ৳{invoice.waived_amount}
                          {invoice.waived_note ? ` — ${invoice.waived_note}` : ""}
                        </p>
                      )}
                    </TableCell>
                    <TableCell className="text-right">৳{invoice.outstanding_amount}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export default function CustomerDetailPage() {
  const params = useParams<{ id: string }>();
  const customerId = Number(params.id);

  const [customer, setCustomer] = useState<Customer | null>(null);
  const [ledger, setLedger] = useState<CustomerLedger | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([getCustomer(customerId), getCustomerLedger(customerId)])
      .then(([customerResult, ledgerResult]) => {
        setCustomer(customerResult);
        setLedger(ledgerResult);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this customer."));
      });
  }, [customerId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!customer || !ledger) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link href="/customers" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to customers
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{customer.name}</CardTitle>
            {customer.is_red_listed ? (
              <Badge variant="destructive">Red-listed</Badge>
            ) : (
              <Badge variant="secondary">Good standing</Badge>
            )}
          </div>
          <CustomerFormDialog
            customer={customer}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
        <CardContent className="space-y-4">
          <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
            <div>
              <dt className="text-xs text-muted-foreground">Phone</dt>
              <dd>{customer.phone}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Email</dt>
              <dd>{customer.email ?? "—"}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Address</dt>
              <dd>{customer.address || "—"}</dd>
            </div>
          </dl>
          {customer.description && (
            <div>
              <dt className="mb-1 text-xs text-muted-foreground">Description</dt>
              <dd className="text-sm">{customer.description}</dd>
            </div>
          )}
        </CardContent>
      </Card>

      <CustomerLedgerCard ledger={ledger} />
    </div>
  );
}
