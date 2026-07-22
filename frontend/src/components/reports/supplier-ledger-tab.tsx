"use client";

import { Package } from "lucide-react";
import { useEffect, useState } from "react";

import { Combobox, type ComboboxOption } from "@/components/combobox";
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
import { getSupplierLedger, listSuppliers } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Supplier, SupplierLedger } from "@/lib/types";

export function SupplierLedgerTab({ fromDate, toDate }: { fromDate?: string; toDate?: string }) {
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [supplierId, setSupplierId] = useState<number | null>(null);
  const [ledger, setLedger] = useState<SupplierLedger | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listSuppliers()
      .then(setSuppliers)
      .catch(() => {
        // picker is supplementary - a failure shouldn't block the rest of the tab
      });
  }, []);

  useEffect(() => {
    if (!supplierId) {
      setLedger(null);
      return;
    }
    setLedger(null);
    setError(null);
    getSupplierLedger(supplierId, { fromDate, toDate })
      .then(setLedger)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this supplier's ledger."));
      });
  }, [supplierId, fromDate, toDate]);

  const supplierOptions: ComboboxOption[] = suppliers.map((supplier) => ({
    value: supplier.id,
    label: supplier.name,
    description: supplier.phone,
  }));

  return (
    <div className="space-y-4">
      <div className="w-72 space-y-1.5">
        <label className="text-xs font-medium text-muted-foreground">Supplier</label>
        <Combobox
          options={supplierOptions}
          value={supplierId}
          onChange={setSupplierId}
          placeholder="Search suppliers..."
          searchPlaceholder="Search suppliers..."
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!supplierId ? (
        <p className="text-sm text-muted-foreground">Pick a supplier to see their ledger.</p>
      ) : !ledger && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : ledger ? (
        <>
          <h3 className="font-medium">{ledger.supplier.name}</h3>

          <ReportStats
            items={[
              { label: "Total Purchase Amount", value: `৳${ledger.total_purchase_amount}` },
              { label: "Purchases In Range", value: `৳${ledger.purchases_in_range}` },
              { label: "Payment Status", value: ledger.payment_status },
            ]}
          />
          <p className="text-xs text-muted-foreground">
            &quot;Total Purchase Amount&quot; is a live stock-on-hand snapshot (not date-filtered); only
            &quot;Purchases In Range&quot; respects the date filter above.
          </p>

          {ledger.products.length === 0 ? (
            <EmptyState icon={Package} title="No products from this supplier" />
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
        </>
      ) : null}
    </div>
  );
}
