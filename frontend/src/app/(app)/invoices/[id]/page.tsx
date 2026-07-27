"use client";

import { AlertTriangle, ArrowLeft, Ban, Link2, Lock, Package, Plus, Receipt, Wrench } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

import { AddPaymentDialog } from "@/components/add-payment-dialog";
import { ApplyDiscountDialog } from "@/components/apply-discount-dialog";
import { ConditionNoteBadges } from "@/components/condition-note-badges";
import { DatePickerButton } from "@/components/date-picker-button";
import { EditPaidInvoiceDialog } from "@/components/edit-paid-invoice-dialog";
import { EmptyState } from "@/components/empty-state";
import { ForceCloseInvoiceDialog } from "@/components/force-close-invoice-dialog";
import { InvoiceStatusBadge } from "@/components/invoice-status-badge";
import { LineDateCell } from "@/components/line-date-cell";
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
  ApiError,
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
  updateInvoiceCreatedDate,
  updateProductLine,
  updateServiceLine,
} from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { reportError } from "@/lib/errors";
import { cleanInvoiceErrorMessage } from "@/lib/invoice-utils";
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

/** Meter identity + KM + condition, combined into one cell - this is the
 * only place a mileage-correction line's meter shows up anywhere (rule 1):
 * no separate meter table/section exists internally or on the public view. */
function MeterCell({ entry }: { entry: InvoiceServiceLine["meter_entry_detail"] }) {
  if (!entry) return <span className="text-muted-foreground">—</span>;
  return (
    <div className="text-sm">
      <p className="font-medium">
        {entry.meter_brand} {entry.meter_model} ({entry.meter_cc}cc)
      </p>
      <p className="text-muted-foreground">
        Serial {entry.serial_number ?? "—"}
        {entry.previous_km != null && entry.current_km != null && ` · ${entry.previous_km} → ${entry.current_km} km`}
      </p>
      <div className="mt-1">
        <ConditionNoteBadges conditions={entry.condition_note} />
      </div>
    </div>
  );
}

