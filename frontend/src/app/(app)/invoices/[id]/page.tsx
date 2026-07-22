"use client";

import { ArrowLeft, Ban, Gauge, Link2, Package, Plus, Receipt, Wrench } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

import { AddPaymentDialog } from "@/components/add-payment-dialog";
import { ApplyDiscountDialog } from "@/components/apply-discount-dialog";
import { EmptyState } from "@/components/empty-state";
import { InvoiceStatusBadge } from "@/components/invoice-status-badge";
import { ProductLineDialog } from "@/components/product-line-dialog";
import { RowActions } from "@/components/row-actions";
import { ServiceLineDialog } from "@/components/service-line-dialog";
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
import {
  deleteProductLine,
  deleteServiceLine,
  getInvoice,
  listAssets,
  listCustomers,
  listMeters,
  listMileageCorrectionDevices,
  listProducts,
  listServiceCategories,
  listServices,
} from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { reportError } from "@/lib/errors";
import type {
  Asset,
  Customer,
  InvoiceDetail,
  InvoiceProductLine,
  InvoiceServiceLine,
  MileageCorrectionDevice,
  Meter,
  ProductItem,
  ServiceCategory,
  ServiceItem,
} from "@/lib/types";

interface ReferenceData {
  customers: Customer[];
  meters: Meter[];
  devices: MileageCorrectionDevice[];
  services: ServiceItem[];
  categories: ServiceCategory[];
  products: ProductItem[];
  assets: Asset[];
}

function ErrorBanner({ message }: { message: string | null }) {
  if (!message) return null;
  return <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{message}</p>;
}

// --- read-only line item tables ---------------------------------------------------
//
// Meter entries are never added on their own anymore - a Mileage Correction
// service line creates its InvoiceMeterEntry inline (see ServiceLineDialog),
// so this table is read-only reference (e.g. to see each meter's paid_share).

