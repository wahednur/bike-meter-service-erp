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
import { getIncomeReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { IncomeReport, ReportPeriod } from "@/lib/types";

const PERIOD_OPTIONS: { value: ReportPeriod; label: string }[] = [
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
  { value: "monthly", label: "Monthly" },
  { value: "yearly", label: "Yearly" },
  { value: "total", label: "Total only" },
];

export function IncomeTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [period, setPeriod] = useState<ReportPeriod>("daily");
  const [report, setReport] = useState<IncomeReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getIncomeReport({ period, fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the income report."));
      });
  }, [period, fromDate, toDate]);

  return (
    <div className="space-y-4">
      <div className="w-48 space-y-1.5">
        <label className="text-xs font-medium text-muted-foreground">Period</label>
        <Select value={period} onValueChange={(value) => setPeriod(value as ReportPeriod)}>
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
          <ReportStats items={[{ label: "Total Income", value: `৳${report.total_income}` }]} />

          {period !== "total" && (
            <ReportTrendChart
              title="Income Trend"
              data={report.rows.map((row) => ({ date: row.period_start, value: Number(row.income) }))}
              colorVar="var(--chart-1)"
              valueLabel="Income"
            />
          )}

          {report.rows.length > 0 && (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Period</TableHead>
                    <TableHead className="text-right">Income</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.period_start}>
                      <TableCell>{row.period_start}</TableCell>
                      <TableCell className="text-right">৳{row.income}</TableCell>
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
