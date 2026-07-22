"use client";

import { Wrench } from "lucide-react";
import { useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ReportStats } from "@/components/reports/report-stats";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getServicePerformanceReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ServicePerformanceReport } from "@/lib/types";

export function ServiceReportTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [report, setReport] = useState<ServicePerformanceReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReport(null);
    setError(null);
    getServicePerformanceReport({ fromDate, toDate })
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the service report."));
      });
  }, [fromDate, toDate]);

  const totalRevenue = report?.rows.reduce((sum, row) => sum + Number(row.total_revenue), 0) ?? 0;
  const totalTimesPerformed = report?.rows.reduce((sum, row) => sum + row.times_performed, 0) ?? 0;

  return (
    <div className="space-y-4">
      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!report && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : report ? (
        <>
          <ReportStats
            items={[
              { label: "Services", value: String(report.service_count) },
              { label: "Times Performed", value: String(totalTimesPerformed) },
              { label: "Total Revenue", value: `৳${totalRevenue.toFixed(2)}` },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={Wrench} title="No services performed in this range" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Service</TableHead>
                    <TableHead className="text-right">Times Performed</TableHead>
                    <TableHead className="text-right">Total Revenue</TableHead>
                    <TableHead className="text-right">Average Price</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.service_id}>
                      <TableCell className="font-medium">{row.service_name}</TableCell>
                      <TableCell className="text-right">{row.times_performed}</TableCell>
                      <TableCell className="text-right">৳{row.total_revenue}</TableCell>
                      <TableCell className="text-right text-muted-foreground">৳{row.average_price}</TableCell>
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
