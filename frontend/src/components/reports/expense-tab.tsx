"use client";

import { useEffect, useState } from "react";

import { ReportStats } from "@/components/reports/report-stats";
import { ReportTrendChart } from "@/components/reports/report-trend-chart";
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
import { getExpenseReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ExpenseReport, ReportPeriod } from "@/lib/types";

type ExpensePeriod = Exclude<ReportPeriod, "yearly">;

const PERIOD_OPTIONS: { value: ExpensePeriod; label: string }[] = [
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
  { value: "monthly", label: "Monthly" },
  { value: "total", label: "Total only" },
];

export function ExpenseTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [period, setPeriod] = useState<ExpensePeriod>("daily");
  const [report, setReport] = useState<ExpenseReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getExpenseReport(period, { fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the expense report."));
      });
  }, [period, fromDate, toDate]);

  return (
    <div className="space-y-4">
      <div className="w-48 space-y-1.5">
        <label className="text-xs font-medium text-muted-foreground">Period</label>
        <Select value={period} onValueChange={(value) => setPeriod(value as ExpensePeriod)}>
          <SelectTrigger className="w-full">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {PERIOD_OPTIONS.map((option) => (
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
              { label: "Total Expenses", value: `৳${report.total_expenses}` },
              { label: "Product Restocks", value: `৳${report.breakdown.product_restocks}` },
              { label: "Asset Purchases", value: `৳${report.breakdown.asset_purchases}` },
              { label: "Device Purchases", value: `৳${report.breakdown.device_purchases}` },
            ]}
          />

          {period !== "total" && (
            <ReportTrendChart
              title="Expense Trend"
              data={report.rows.map((row) => ({ date: row.period_start, value: Number(row.expense) }))}
              colorVar="var(--chart-2)"
              valueLabel="Expense"
            />
          )}

          {report.rows.length > 0 && (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Period</TableHead>
                    <TableHead className="text-right">Expense</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.period_start}>
                      <TableCell>{row.period_start}</TableCell>
                      <TableCell className="text-right">৳{row.expense}</TableCell>
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
