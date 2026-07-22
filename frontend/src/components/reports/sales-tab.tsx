"use client";

import { TrendingUp } from "lucide-react";
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
import { getSalesReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { SalesReport } from "@/lib/types";

export function SalesTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<SalesReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getSalesReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the sales report."));
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
              { label: "Total Sales", value: `৳${report.total_sales}` },
              { label: "Line Items", value: String(report.line_count) },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={TrendingUp} title="No sales in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Invoice</TableHead>
                    <TableHead>Customer</TableHead>
                    <TableHead>Item</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead className="text-right">Qty</TableHead>
                    <TableHead className="text-right">Unit Price</TableHead>
                    <TableHead className="text-right">Total</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row, index) => (
                    <TableRow key={`${row.invoice_no}-${row.item_name}-${index}`}>
                      <TableCell className="text-muted-foreground">{row.date}</TableCell>
                      <TableCell>{row.invoice_no}</TableCell>
                      <TableCell>{row.customer_name}</TableCell>
                      <TableCell className="font-medium">{row.item_name}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{row.type}</Badge>
                      </TableCell>
                      <TableCell className="text-right">{row.quantity}</TableCell>
                      <TableCell className="text-right">৳{row.unit_price}</TableCell>
                      <TableCell className="text-right">৳{row.line_total}</TableCell>
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
