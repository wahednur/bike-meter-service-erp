"use client";

import { ShoppingCart } from "lucide-react";
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
import { getPurchaseReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { PurchaseReport } from "@/lib/types";

export function PurchaseTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<PurchaseReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getPurchaseReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the purchase report."));
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
              { label: "Total Purchases", value: `৳${report.total_purchases}` },
              { label: "Transactions", value: String(report.transaction_count) },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={ShoppingCart} title="No purchases in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Name</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Supplier</TableHead>
                    <TableHead className="text-right">Qty</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row, index) => (
                    <TableRow key={`${row.name}-${row.date}-${index}`}>
                      <TableCell className="text-muted-foreground">{row.date}</TableCell>
                      <TableCell className="font-medium">{row.name}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{row.type.replace(/_/g, " ")}</Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{row.supplier_name ?? "—"}</TableCell>
                      <TableCell className="text-right">{row.quantity}</TableCell>
                      <TableCell className="text-right">৳{row.amount}</TableCell>
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
