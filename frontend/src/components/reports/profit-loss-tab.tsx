"use client";

import { useEffect, useState } from "react";

import { ReportStats } from "@/components/reports/report-stats";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { getProfitLossReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ProfitLossReport } from "@/lib/types";

function statusBadge(status: ProfitLossReport["status"]) {
  if (status === "PROFIT") {
    return (
      <Badge className="border-transparent bg-green-500/10 text-green-600 dark:bg-green-500/20 dark:text-green-400">
        Profit
      </Badge>
    );
  }
  if (status === "LOSS") {
    return <Badge variant="destructive">Loss</Badge>;
  }
  return <Badge variant="secondary">Break Even</Badge>;
}

export function ProfitLossTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<ProfitLossReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getProfitLossReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the profit/loss report."));
      });
  }, [fromDate, toDate]);

  return (
    <div className="space-y-4">
      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!report && !error ? (
        <Skeleton className="h-40 w-full" />
      ) : report ? (
        <>
          <div className="flex items-center gap-3 rounded-lg border p-4">
            <div>
              <p className="text-xs text-muted-foreground uppercase">Profit / Loss</p>
              <p className="text-2xl font-semibold">৳{report.profit_loss}</p>
            </div>
            {statusBadge(report.status)}
          </div>

          <ReportStats
            items={[
              { label: "Total Income", value: `৳${report.total_income}` },
              { label: "Total Expenses", value: `৳${report.total_expenses}` },
              { label: "Product Restocks", value: `৳${report.expense_breakdown.product_restocks}` },
              { label: "Asset + Device Purchases", value: `৳${(Number(report.expense_breakdown.asset_purchases) + Number(report.expense_breakdown.device_purchases)).toFixed(2)}` },
            ]}
          />
        </>
      ) : null}
    </div>
  );
}
