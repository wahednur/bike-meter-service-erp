"use client";

import { ArrowLeft, Package, Pencil, TrendingUp } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { SupplierFormDialog } from "@/components/supplier-form-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getSupplier, getSupplierLedger, getSupplierProfitAnalysis } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Supplier, SupplierLedger, SupplierProfitAnalysisRow } from "@/lib/types";

function formatDecimal(value: number | string): string {
  const num = typeof value === "string" ? Number(value) : value;
  return Number.isFinite(num) ? num.toFixed(2) : String(value);
}

function SupplierLedgerCard({ ledger }: { ledger: SupplierLedger }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Supplier Ledger</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
          <div>
            <dt className="text-xs text-muted-foreground">Total Purchase Amount</dt>
            <dd className="text-lg font-semibold">৳{ledger.total_purchase_amount}</dd>
            <dd className="text-xs text-muted-foreground">Cost basis of current stock on hand</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Purchases In Range</dt>
            <dd className="text-lg font-semibold">৳{ledger.purchases_in_range}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Payment Status</dt>
            <dd>
              <Badge variant="outline">{ledger.payment_status}</Badge>
            </dd>
          </div>
        </dl>

        {ledger.products.length === 0 ? (
          <EmptyState icon={Package} title="No products supplied yet" />
        ) : (
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Product</TableHead>
                  <TableHead>SKU</TableHead>
                  <TableHead className="text-right">Buy Price</TableHead>
                  <TableHead className="text-right">Sale Price</TableHead>
                  <TableHead className="text-right">Stock Qty</TableHead>
                  <TableHead className="text-right">Stock Value</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {ledger.products.map((product) => (
                  <TableRow key={product.id}>
                    <TableCell className="font-medium">{product.name}</TableCell>
                    <TableCell className="text-muted-foreground">{product.sku}</TableCell>
                    <TableCell className="text-right">৳{product.buy_price}</TableCell>
                    <TableCell className="text-right">৳{product.sale_price}</TableCell>
                    <TableCell className="text-right">{product.current_stock_quantity}</TableCell>
                    <TableCell className="text-right">৳{product.stock_value}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function ProfitMarginCard({ row }: { row: SupplierProfitAnalysisRow | null }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Profit Margin Analysis</CardTitle>
      </CardHeader>
      <CardContent>
        {!row ? (
          <EmptyState icon={TrendingUp} title="No product data yet for this supplier" />
        ) : (
          <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
            <div>
              <dt className="text-xs text-muted-foreground">Products Supplied</dt>
              <dd className="text-lg font-semibold">{row.product_count}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Avg Buy Price</dt>
              <dd className="text-lg font-semibold">৳{formatDecimal(row.avg_buy_price)}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Avg Sale Price</dt>
              <dd className="text-lg font-semibold">৳{formatDecimal(row.avg_sale_price)}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Avg Profit Margin</dt>
              <dd className="text-lg font-semibold">৳{formatDecimal(row.avg_profit_margin)}</dd>
            </div>
          </dl>
        )}
      </CardContent>
    </Card>
  );
}

export default function SupplierDetailPage() {
  const params = useParams<{ id: string }>();
  const supplierId = Number(params.id);

  const [supplier, setSupplier] = useState<Supplier | null>(null);
  const [ledger, setLedger] = useState<SupplierLedger | null>(null);
  const [profitRow, setProfitRow] = useState<SupplierProfitAnalysisRow | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([getSupplier(supplierId), getSupplierLedger(supplierId), getSupplierProfitAnalysis()])
      .then(([supplierResult, ledgerResult, profitRows]) => {
        setSupplier(supplierResult);
        setLedger(ledgerResult);
        setProfitRow(profitRows.find((row) => row.supplier_id === supplierId) ?? null);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this supplier."));
      });
  }, [supplierId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!supplier || !ledger) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link href="/suppliers" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to suppliers
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <CardTitle className="text-xl">{supplier.name}</CardTitle>
          <SupplierFormDialog
            supplier={supplier}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
            <div>
              <dt className="text-xs text-muted-foreground">Phone</dt>
              <dd>{supplier.phone}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Address</dt>
              <dd>{supplier.address || "—"}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Note</dt>
              <dd>{supplier.note || "—"}</dd>
            </div>
          </dl>
        </CardContent>
      </Card>

      <SupplierLedgerCard ledger={ledger} />
      <ProfitMarginCard row={profitRow} />
    </div>
  );
}
