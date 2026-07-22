"use client";

import { Wallet } from "lucide-react";
import { useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ReportStats } from "@/components/reports/report-stats";
import { ReportTrendChart } from "@/components/reports/report-trend-chart";
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
import { getCashbookReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { CashbookReport } from "@/lib/types";

export function CashbookTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<CashbookReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getCashbookReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the cashbook report."));
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
              { label: "Total In", value: `৳${report.total_in}` },
              { label: "Total Out", value: `৳${report.total_out}` },
              { label: "Net", value: `৳${report.net}` },
            ]}
          />

          <ReportTrendChart
            title="Running Balance"
            description="Relative to the start of the selected range"
            data={report.entries.map((entry) => ({
              date: entry.date,
              value: Number(entry.running_balance),
            }))}
            colorVar="var(--chart-3)"
            valueLabel="Balance"
          />

          {report.entries.length === 0 ? (
            <EmptyState icon={Wallet} title="No cash movement in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Description</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                    <TableHead className="text-right">Balance</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.entries.map((entry, index) => (
                    <TableRow key={`${entry.date}-${index}`}>
                      <TableCell className="text-muted-foreground">{entry.date}</TableCell>
                      <TableCell>
                        <Badge variant={entry.direction === "IN" ? "outline" : "secondary"}>
                          {entry.category.replace(/_/g, " ")}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{entry.description}</TableCell>
                      <TableCell
                        className={`text-right font-medium ${entry.direction === "IN" ? "text-green-600 dark:text-green-400" : "text-destructive"}`}
                      >
                        {entry.direction === "IN" ? "+" : "-"}৳{entry.amount}
                      </TableCell>
                      <TableCell className="text-right">৳{entry.running_balance}</TableCell>
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
