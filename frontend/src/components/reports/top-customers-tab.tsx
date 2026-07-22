"use client";

import { Users } from "lucide-react";
import { useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ReportStats } from "@/components/reports/report-stats";
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
import { getTopCustomersReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { TopCustomersReport, TopCustomersSortBy } from "@/lib/types";

const SORT_OPTIONS: { value: TopCustomersSortBy; label: string }[] = [
  { value: "total_billed_amount", label: "Total Billed Amount" },
  { value: "invoice_count", label: "Invoice Count" },
];

export function TopCustomersTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [sortBy, setSortBy] = useState<TopCustomersSortBy>("total_billed_amount");
  const [report, setReport] = useState<TopCustomersReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getTopCustomersReport({ fromDate, toDate }, sortBy)
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the top customers report."));
      });
  }, [fromDate, toDate, sortBy]);

  const totalBilled = report?.rows.reduce((sum, row) => sum + Number(row.total_billed_amount), 0) ?? 0;
  const totalDue = report?.rows.reduce((sum, row) => sum + Number(row.total_due_amount), 0) ?? 0;

  return (
    <div className="space-y-4">
      <div className="w-56 space-y-1.5">
        <label className="text-xs font-medium text-muted-foreground">Sort by</label>
        <Select value={sortBy} onValueChange={(value) => setSortBy(value as TopCustomersSortBy)}>
          <SelectTrigger className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {SORT_OPTIONS.map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!report && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : report ? (
        <>
          <ReportStats
            items={[
              { label: "Customers", value: String(report.customer_count) },
              { label: "Total Billed", value: `৳${totalBilled.toFixed(2)}` },
              { label: "Total Due", value: `৳${totalDue.toFixed(2)}` },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={Users} title="No invoices in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Customer</TableHead>
                    <TableHead className="text-right">Invoices</TableHead>
                    <TableHead className="text-right">Total Billed</TableHead>
                    <TableHead className="text-right">Total Paid</TableHead>
                    <TableHead className="text-right">Total Due</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.customer_id}>
                      <TableCell className="font-medium">{row.customer_name}</TableCell>
                      <TableCell className="text-right">{row.invoice_count}</TableCell>
                      <TableCell className="text-right">৳{row.total_billed_amount}</TableCell>
                      <TableCell className="text-right">৳{row.total_paid_amount}</TableCell>
                      <TableCell className="text-right font-medium text-destructive">
                        ৳{row.total_due_amount}
                      </TableCell>
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
