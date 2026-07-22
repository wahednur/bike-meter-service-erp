"use client";

import { Package } from "lucide-react";
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
import { getStockReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { StockReport } from "@/lib/types";

export function StockTab() {
  const [report, setReport] = useState<StockReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getStockReport()
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load the stock report."));
      });
  }, []);

  return (
    <div className="space-y-4">
      <p className="text-xs text-muted-foreground">
        This is a live, point-in-time snapshot — the date filter above doesn&apos;t apply here since there&apos;s no
        historical stock log.
      </p>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!report && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : report ? (
        <>
          <ReportStats
            items={[
              { label: "Products", value: String(report.total_products) },
              { label: "Stock Value", value: `৳${report.total_stock_value}` },
              { label: "Potential Sale Value", value: `৳${report.total_potential_sale_value}` },
            ]}
          />

          {report.rows.length === 0 ? (
            <EmptyState icon={Package} title="No products in stock" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Product</TableHead>
                    <TableHead>SKU</TableHead>
                    <TableHead className="text-right">Qty</TableHead>
                    <TableHead className="text-right">Buy Price</TableHead>
                    <TableHead className="text-right">Sale Price</TableHead>
                    <TableHead className="text-right">Stock Value</TableHead>
                    <TableHead className="text-right">Potential Sale Value</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.id}>
                      <TableCell className="font-medium">{row.name}</TableCell>
                      <TableCell className="text-muted-foreground">{row.sku}</TableCell>
                      <TableCell className="text-right">{row.current_stock_quantity}</TableCell>
                      <TableCell className="text-right">৳{row.buy_price}</TableCell>
                      <TableCell className="text-right">৳{row.sale_price}</TableCell>
                      <TableCell className="text-right">৳{row.stock_value}</TableCell>
                      <TableCell className="text-right">৳{row.potential_sale_value}</TableCell>
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
