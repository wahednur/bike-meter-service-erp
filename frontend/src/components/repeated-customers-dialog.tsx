"use client";

import { Users } from "lucide-react";
import { useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getRepeatedCustomersReport } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { RepeatedCustomersReport } from "@/lib/types";

export function RepeatedCustomersDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const [report, setReport] = useState<RepeatedCustomersReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setReport(null);
    setError(null);
    getRepeatedCustomersReport()
      .then(setReport)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load repeated customers."));
      });
  }, [open]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Repeated Customers</DialogTitle>
          <DialogDescription>Customers with more than one invoice.</DialogDescription>
        </DialogHeader>

        {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

        {!report && !error ? (
          <Skeleton className="h-64 w-full" />
        ) : report ? (
          report.rows.length === 0 ? (
            <EmptyState icon={Users} title="No repeated customers yet" />
          ) : (
            <div className="max-h-[60vh] overflow-y-auto rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Customer</TableHead>
                    <TableHead>Phone</TableHead>
                    <TableHead className="text-right">Invoices</TableHead>
                    <TableHead className="text-right">Total Billed</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {report.rows.map((row) => (
                    <TableRow key={row.customer_id}>
                      <TableCell className="font-medium">{row.customer_name}</TableCell>
                      <TableCell>{row.phone}</TableCell>
                      <TableCell className="text-right">{row.invoice_count}</TableCell>
                      <TableCell className="text-right">৳{row.total_billed_amount}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
