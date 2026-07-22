"use client";

import { CircleCheck } from "lucide-react";
import { useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ReportStats } from "@/components/reports/report-stats";
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
import { getDueReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { DueReport } from "@/lib/types";

export function DueTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<DueReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getDueReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the due report."));
      });
  }, [fromDate, toDate]);

  return (
    <div className="space-y-4">
      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!report && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : report ? (
        <>
          <ReportStats
            items={[
              { label: "Total Due", value: `৳${report.total_due}` },
              { label: "Invoices", value: String(report.invoice_count) },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={CircleCheck} title="Nothing due in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Invoice</TableHead>
                    <TableHead>Customer</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                    <TableHead className="text-right">Paid</TableHead>
                    <TableHead className="text-right">Due</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.invoice_no}>
                      <TableCell className="font-medium">{row.invoice_no}</TableCell>
                      <TableCell>{row.customer_name}</TableCell>
                      <TableCell>
                        <Badge variant={row.status === "UNPAID" ? "destructive" : "outline"}>
                          {row.status === "UNPAID" ? "Unpaid" : "Partial Paid"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{row.created_date}</TableCell>
                      <TableCell className="text-right">৳{row.total_amount}</TableCell>
                      <TableCell className="text-right">৳{row.paid_amount}</TableCell>
                      <TableCell className="text-right font-medium text-destructive">৳{row.due_amount}</TableCell>
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
