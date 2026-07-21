"use client";

import { useEffect, useMemo, useState } from "react";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  addMeterEntry,
  addProductLine,
  addServiceLine,
  ApiError,
  getInvoice,
  listCustomers,
  listMeters,
  listMileageCorrectionDevices,
  listProducts,
  listServices,
  startInvoice,
} from "@/lib/api";
import type {
  Customer,
  InvoiceDetail,
  MileageCorrectionDevice,
  Meter,
  ProductItem,
  ServiceItem,
} from "@/lib/types";

interface ReferenceData {
  customers: Customer[];
  meters: Meter[];
  devices: MileageCorrectionDevice[];
  services: ServiceItem[];
  products: ProductItem[];
}

function ErrorBanner({ message }: { message: string | null }) {
  if (!message) return null;
  return <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{message}</p>;
}

function statusBadgeVariant(status: InvoiceDetail["status"]): "default" | "secondary" | "destructive" | "outline" {
  switch (status) {
    case "PAID":
      return "default";
    case "PARTIAL":
      return "secondary";
    case "CANCELLED":
      return "outline";
    default:
      return "destructive"; // UNPAID
  }
}

// --- start / resume invoice -----------------------------------------------------

function StartInvoiceCard({
  customers,
  onStarted,
}: {
  customers: Customer[];
  onStarted: (invoice: InvoiceDetail) => void;
}) {
  const [customerId, setCustomerId] = useState<number | null>(null);
  const [isStarting, setIsStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const options: ComboboxOption[] = customers.map((customer) => ({
    value: customer.id,
    label: customer.name,
    description: customer.phone + (customer.is_red_listed ? " · red-listed" : ""),
  }));

  async function handleStart() {
    if (!customerId) return;
    setError(null);
    setIsStarting(true);
    try {
      const invoice = await startInvoice(customerId);
      onStarted(invoice);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to start the invoice.");
    } finally {
      setIsStarting(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Start a visit</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2">
        <div className="flex items-end gap-3">
          <div className="flex-1 space-y-2">
            <Label>
              Customer <span className="text-destructive">*</span>
            </Label>
            <Combobox
              options={options}
              value={customerId}
              onChange={setCustomerId}
              placeholder="Search customers..."
              searchPlaceholder="Search customers..."
            />
          </div>
          <Button type="button" disabled={!customerId || isStarting} onClick={handleStart}>
            {isStarting ? "Starting..." : "Start / Resume Invoice"}
          </Button>
        </div>
        <p className="text-xs text-muted-foreground">
          If this customer already has an unpaid or partially paid invoice, it will be reused instead of
          creating a new one.
        </p>
        <ErrorBanner message={error} />
      </CardContent>
    </Card>
  );
}

// --- add meter entry ---------------------------------------------------------------

function AddMeterEntryForm({
  invoice,
  meters,
  devices,
  onAdded,
}: {
  invoice: InvoiceDetail;
  meters: Meter[];
  devices: MileageCorrectionDevice[];
  onAdded: () => void;
}) {
  const [meterId, setMeterId] = useState<number | null>(null);
  const [serialNumber, setSerialNumber] = useState("");
  const [conditionNote, setConditionNote] = useState("");
  const [previousKm, setPreviousKm] = useState("");
  const [currentKm, setCurrentKm] = useState("");
  const [deviceId, setDeviceId] = useState<number | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const meterOptions: ComboboxOption[] = meters.map((meter) => ({
    value: meter.id,
    label: meter.title,
    description: meter.memory_type,
  }));

  const selectedMeter = meters.find((meter) => meter.id === meterId) ?? null;

  // Business rule (Phase 3): MCU meters only take VVDI Prog, EEPROM meters
  // take the rest - filter the device dropdown to what's actually valid so
  // this is obvious before the backend has to reject it.
  const deviceOptions: ComboboxOption[] = useMemo(() => {
    const compatible = selectedMeter
      ? devices.filter(
          (device) => device.memory_type_support === "BOTH" || device.memory_type_support === selectedMeter.memory_type,
        )
      : devices;
    return compatible.map((device) => ({ value: device.id, label: device.name }));
  }, [devices, selectedMeter]);

  function resetForm() {
    setMeterId(null);
    setSerialNumber("");
    setConditionNote("");
    setPreviousKm("");
    setCurrentKm("");
    setDeviceId(null);
  }

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!meterId || !serialNumber.trim()) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await addMeterEntry(invoice.id, {
        meter: meterId,
        serial_number: serialNumber.trim(),
        condition_note: conditionNote.trim() || undefined,
        previous_km: previousKm ? Number(previousKm) : null,
        current_km: currentKm ? Number(currentKm) : null,
        mileage_correction_device: deviceId,
      });
      resetForm();
      onAdded();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to add the meter.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Add a meter</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Meter <span className="text-destructive">*</span>
            </Label>
            <Combobox
              options={meterOptions}
              value={meterId}
              onChange={(value) => {
                setMeterId(value);
                setDeviceId(null);
              }}
              placeholder="Search meters..."
              searchPlaceholder="Search meters..."
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="serial-number">
              Serial number <span className="text-destructive">*</span>
            </Label>
            <Input
              id="serial-number"
              type="text"
              required
              value={serialNumber}
              onChange={(event) => setSerialNumber(event.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="condition-note">Condition note</Label>
            <Input
              id="condition-note"
              type="text"
              value={conditionNote}
              onChange={(event) => setConditionNote(event.target.value)}
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="previous-km">Previous KM</Label>
              <Input
                id="previous-km"
                type="number"
                min={0}
                value={previousKm}
                onChange={(event) => setPreviousKm(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="current-km">Current KM</Label>
              <Input
                id="current-km"
                type="number"
                min={0}
                value={currentKm}
                onChange={(event) => setCurrentKm(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Mileage correction device</Label>
            <Combobox
              options={deviceOptions}
              value={deviceId}
              onChange={setDeviceId}
              allowClear
              placeholder={selectedMeter ? "Only for mileage correction" : "Pick a meter first"}
              disabled={!selectedMeter}
              emptyMessage="No compatible device"
              searchPlaceholder="Search devices..."
            />
          </div>
          <p className="text-xs text-muted-foreground">
            Previous/current KM and a condition note are required if you&apos;ll add a Mileage Correction
            service against this meter.
          </p>
          <ErrorBanner message={error} />
          <Button type="submit" disabled={!meterId || !serialNumber.trim() || isSubmitting} className="w-full">
            {isSubmitting ? "Adding..." : "Add meter"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

// --- add service line -----------------------------------------------------------

function AddServiceLineForm({
  invoice,
  services,
  onAdded,
}: {
  invoice: InvoiceDetail;
  services: ServiceItem[];
  onAdded: () => void;
}) {
  const [serviceId, setServiceId] = useState<number | null>(null);
  const [meterEntryId, setMeterEntryId] = useState<number | null>(null);
  const [priceOverride, setPriceOverride] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const serviceOptions: ComboboxOption[] = services.map((service) => ({
    value: service.id,
    label: service.name,
    description: `${service.category_name} · ৳${service.service_price}`,
  }));

  const meterEntryOptions: ComboboxOption[] = invoice.meter_entries.map((entry) => ({
    value: entry.id,
    label: `Serial ${entry.serial_number}`,
  }));

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    if (!serviceId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await addServiceLine(invoice.id, {
        service: serviceId,
        meter_entry: meterEntryId,
        price_charged: priceOverride ? Number(priceOverride) : null,
      });
      setServiceId(null);
      setMeterEntryId(null);
      setPriceOverride("");
      onAdded();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to add the service.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Add a service</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Service <span className="text-destructive">*</span>
            </Label>
            <Combobox
              options={serviceOptions}
              value={serviceId}
              onChange={setServiceId}
              placeholder="Search services..."
              searchPlaceholder="Search services..."
            />
          </div>
          <div className="space-y-2">
            <Label>For which meter?</Label>
            <Combobox
              options={meterEntryOptions}
              value={meterEntryId}
              onChange={setMeterEntryId}
              allowClear
              placeholder={meterEntryOptions.length ? "Optional" : "No meters added yet"}
              disabled={meterEntryOptions.length === 0}
              emptyMessage="No meters on this invoice yet"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="service-price-override">Price override</Label>
            <Input
              id="service-price-override"
              type="number"
              min={0}
              step="0.01"
              placeholder="Leave blank to use the service's default price"
              value={priceOverride}
              onChange={(event) => setPriceOverride(event.target.value)}
            />
          </div>
          <ErrorBanner message={error} />
          <Button type="submit" disabled={!serviceId || isSubmitting} className="w-full">
            {isSubmitting ? "Adding..." : "Add service"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

// --- add product line -----------------------------------------------------------

function AddProductLineForm({
  invoice,
  products,
  onAdded,
}: {
  invoice: InvoiceDetail;
  products: ProductItem[];
  onAdded: () => void;
}) {
  const [productId, setProductId] = useState<number | null>(null);
  const [quantity, setQuantity] = useState("1");
  const [priceOverride, setPriceOverride] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const productOptions: ComboboxOption[] = products.map((product) => ({
    value: product.id,
    label: product.name,
    description: `${product.sku} · ${product.current_stock_quantity} in stock`,
  }));

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    const parsedQuantity = Number(quantity);
    if (!productId || !parsedQuantity || parsedQuantity < 1) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await addProductLine(invoice.id, {
        product: productId,
        quantity: parsedQuantity,
        price_charged: priceOverride ? Number(priceOverride) : null,
      });
      setProductId(null);
      setQuantity("1");
      setPriceOverride("");
      onAdded();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to add the product.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Add a product</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Product <span className="text-destructive">*</span>
            </Label>
            <Combobox
              options={productOptions}
              value={productId}
              onChange={setProductId}
              placeholder="Search products..."
              searchPlaceholder="Search products..."
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="quantity">
                Quantity <span className="text-destructive">*</span>
              </Label>
              <Input
                id="quantity"
                type="number"
                min={1}
                required
                value={quantity}
                onChange={(event) => setQuantity(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="product-price-override">Price override</Label>
              <Input
                id="product-price-override"
                type="number"
                min={0}
                step="0.01"
                placeholder="Default sale price"
                value={priceOverride}
                onChange={(event) => setPriceOverride(event.target.value)}
              />
            </div>
          </div>
          <ErrorBanner message={error} />
          <Button type="submit" disabled={!productId || isSubmitting} className="w-full">
            {isSubmitting ? "Adding..." : "Add product"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

// --- invoice summary -------------------------------------------------------------

function InvoiceSummary({
  invoice,
  meters,
  services,
  products,
}: {
  invoice: InvoiceDetail;
  meters: Meter[];
  services: ServiceItem[];
  products: ProductItem[];
}) {
  const meterById = new Map(meters.map((meter) => [meter.id, meter]));
  const serviceById = new Map(services.map((service) => [service.id, service]));
  const productById = new Map(products.map((product) => [product.id, product]));

  return (
    <Card>
      <CardHeader className="flex items-center justify-between">
        <div>
          <CardTitle>{invoice.invoice_no}</CardTitle>
          <p className="text-xs text-muted-foreground">Created {invoice.created_date}</p>
        </div>
        <Badge variant={statusBadgeVariant(invoice.status)}>{invoice.status}</Badge>
      </CardHeader>
      <CardContent>
        <dl className="grid grid-cols-3 gap-3 text-sm">
          <div>
            <dt className="text-xs text-muted-foreground">Total</dt>
            <dd className="font-medium">৳{invoice.total_amount}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Paid</dt>
            <dd className="font-medium">৳{invoice.paid_amount}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Outstanding</dt>
            <dd className="font-medium">৳{invoice.outstanding_amount}</dd>
          </div>
        </dl>

        {invoice.meter_entries.length > 0 && (
          <div className="mt-4">
            <h3 className="mb-1 text-xs font-semibold text-muted-foreground uppercase">Meters</h3>
            <ul className="divide-y text-sm">
              {invoice.meter_entries.map((entry) => (
                <li key={entry.id} className="py-1.5">
                  {meterById.get(entry.meter)?.title ?? `Meter #${entry.meter}`} — serial {entry.serial_number}
                </li>
              ))}
            </ul>
          </div>
        )}

        {invoice.service_lines.length > 0 && (
          <div className="mt-4">
            <h3 className="mb-1 text-xs font-semibold text-muted-foreground uppercase">Services</h3>
            <ul className="divide-y text-sm">
              {invoice.service_lines.map((line) => (
                <li key={line.id} className="flex justify-between py-1.5">
                  <span>{serviceById.get(line.service)?.name ?? `Service #${line.service}`}</span>
                  <span className="text-muted-foreground">৳{line.price_charged}</span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {invoice.product_lines.length > 0 && (
          <div className="mt-4">
            <h3 className="mb-1 text-xs font-semibold text-muted-foreground uppercase">Products</h3>
            <ul className="divide-y text-sm">
              {invoice.product_lines.map((line) => (
                <li key={line.id} className="flex justify-between py-1.5">
                  <span>
                    {line.quantity} x {productById.get(line.product)?.name ?? `Product #${line.product}`}
                  </span>
                  <span className="text-muted-foreground">৳{line.line_total}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// --- page ---------------------------------------------------------------------------

function InvoiceCreationContent() {
  const [referenceData, setReferenceData] = useState<ReferenceData | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [invoice, setInvoice] = useState<InvoiceDetail | null>(null);

  useEffect(() => {
    let isMounted = true;
    Promise.all([listCustomers(), listMeters(), listMileageCorrectionDevices(), listServices(), listProducts()])
      .then(([customers, meters, devices, services, products]) => {
        if (isMounted) setReferenceData({ customers, meters, devices, services, products });
      })
      .catch((err: unknown) => {
        if (!isMounted) return;
        setLoadError(err instanceof ApiError ? err.message : "Failed to load reference data.");
      });
    return () => {
      isMounted = false;
    };
  }, []);

  async function refreshInvoice(invoiceId: number) {
    const fresh = await getInvoice(invoiceId);
    setInvoice(fresh);
  }

  if (loadError) return <ErrorBanner message={loadError} />;
  if (!referenceData) return <p className="text-sm text-muted-foreground">Loading...</p>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">New Invoice</h1>
        <p className="text-sm text-muted-foreground">
          Start a visit, then add meters, services, and products as you go.
        </p>
      </div>

      <StartInvoiceCard customers={referenceData.customers} onStarted={setInvoice} />

      {invoice && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div className="space-y-6">
            <AddMeterEntryForm
              invoice={invoice}
              meters={referenceData.meters}
              devices={referenceData.devices}
              onAdded={() => refreshInvoice(invoice.id)}
            />
            <AddServiceLineForm
              invoice={invoice}
              services={referenceData.services}
              onAdded={() => refreshInvoice(invoice.id)}
            />
            <AddProductLineForm
              invoice={invoice}
              products={referenceData.products}
              onAdded={() => refreshInvoice(invoice.id)}
            />
          </div>
          <div>
            <InvoiceSummary
              invoice={invoice}
              meters={referenceData.meters}
              services={referenceData.services}
              products={referenceData.products}
            />
          </div>
        </div>
      )}
    </div>
  );
}

export default function NewInvoicePage() {
  return <InvoiceCreationContent />;
}