function ServicesTable({
  invoice,
  canEdit,
  reason,
  onEdit,
  onReplace,
  onDeleted,
}: {
  invoice: InvoiceDetail;
  canEdit: boolean;
  reason?: string;
  onEdit: (line: InvoiceServiceLine) => void;
  onReplace: (line: InvoiceServiceLine) => void;
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
            <TableHead>Product Used</TableHead>
            <TableHead>Date</TableHead>
            <TableHead className="text-right">Charge</TableHead>
            <TableHead className="text-right">Product ৳</TableHead>
            <TableHead className="text-right">Total</TableHead>
            {canEdit && <TableHead className="w-12" />}
          </TableRow>
        </TableHeader>
        <TableBody>
          {invoice.service_lines.map((line) => (
            <TableRow key={line.id}>
              <TableCell className="font-medium">
                {line.service_name}
                {line.asset_used_name && <p className="text-xs font-normal text-muted-foreground">Tool: {line.asset_used_name}</p>}
              </TableCell>
              <TableCell>
                <MeterCell entry={line.meter_entry_detail} />
              </TableCell>
              <TableCell className="text-muted-foreground">{line.product_used_name ?? "—"}</TableCell>
              <TableCell>
                <LineDateCell
                  value={line.added_date}
                  disabled={!canEdit}
                  onChange={(added_date) => updateServiceLine(invoice.id, line.id, { added_date, reason }).then(onDeleted)}
                />
              </TableCell>
              <TableCell className="text-right">৳{line.price_charged}</TableCell>
              <TableCell className="text-right text-muted-foreground">
                {Number(line.product_price) > 0 ? `৳${line.product_price}` : "—"}
              </TableCell>
              <TableCell className="text-right font-medium">৳{line.line_total}</TableCell>
              {canEdit && (
                <TableCell>
                  <RowActions
                    resourceLabel="Service"
                    onEdit={() => onEdit(line)}
                    onReplace={() => onReplace(line)}
                    onDelete={() => deleteServiceLine(invoice.id, line.id, { reason }).then(onDeleted)}
                    deleteDescription={
                      line.meter_entry_detail
                        ? "This will also remove the linked meter entry if no other service line uses it."
                        : undefined
                    }
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

function ProductsTable({
  invoice,
  canEdit,
  reason,
  onEdit,
  onReplace,
  onDeleted,
}: {
  invoice: InvoiceDetail;
  canEdit: boolean;
  reason?: string;
  onEdit: (line: InvoiceProductLine) => void;
  onReplace: (line: InvoiceProductLine) => void;
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
            <TableHead>Date</TableHead>
            <TableHead className="text-right">Qty</TableHead>
            <TableHead className="text-right">Price</TableHead>
            <TableHead className="text-right">Total</TableHead>
            {canEdit && <TableHead className="w-12" />}
          </TableRow>
        </TableHeader>
        <TableBody>
          {invoice.product_lines.map((line) => (
            <TableRow key={line.id}>
              <TableCell className="font-medium">{line.product_name}</TableCell>
              <TableCell>
                <LineDateCell
                  value={line.added_date}
                  disabled={!canEdit}
                  onChange={(added_date) => updateProductLine(invoice.id, line.id, { added_date, reason }).then(onDeleted)}
                />
              </TableCell>
              <TableCell className="text-right">{line.quantity}</TableCell>
              <TableCell className="text-right">৳{line.price_charged}</TableCell>
              <TableCell className="text-right font-medium">৳{line.line_total}</TableCell>
              {canEdit && (
                <TableCell>
                  <RowActions
                    resourceLabel="Product"
                    onEdit={() => onEdit(line)}
                    onReplace={() => onReplace(line)}
                    onDelete={() => deleteProductLine(invoice.id, line.id, { reason }).then(onDeleted)}
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
  onClosed,
}: {
  invoice: InvoiceDetail;
  isEditable: boolean;
  isAdmin: boolean;
  onDiscountApplied: () => void;
  onClosed: () => void;
}) {
  const discountAmount = Number(invoice.discount_amount);
  const waivedAmount = Number(invoice.waived_amount);
  const hasDiscount = discountAmount > 0;
  const hasWaived = waivedAmount > 0;
  // Gross work total (services + products), before discount/waived - the
  // server computes total_amount = subtotal - discount_amount - waived_amount.
  const subtotal = Number(invoice.total_amount) + discountAmount + waivedAmount;
  const isPaidInFull = invoice.status === "PAID" || Number(invoice.due_amount) <= 0;
  const dueAmount = Number(invoice.due_amount);

  return (
    <Card>
      <CardHeader className="flex flex-row flex-wrap items-center justify-between gap-2 space-y-0">
        <CardTitle className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
          Invoice Summary
        </CardTitle>
        <div className="flex gap-2">
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
          {isAdmin && isEditable && dueAmount > 0 && (
            <ForceCloseInvoiceDialog
              invoice={invoice}
              trigger={
                <Button type="button" variant="destructive" size="sm">
                  Mark as Paid (Force Close)
                </Button>
              }
              onClosed={onClosed}
            />
          )}
        </div>
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
          {hasWaived && (
            <div className="flex items-center justify-between rounded-md bg-amber-500/10 px-2 py-1 text-amber-700 dark:text-amber-400">
              <dt className="font-medium">
                Waived{invoice.waived_note ? ` — ${invoice.waived_note}` : ""}
              </dt>
              <dd className="font-medium">−৳{invoice.waived_amount}</dd>
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
  const [replacingServiceLine, setReplacingServiceLine] = useState<InvoiceServiceLine | null>(null);
  const [editingProductLine, setEditingProductLine] = useState<InvoiceProductLine | null>(null);
  const [replacingProductLine, setReplacingProductLine] = useState<InvoiceProductLine | null>(null);
  // Set only after an Admin confirms a reason via EditPaidInvoiceDialog -
  // unlocks editing on an otherwise-locked Paid/force-closed invoice for
  // the rest of this page session (rule 14). Cleared on "Done editing" or
  // on navigating away (fresh state each time the page mounts).
  const [editingPaidReason, setEditingPaidReason] = useState<string | null>(null);

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

  async function handleCreatedDateChange(nextDate: string | undefined) {
    if (!invoice || !nextDate || nextDate === invoice.created_date) return;
    try {
      await updateInvoiceCreatedDate(invoice.id, {
        created_date: nextDate,
        ...(editingPaidReason && { reason: editingPaidReason }),
      });
      toast.success("Invoice date updated.");
      loadInvoice();
    } catch (err) {
      toast.error(err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to update the date.");
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
  const isLockedButUnlockable = isAdmin && !isEditable && invoice.status === "PAID";
  const canEditLines = isEditable || editingPaidReason !== null;
  const canEditDate = isAdmin && canEditLines;

  return (
    <div className="space-y-6">
      <Link href="/invoices" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to invoices
      </Link>

      {/* Customer + invoice identity - shown exactly once, at the top. */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="text-xl font-semibold">{invoice.invoice_no}</h1>
            <InvoiceStatusBadge status={invoice.status} />
            {invoice.status === "CANCELLED" && (
              <Badge variant="secondary">
                <Ban className="mr-1 h-3 w-3" /> Cancelled
              </Badge>
            )}
          </div>
          <p className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
            {customer ? (
              <Link href={`/customers/${customer.id}`} className="hover:underline">
                {customer.name}
              </Link>
            ) : (
              invoice.customer_name
            )}
            {customer?.is_red_listed && <Badge variant="destructive">Red-listed</Badge>}
            <span>·</span>
            {canEditDate ? (
              <DatePickerButton value={invoice.created_date} onChange={handleCreatedDateChange} size="sm" />
            ) : (
              invoice.created_date
            )}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Button type="button" variant="outline" size="sm" onClick={handleCopyLink}>
            <Link2 /> Copy Public Link
          </Button>
          {isLockedButUnlockable && editingPaidReason === null && (
            <EditPaidInvoiceDialog
              trigger={
                <Button type="button" variant="outline" size="sm">
                  <Lock /> Edit Paid Invoice
                </Button>
              }
              onUnlocked={setEditingPaidReason}
            />
          )}
        </div>
      </div>

      {editingPaidReason !== null && (
        <div className="flex flex-wrap items-center justify-between gap-2 rounded-md border border-amber-500/40 bg-amber-500/10 px-3 py-2 text-sm text-amber-800 dark:text-amber-300">
          <span className="flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 shrink-0" />
            Editing unlocked on this normally-locked Paid invoice. Reason: {editingPaidReason}
          </span>
          <Button type="button" variant="outline" size="sm" onClick={() => setEditingPaidReason(null)}>
            Done editing
          </Button>
        </div>
      )}

      <InvoiceSummaryCard
        invoice={invoice}
        isEditable={isEditable}
        isAdmin={isAdmin}
        onDiscountApplied={loadInvoice}
        onClosed={loadInvoice}
      />

      <div className="space-y-6">
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
                products={referenceData.products}
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
            canEdit={canEditLines}
            reason={editingPaidReason ?? undefined}
            onEdit={setEditingServiceLine}
            onReplace={setReplacingServiceLine}
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
            canEdit={canEditLines}
            reason={editingPaidReason ?? undefined}
            onEdit={setEditingProductLine}
            onReplace={setReplacingProductLine}
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
        products={referenceData.products}
        assets={referenceData.assets}
        serviceLine={editingServiceLine ?? undefined}
        reason={editingPaidReason ?? undefined}
        open={editingServiceLine !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingServiceLine(null);
        }}
        onSaved={loadInvoice}
      />
      <ServiceLineDialog
        invoice={invoice}
        services={referenceData.services}
        categories={referenceData.categories}
        meters={referenceData.meters}
        devices={referenceData.devices}
        products={referenceData.products}
        assets={referenceData.assets}
        serviceLine={replacingServiceLine ?? undefined}
        allowReplace
        reason={editingPaidReason ?? undefined}
        open={replacingServiceLine !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setReplacingServiceLine(null);
        }}
        onSaved={loadInvoice}
      />
      <ProductLineDialog
        invoiceId={invoice.id}
        products={referenceData.products}
        productLine={editingProductLine ?? undefined}
        reason={editingPaidReason ?? undefined}
        open={editingProductLine !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingProductLine(null);
        }}
        onSaved={loadInvoice}
      />
      <ProductLineDialog
        invoiceId={invoice.id}
        products={referenceData.products}
        productLine={replacingProductLine ?? undefined}
        allowReplace
        reason={editingPaidReason ?? undefined}
        open={replacingProductLine !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setReplacingProductLine(null);
        }}
        onSaved={loadInvoice}
      />
    </div>
  );
}

export default function InvoiceDetailPage() {
  return <InvoiceDetailContent />;
}