function MetersTable({ invoice }: { invoice: InvoiceDetail }) {
  if (invoice.meter_entries.length === 0) {
    return <EmptyState icon={Gauge} title="No meters added yet" />;
  }

  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Meter</TableHead>
            <TableHead>Serial</TableHead>
            <TableHead>KM</TableHead>
            <TableHead>Device</TableHead>
            <TableHead className="text-right">Paid Share</TableHead>
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
              <TableCell className="text-muted-foreground">{entry.mileage_correction_device_name ?? "—"}</TableCell>
              <TableCell className="text-right">৳{entry.paid_share}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

function ServicesTable({
  invoice,
  isEditable,
  onEdit,
  onDeleted,
}: {
  invoice: InvoiceDetail;
  isEditable: boolean;
  onEdit: (line: InvoiceServiceLine) => void;
  onDeleted: () => void;
}) {
  if (invoice.service_lines.length === 0) {
    return <EmptyState icon={Wrench} title="No services added yet" />;
  }

  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Service</TableHead>
            <TableHead>Meter</TableHead>
            <TableHead>Asset Used</TableHead>
            <TableHead className="text-right">Price</TableHead>
            {isEditable && <TableHead className="w-12" />}
          </TableRow>
        </TableHeader>
        <TableBody>
          {invoice.service_lines.map((line) => {
            const entry = line.meter_entry_detail;
            return (
              <TableRow key={line.id}>
                <TableCell className="font-medium">{line.service_name}</TableCell>
                <TableCell className="text-muted-foreground">
                  {entry
                    ? `${entry.meter_title} (Serial ${entry.serial_number})${
                        entry.previous_km != null && entry.current_km != null
                          ? ` · ${entry.previous_km} → ${entry.current_km}`
                          : ""
                      }`
                    : "—"}
                </TableCell>
                <TableCell className="text-muted-foreground">{line.asset_used_name ?? "—"}</TableCell>
                <TableCell className="text-right">৳{line.price_charged}</TableCell>
                {isEditable && (
                  <TableCell>
                    <RowActions
                      resourceLabel="Service"
                      onEdit={() => onEdit(line)}
                      onDelete={() => deleteServiceLine(invoice.id, line.id).then(onDeleted)}
                      deleteDescription={
                        entry
                          ? "This will also remove the linked meter entry if no other service line uses it."
                          : undefined
                      }
                    />
                  </TableCell>
                )}
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </div>
  );
}

function ProductsTable({
  invoice,
  isEditable,
  onEdit,
  onDeleted,
}: {
  invoice: InvoiceDetail;
  isEditable: boolean;
  onEdit: (line: InvoiceProductLine) => void;
  onDeleted: () => void;
}) {
  if (invoice.product_lines.length === 0) {
    return <EmptyState icon={Package} title="No products added yet" />;
  }

  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Product</TableHead>
            <TableHead className="text-right">Qty</TableHead>
            <TableHead className="text-right">Price</TableHead>
            <TableHead className="text-right">Total</TableHead>
            {isEditable && <TableHead className="w-12" />}
          </TableRow>
        </TableHeader>
        <TableBody>
          {invoice.product_lines.map((line) => (
            <TableRow key={line.id}>
              <TableCell className="font-medium">{line.product_name}</TableCell>
              <TableCell className="text-right">{line.quantity}</TableCell>
              <TableCell className="text-right">৳{line.price_charged}</TableCell>
              <TableCell className="text-right">৳{line.line_total}</TableCell>
              {isEditable && (
                <TableCell>
                  <RowActions
                    resourceLabel="Product"
                    onEdit={() => onEdit(line)}
                    onDelete={() => deleteProductLine(invoice.id, line.id).then(onDeleted)}
                  />
                </TableCell>
              )}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

function PaymentsTable({ invoice }: { invoice: InvoiceDetail }) {
  if (invoice.payments.length === 0) {
    return <EmptyState icon={Receipt} title="No payments recorded yet" />;
  }

  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Date</TableHead>
            <TableHead>Method</TableHead>
            <TableHead>Note</TableHead>
            <TableHead className="text-right">Amount</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {invoice.payments.map((payment) => (
            <TableRow key={payment.id}>
              <TableCell className="text-muted-foreground">
                {new Date(payment.payment_date).toLocaleString()}
              </TableCell>
              <TableCell>
                <Badge variant="outline">{payment.payment_method}</Badge>
              </TableCell>
              <TableCell className="text-muted-foreground">{payment.note || "—"}</TableCell>
              <TableCell className="text-right">৳{payment.amount}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

// --- page ---------------------------------------------------------------------------

function InvoiceSummaryCard({
  invoice,
  isEditable,
  isAdmin,
  onDiscountApplied,
}: {
  invoice: InvoiceDetail;
  isEditable: boolean;
  isAdmin: boolean;
  onDiscountApplied: () => void;
}) {
  const discountAmount = Number(invoice.discount_amount);
  const hasDiscount = discountAmount > 0;
  // Gross work total (services + products), before discount - the server
  // computes total_amount = subtotal - discount_amount, so this is exact.
  const subtotal = Number(invoice.total_amount) + discountAmount;
  const isPaidInFull = invoice.status === "PAID" || Number(invoice.due_amount) <= 0;

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between gap-2 space-y-0">
        <CardTitle className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
          Invoice Summary
        </CardTitle>
        {isAdmin && isEditable && (
          <ApplyDiscountDialog
            invoice={invoice}
            trigger={
              <Button type="button" variant="outline" size="sm">
                {hasDiscount ? "Edit Discount" : "Apply Discount"}
              </Button>
            }
            onApplied={onDiscountApplied}
          />
        )}
      </CardHeader>
      <CardContent>
        <dl className="space-y-2 text-sm">
          <div className="flex items-center justify-between">
            <dt className="text-muted-foreground">Subtotal</dt>
            <dd>৳{subtotal.toFixed(2)}</dd>
          </div>
          {hasDiscount && (
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
            <dt>Due</dt>
            {isPaidInFull ? (
              <dd className="flex items-center gap-2">
                ৳0.00
                <Badge className="border-transparent bg-green-500/10 text-green-600 dark:bg-green-500/20 dark:text-green-400">
                  Paid in full
                </Badge>
              </dd>
            ) : (
              <dd className="text-destructive">৳{invoice.due_amount}</dd>
            )}
          </div>
        </dl>
      </CardContent>
    </Card>
  );
}

function InvoiceDetailContent() {
  const params = useParams<{ id: string }>();
  const invoiceId = Number(params.id);
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";

  const [invoice, setInvoice] = useState<InvoiceDetail | null>(null);
  const [referenceData, setReferenceData] = useState<ReferenceData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [editingServiceLine, setEditingServiceLine] = useState<InvoiceServiceLine | null>(null);
  const [editingProductLine, setEditingProductLine] = useState<InvoiceProductLine | null>(null);

  const loadInvoice = useCallback(() => {
    return getInvoice(invoiceId)
      .then(setInvoice)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this invoice."));
      });
  }, [invoiceId]);

  useEffect(() => {
    loadInvoice();
  }, [loadInvoice]);

  useEffect(() => {
    Promise.all([
      listCustomers(),
      listMeters(),
      listMileageCorrectionDevices(),
      listServices(),
      listServiceCategories(),
      listProducts(),
      listAssets(),
    ])
      .then(([customers, meters, devices, services, categories, products, assets]) => {
        setReferenceData({ customers, meters, devices, services, categories, products, assets });
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load reference data."));
      });
  }, []);

  async function handleCopyLink() {
    if (!invoice) return;
    const url = `${window.location.origin}/invoice/${invoice.public_share_token}`;
    try {
      await navigator.clipboard.writeText(url);
      toast.success("Public link copied to clipboard.");
    } catch {
      toast.error("Couldn't copy the link — copy it manually.");
    }
  }

  if (error) return <ErrorBanner message={error} />;
  if (!invoice || !referenceData) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  const customer = referenceData.customers.find((item) => item.id === invoice.customer);
  const isEditable = invoice.status === "UNPAID" || invoice.status === "PARTIAL";

  return (
    <div className="space-y-6">
      <Link href="/invoices" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to invoices
      </Link>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-semibold">{invoice.invoice_no}</h1>
            <InvoiceStatusBadge status={invoice.status} />
          </div>
          <p className="text-sm text-muted-foreground">
            {customer ? (
              <Link href={`/customers/${customer.id}`} className="hover:underline">
                {customer.name}
              </Link>
            ) : (
              invoice.customer_name
            )}
            {customer?.is_red_listed && (
              <Badge variant="destructive" className="ml-2">
                Red-listed
              </Badge>
            )}
            <span className="mx-2">·</span>
            {invoice.created_date}
          </p>
        </div>
        <div className="flex gap-2">
          <Button type="button" variant="outline" size="sm" onClick={handleCopyLink}>
            <Link2 /> Copy Public Link
          </Button>
          {invoice.status === "CANCELLED" && (
            <Badge variant="secondary">
              <Ban className="mr-1 h-3 w-3" /> Cancelled
            </Badge>
          )}
        </div>
      </div>

      <InvoiceSummaryCard
        invoice={invoice}
        isEditable={isEditable}
        isAdmin={isAdmin}
        onDiscountApplied={loadInvoice}
      />

      <div className="space-y-6">
        {invoice.meter_entries.length > 0 && (
          <section>
            <h2 className="mb-2 text-sm font-semibold">Meters</h2>
            <MetersTable invoice={invoice} />
          </section>
        )}
        <section>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-sm font-semibold">Services</h2>
            {isEditable && (
              <ServiceLineDialog
                invoice={invoice}
                services={referenceData.services}
                categories={referenceData.categories}
                meters={referenceData.meters}
                devices={referenceData.devices}
                assets={referenceData.assets}
                trigger={
                  <Button type="button" size="sm">
                    <Plus /> Add Service
                  </Button>
                }
                onSaved={loadInvoice}
              />
            )}
          </div>
          <ServicesTable
            invoice={invoice}
            isEditable={isEditable}
            onEdit={setEditingServiceLine}
            onDeleted={loadInvoice}
          />
        </section>
        <section>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-sm font-semibold">Products</h2>
            {isEditable && (
              <ProductLineDialog
                invoiceId={invoice.id}
                products={referenceData.products}
                trigger={
                  <Button type="button" size="sm">
                    <Plus /> Add Product
                  </Button>
                }
                onSaved={loadInvoice}
              />
            )}
          </div>
          <ProductsTable
            invoice={invoice}
            isEditable={isEditable}
            onEdit={setEditingProductLine}
            onDeleted={loadInvoice}
          />
        </section>
        <section>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-sm font-semibold">Payments</h2>
            {isEditable && Number(invoice.due_amount) > 0 && (
              <AddPaymentDialog
                invoice={invoice}
                trigger={
                  <Button type="button" size="sm">
                    Add Payment
                  </Button>
                }
                onPaid={loadInvoice}
              />
            )}
          </div>
          <PaymentsTable invoice={invoice} />
        </section>
      </div>

      <ServiceLineDialog
        invoice={invoice}
        services={referenceData.services}
        categories={referenceData.categories}
        meters={referenceData.meters}
        devices={referenceData.devices}
        assets={referenceData.assets}
        serviceLine={editingServiceLine ?? undefined}
        open={editingServiceLine !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingServiceLine(null);
        }}
        onSaved={loadInvoice}
      />
      <ProductLineDialog
        invoiceId={invoice.id}
        products={referenceData.products}
        productLine={editingProductLine ?? undefined}
        open={editingProductLine !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingProductLine(null);
        }}
        onSaved={loadInvoice}
      />
    </div>
  );
}

export default function InvoiceDetailPage() {
  return <InvoiceDetailContent />;
}
