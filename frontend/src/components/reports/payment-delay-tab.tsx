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
import { getPaymentDelayReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { PaymentDelayReport } from "@/lib/types";

// Two escalating thresholds: a two-week gap gets a soft amber nudge, a
// month or more gets the theme's actual destructive (red) treatment - the
// worst offenders should look alarming, not just "different."
const SEVERE_DELAY_DAYS = 30;
const WARNING_DELAY_DAYS = 14;

function DelayBadge({ days }: { days: number }) {
  if (days >= SEVERE_DELAY_DAYS) {
    return <Badge variant="destructive">{days} days</Badge>;
  }
  if (days >= WARNING_DELAY_DAYS) {
    return (
      <Badge className="border-transparent bg-amber-500/10 text-amber-600 dark:bg-amber-500/20 dark:text-amber-400">
        {days} days
      </Badge>
    );
  }
  return <Badge variant="outline">{days} days</Badge>;
}

export function PaymentDelayTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<PaymentDelayReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getPaymentDelayReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the payment delay report."));
      });
  }, [fromDate, toDate]);

  const totalDue = report?.rows.reduce((sum, row) => sum + Number(row.amount_due), 0) ?? 0;
  const worstDelay = report?.rows.reduce((max, row) => Math.max(max, row.days_delayed), 0) ?? 0;

  return (
    <div className="space-y-4">
      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!report && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : report ? (
        <>
          <ReportStats
            items={[
              { label: "Customers Affected", value: String(report.customer_count) },
              { label: "Total Amount Due", value: `৳${totalDue.toFixed(2)}` },
              { label: "Longest Delay", value: `${worstDelay} days` },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={CircleCheck} title="No overdue payments in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Customer</TableHead>
                    <TableHead>Invoice(s)</TableHead>
                    <TableHead>Days Delayed</TableHead>
                    <TableHead className="text-right">Amount Due</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.customer_id}>
                      <TableCell className="font-medium">{row.customer_name}</TableCell>
                      <TableCell className="text-muted-foreground">{row.invoice_nos.join(", ")}</TableCell>
                      <TableCell>
                        <DelayBadge days={row.days_delayed} />
                      </TableCell>
                      <TableCell className="text-right font-medium">৳{row.amount_due}</TableCell>
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
