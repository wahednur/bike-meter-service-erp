"use client";

import { Printer } from "lucide-react";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

import { InvoiceStatusBadge } from "@/components/invoice-status-badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ApiError, getPublicInvoice } from "@/lib/api";
import type { PublicInvoiceDetail } from "@/lib/types";

const DEFAULT_SHOP_NAME = "Nurain Motorcycle Meter Service Center";

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-2">
      <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">{title}</h2>
      {children}
    </section>
  );
}

export default function PublicInvoicePage() {
  const params = useParams<{ token: string }>();
  const [invoice, setInvoice] = useState<PublicInvoiceDetail | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getPublicInvoice(params.token)
      .then(setInvoice)
      .catch((err: unknown) => {
        setError(err instanceof ApiError ? err.message : "Failed to load this invoice.");
      });
  }, [params.token]);

  if (error) {
    return (
      <main className="mx-auto flex min-h-screen max-w-lg items-center justify-center p-6 text-center">
        <div>
          <h1 className="text-lg font-semibold">Invoice not found</h1>
          <p className="mt-1 text-sm text-muted-foreground">{error}</p>
        </div>
      </main>
    );
  }

  if (!invoice) {
    return (
      <main className="mx-auto max-w-2xl p-6">
        <p className="text-sm text-muted-foreground">Loading...</p>
      </main>
    );
  }

  const entryBySerial = new Map(invoice.meter_entries.map((entry) => [entry.id, entry.serial_number]));

  return (
    <main className="mx-auto max-w-2xl space-y-6 p-6 print:p-0">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-lg font-semibold">{invoice.shop_name || DEFAULT_SHOP_NAME}</h1>
          <p className="text-sm text-muted-foreground">Invoice receipt</p>
        </div>
        <Button type="button" variant="outline" size="sm" className="print:hidden" onClick={() => window.print()}>
          <Printer /> Print
        </Button>
      </div>

      <div className="rounded-lg border p-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div>
            <p className="text-base font-semibold">{invoice.invoice_no}</p>
            <p className="text-sm text-muted-foreground">{invoice.created_date}</p>
          </div>
          <InvoiceStatusBadge status={invoice.status} />
        </div>
        <div className="mt-3 border-t pt-3 text-sm">
          <p className="font-medium">{invoice.customer_name}</p>
          <p className="text-muted-foreground">{invoice.customer_phone}</p>
        </div>
      </div>

      {invoice.meter_entries.length > 0 && (
        <Section title="Meters">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Meter</TableHead>
                  <TableHead>Serial</TableHead>
                  <TableHead>KM</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoice.meter_entries.map((entry) => (
                  <TableRow key={entry.id}>
                    <TableCell className="font-medium">{entry.meter_title}</TableCell>
                    <TableCell>{entry.serial_number}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {entry.previous_km != null && entry.current_km != null
                        ? `${entry.previous_km} → ${entry.current_km}`
                        : "—"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </Section>
      )}

      {invoice.service_lines.length > 0 && (
        <Section title="Services">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Service</TableHead>
                  <TableHead>Meter</TableHead>
                  <TableHead className="text-right">Price</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoice.service_lines.map((line) => (
                  <TableRow key={line.id}>
                    <TableCell className="font-medium">{line.service_name}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {line.meter_entry ? `Serial ${entryBySerial.get(line.meter_entry) ?? line.meter_entry}` : "—"}
                    </TableCell>
                    <TableCell className="text-right">৳{line.price_charged}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </Section>
      )}

      {invoice.product_lines.length > 0 && (
        <Section title="Products">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Product</TableHead>
                  <TableHead className="text-right">Qty</TableHead>
                  <TableHead className="text-right">Price</TableHead>
                  <TableHead className="text-right">Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoice.product_lines.map((line) => (
                  <TableRow key={line.id}>
                    <TableCell className="font-medium">{line.product_name}</TableCell>
                    <TableCell className="text-right">{line.quantity}</TableCell>
                    <TableCell className="text-right">৳{line.price_charged}</TableCell>
                    <TableCell className="text-right">৳{line.line_total}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </Section>
      )}

      {invoice.payments.length > 0 && (
        <Section title="Payments">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Method</TableHead>
                  <TableHead className="text-right">Amount</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoice.payments.map((payment) => (
                  <TableRow key={payment.id}>
                    <TableCell className="text-muted-foreground">
                      {new Date(payment.payment_date).toLocaleDateString()}
                    </TableCell>
                    <TableCell className="text-muted-foreground">{payment.payment_method}</TableCell>
                    <TableCell className="text-right">৳{payment.amount}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </Section>
      )}

      <div className="rounded-lg border p-4">
        <dl className="space-y-2 text-sm">
          <div className="flex items-center justify-between">
            <dt className="text-muted-foreground">Subtotal</dt>
            <dd>৳{(Number(invoice.total_amount) + Number(invoice.discount_amount)).toFixed(2)}</dd>
          </div>
          {Number(invoice.discount_amount) > 0 && (
            <div className="flex items-center justify-between text-destructive">
              <dt>Discount{invoice.discount_note ? ` — ${invoice.discount_note}` : ""}</dt>
              <dd>−৳{invoice.discount_amount}</dd>
            </div>
          )}
          <div className="flex items-center justify-between border-t pt-2 text-base font-semibold">
            <dt>Total</dt>
            <dd>৳{invoice.total_amount}</dd>
          </div>
          <div className="flex items-center justify-between">
            <dt className="text-muted-foreground">Paid</dt>
            <dd>৳{invoice.paid_amount}</dd>
          </div>
          <div className="flex items-center justify-between border-t pt-2 text-base font-semibold">
            <dt>Due Amount</dt>
            <dd>৳{invoice.due_amount}</dd>
          </div>
        </dl>
      </div>

      <div className="space-y-1 text-center">
        <p className="text-xs text-muted-foreground">Thank you for your business.</p>
        <p className="text-xs text-muted-foreground">{invoice.invoice_footer_text || "Development by Wahed Nur"}</p>
      </div>
    </main>
  );
}
