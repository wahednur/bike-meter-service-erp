"use client";

import { History } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { DatePickerButton } from "@/components/date-picker-button";
import { EmptyState } from "@/components/empty-state";
import { ListPagination } from "@/components/list-pagination";
import { Badge } from "@/components/ui/badge";
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
import { getAuditLog, listUsers } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { AuditFeedEntry, SystemUser } from "@/lib/types";

const PAGE_SIZE = 25;

// Only models with a real detail page in this app get a link - everything
// else (invoice line items, restock events, etc.) renders as plain text.
const MODEL_ROUTES: Record<string, string> = {
  customer: "/customers",
  supplier: "/suppliers",
  meter: "/meters",
  mileagecorrectiondevice: "/devices",
  servicecategory: "/service-categories",
  service: "/services",
  product: "/products",
  invoice: "/invoices",
  asset: "/assets",
  loan: "/loans",
};

const MODEL_OPTIONS = [
  { value: "ALL", label: "All models" },
  { value: "customer", label: "Customer" },
  { value: "supplier", label: "Supplier" },
  { value: "meter", label: "Meter" },
  { value: "mileagecorrectiondevice", label: "Correction Device" },
  { value: "servicecategory", label: "Service Category" },
  { value: "service", label: "Service" },
  { value: "product", label: "Product" },
  { value: "productrestockevent", label: "Product Restock Event" },
  { value: "purchase", label: "Purchase" },
  { value: "invoice", label: "Invoice" },
  { value: "invoicepayment", label: "Invoice Payment" },
  { value: "invoicemeterentry", label: "Invoice Meter Entry" },
  { value: "invoiceserviceline", label: "Invoice Service Line" },
  { value: "invoiceproductline", label: "Invoice Product Line" },
  { value: "asset", label: "Asset" },
  { value: "assetincident", label: "Asset Incident" },
  { value: "loan", label: "Loan" },
  { value: "loaninstallmentpayment", label: "Loan Installment Payment" },
  { value: "user", label: "User" },
];

const ACTION_OPTIONS = [
  { value: "ALL", label: "All actions" },
  { value: "CREATE", label: "Create" },
  { value: "UPDATE", label: "Update" },
  { value: "DELETE", label: "Delete" },
  { value: "invoice_created", label: "Invoice Created" },
  { value: "meter_entry_added", label: "Meter Entry Added" },
  { value: "service_line_added", label: "Service Line Added" },
  { value: "product_line_added", label: "Product Line Added" },
  { value: "payment_added", label: "Payment Added" },
  { value: "discount_applied", label: "Discount Applied" },
  { value: "customer_red_listed", label: "Customer Red Listed" },
  { value: "customer_red_list_cleared", label: "Customer Red List Cleared" },
  { value: "invoice_cancelled", label: "Invoice Cancelled" },
  { value: "invoice_deleted", label: "Invoice Deleted" },
];

function formatTimestamp(value: string): string {
  return new Date(value).toLocaleString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function AffectedRecordCell({ entry }: { entry: AuditFeedEntry }) {
  const routePrefix = MODEL_ROUTES[entry.model];
  if (!routePrefix) {
    return <span>{entry.record}</span>;
  }
  return (
    <Link href={`${routePrefix}/${entry.object_id}/`} className="text-primary hover:underline">
      {entry.record}
    </Link>
  );
}

export default function AuditLogPage() {
  const [entries, setEntries] = useState<AuditFeedEntry[] | null>(null);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  const [users, setUsers] = useState<SystemUser[]>([]);
  const [dateFrom, setDateFrom] = useState<string | undefined>(undefined);
  const [dateTo, setDateTo] = useState<string | undefined>(undefined);
  const [userId, setUserId] = useState<string | null>(null);
  const [model, setModel] = useState("ALL");
  const [action, setAction] = useState("ALL");

  useEffect(() => {
    listUsers()
      .then(setUsers)
      .catch(() => {});
  }, []);

  const userOptions: ComboboxOption<string>[] = users.map((systemUser) => ({
    value: systemUser.id,
    label: systemUser.name,
    description: systemUser.email ?? systemUser.phone ?? undefined,
  }));

  const loadEntries = useCallback(() => {
    getAuditLog({
      fromDate: dateFrom,
      toDate: dateTo,
      user: userId ?? undefined,
      model: model === "ALL" ? undefined : model,
      action: action === "ALL" ? undefined : action,
      page,
      pageSize: PAGE_SIZE,
    })
      .then((response) => {
        setEntries(response.results);
        setTotalCount(response.count);
        setTotalPages(response.total_pages);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the audit log."));
      });
  }, [dateFrom, dateTo, userId, model, action, page]);

  useEffect(() => {
    loadEntries();
  }, [loadEntries]);

  // Any filter change resets to page 1 - a stale page number could
  // otherwise land past the end of the newly filtered result set.
  useEffect(() => {
    setPage(1);
  }, [dateFrom, dateTo, userId, model, action]);

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold">Audit Log</h1>
        <p className="text-sm text-muted-foreground">
          Every automatic record change and business event (payments, discounts, red-listing, etc.), merged into one
          chronological trail.
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">From</label>
          <DatePickerButton value={dateFrom} onChange={setDateFrom} placeholder="Any" />
        </div>
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">To</label>
          <DatePickerButton value={dateTo} onChange={setDateTo} placeholder="Any" />
        </div>
        <div className="w-56 space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">User</label>
          <Combobox
            options={userOptions}
            value={userId}
            onChange={setUserId}
            placeholder="All users"
            searchPlaceholder="Search users..."
            emptyMessage="No users found."
            allowClear
          />
        </div>
        <div className="w-56 space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">Model</label>
          <Select value={model} onValueChange={setModel}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {MODEL_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="w-56 space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">Action</label>
          <Select value={action} onValueChange={setAction}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {ACTION_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!entries && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : entries && entries.length === 0 ? (
        <EmptyState icon={History} title="No audit entries match these filters" />
      ) : (
        entries && (
          <>
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Timestamp</TableHead>
                    <TableHead>User</TableHead>
                    <TableHead>Action</TableHead>
                    <TableHead>Affected Record</TableHead>
                    <TableHead>Summary</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {entries.map((entry) => (
                    <TableRow key={entry.id}>
                      <TableCell className="whitespace-nowrap text-muted-foreground">
                        {formatTimestamp(entry.timestamp)}
                      </TableCell>
                      <TableCell>{entry.user ?? "—"}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{entry.action_display}</Badge>
                      </TableCell>
                      <TableCell>
                        <AffectedRecordCell entry={entry} />
                      </TableCell>
                      <TableCell className="max-w-md text-muted-foreground">{entry.summary}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
            <ListPagination page={page} totalPages={totalPages} totalCount={totalCount} onPageChange={setPage} />
          </>
        )
      )}
    </div>
  );
}
