"use client";

import { FileText, Plus } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { DatePickerButton } from "@/components/date-picker-button";
import { DueAmount } from "@/components/due-amount";
import { EmptyState } from "@/components/empty-state";
import { InvoiceStatusBadge } from "@/components/invoice-status-badge";
import { ListPagination } from "@/components/list-pagination";
import { RowActions } from "@/components/row-actions";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { deleteInvoice, listCustomers, listInvoices } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Customer, Invoice, InvoiceStatus } from "@/lib/types";

const PAGE_SIZE = 15;
const STATUS_OPTIONS: { value: InvoiceStatus | "ALL"; label: string }[] = [
  { value: "ALL", label: "All statuses" },
  { value: "UNPAID", label: "Unpaid" },
  { value: "PARTIAL", label: "Partial Paid" },
  { value: "PAID", label: "Paid" },
  { value: "CANCELLED", label: "Cancelled" },
];

export default function InvoicesPage() {
  const router = useRouter();
  const [invoices, setInvoices] = useState<Invoice[] | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  const [status, setStatus] = useState<InvoiceStatus | "ALL">("ALL");
  const [customerId, setCustomerId] = useState<number | null>(null);
  const [dateFrom, setDateFrom] = useState<string | undefined>(undefined);
  const [dateTo, setDateTo] = useState<string | undefined>(undefined);

  const loadInvoices = useCallback(() => {
    listInvoices({
      status: status === "ALL" ? undefined : status,
      customer: customerId ?? undefined,
      dateFrom,
      dateTo,
    })
      .then(setInvoices)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load invoices."));
      });
  }, [status, customerId, dateFrom, dateTo]);

  useEffect(() => {
    setPage(1);
    loadInvoices();
  }, [loadInvoices]);

  useEffect(() => {
    listCustomers()
      .then(setCustomers)
      .catch(() => {
        // customer names/filter are supplementary - a failure here shouldn't
        // block viewing the invoice list itself
      });
  }, []);

  const customerOptions: ComboboxOption[] = customers.map((customer) => ({
    value: customer.id,
    label: customer.name,
    description: customer.phone,
  }));

  const totalPages = Math.max(1, Math.ceil((invoices?.length ?? 0) / PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const pageItems = (invoices ?? []).slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Invoices</h1>
          <p className="text-sm text-muted-foreground">Browse and filter every invoice.</p>
        </div>
        <Button asChild>
          <Link href="/invoices/new">
            <Plus /> New Invoice
          </Link>
        </Button>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="w-44 space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">Status</label>
          <Select value={status} onValueChange={(value) => setStatus(value as InvoiceStatus | "ALL")}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {STATUS_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
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

      {!invoices && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : invoices && invoices.length === 0 ? (
        <EmptyState icon={FileText} title="No invoices match these filters" />
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Invoice No</TableHead>
                  <TableHead>Customer</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                  <TableHead className="text-right">Paid</TableHead>
                  <TableHead className="text-right">Due Amount</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.map((invoice) => (
                  <TableRow key={invoice.id} className="cursor-pointer">
                    <TableCell className="font-medium">
                      <Link href={`/invoices/${invoice.id}`} className="block">
                        {invoice.invoice_no}
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Link href={`/invoices/${invoice.id}`} className="block">
                        {invoice.customer_name}
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Link href={`/invoices/${invoice.id}`} className="block">
                        <InvoiceStatusBadge status={invoice.status} />
                      </Link>
                    </TableCell>
                    <TableCell className="text-right">
                      <Link href={`/invoices/${invoice.id}`} className="block">
                        ৳{invoice.total_amount}
                      </Link>
                    </TableCell>
                    <TableCell className="text-right">
                      <Link href={`/invoices/${invoice.id}`} className="block">
                        ৳{invoice.paid_amount}
                      </Link>
                    </TableCell>
                    <TableCell className="text-right">
                      <Link href={`/invoices/${invoice.id}`} className="flex justify-end">
                        <DueAmount amount={invoice.due_amount} status={invoice.status} />
                      </Link>
                    </TableCell>
                    <TableCell>
                      <Link href={`/invoices/${invoice.id}`} className="block text-muted-foreground">
                        {invoice.created_date}
                      </Link>
                    </TableCell>
                    <TableCell>
                      <RowActions
                        resourceLabel="Invoice"
                        onEdit={() => router.push(`/invoices/${invoice.id}`)}
                        onDelete={() =>
                          deleteInvoice(invoice.id).then(() =>
                            setInvoices((prev) => prev?.filter((item) => item.id !== invoice.id) ?? prev),
                          )
                        }
                        deleteDescription="It will disappear from lists immediately. This is a soft delete - the record stays in the database. Fully paid invoices can't be deleted."
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <ListPagination
            page={currentPage}
            totalPages={totalPages}
            totalCount={invoices?.length ?? 0}
            onPageChange={setPage}
          />
        </>
      )}
    </div>
  );
}
