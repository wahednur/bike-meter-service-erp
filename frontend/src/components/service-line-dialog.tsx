"use client";

import { useEffect, useMemo, useState, type FormEvent, type ReactNode } from "react";
import { toast } from "sonner";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { addServiceLine, ApiError, updateServiceLine } from "@/lib/api";
import { cleanInvoiceErrorMessage, compatibleCorrectionDevices } from "@/lib/invoice-utils";
import type {
  Asset,
  InvoiceDetail,
  InvoiceServiceLine,
  MileageCorrectionDevice,
  Meter,
  ProductItem,
  ServiceCategory,
  ServiceItem,
} from "@/lib/types";

function ErrorBanner({ message }: { message: string | null }) {
  if (!message) return null;
  return <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{message}</p>;
}

/** Add-or-edit-or-replace dialog for one InvoiceServiceLine. Selecting a
 * Mileage Correction service expands the form to collect a meter + its
 * KM/device details, and creates the InvoiceMeterEntry and this line
 * together in one call (see apps.invoices.services.add_service_line() on
 * the backend) - no separate "add meter" step. Any other category shows
 * two independent amounts instead: Service Charge and (for a combination
 * repair like Display Repair) an optional Product + Product Price.
 *
 * Reused for adding (pass `trigger`, no `serviceLine`), editing (pass
 * `serviceLine` + a controlled `open`/`onOpenChange`, no `trigger`), and
 * replacing (same as editing, plus `allowReplace` to unlock the Service
 * combobox - rule 8's "replace which service/meter this line is for").
 * `reason` is forwarded to the edit call when reopening a Paid invoice
 * under the Admin "Edit Paid Invoice" exception.
 */
export function ServiceLineDialog({
  invoice,
  services,
  categories,
  meters,
  devices,
  products,
  assets,
  serviceLine,
  allowReplace = false,
  reason,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  invoice: InvoiceDetail;
  services: ServiceItem[];
  categories: ServiceCategory[];
  meters: Meter[];
  devices: MileageCorrectionDevice[];
  products: ProductItem[];
  assets: Asset[];
  serviceLine?: InvoiceServiceLine;
  allowReplace?: boolean;
  reason?: string;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: () => void;
}) {
  const isEdit = !!serviceLine;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;

  const [serviceId, setServiceId] = useState<number | null>(null);
  const [meterId, setMeterId] = useState<number | null>(null);
  const [serialNumber, setSerialNumber] = useState("");
  const [conditionNote, setConditionNote] = useState("");
  const [previousKm, setPreviousKm] = useState("");
  const [currentKm, setCurrentKm] = useState("");
  const [deviceId, setDeviceId] = useState<number | null>(null);
  const [price, setPrice] = useState("");
  const [priceEdited, setPriceEdited] = useState(false);
  const [productUsedId, setProductUsedId] = useState<number | null>(null);
  const [productPrice, setProductPrice] = useState("");
  const [productPriceEdited, setProductPriceEdited] = useState(false);
  const [assetUsedId, setAssetUsedId] = useState<number | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const mileageCorrectionCategoryId = categories.find((category) => category.name === "MILEAGE_CORRECTION")?.id;
  const selectedService = services.find((service) => service.id === serviceId) ?? null;
  const isMileageCorrection = !!selectedService && selectedService.category === mileageCorrectionCategoryId;
  const selectedMeter = meters.find((meter) => meter.id === meterId) ?? null;
  const selectedProductUsed = products.find((product) => product.id === productUsedId) ?? null;

  // The meter itself can't be changed once a meter entry already exists
  // (the API has no "swap which physical meter" support) - only its
  // serial/KM/condition/device fields. The Service combobox unlocks in
  // replace mode; the meter one only when there's no existing entry yet.
  const serviceLocked = isEdit && !allowReplace;
  const meterLocked = isEdit && !!serviceLine?.meter_entry_detail;

  const defaultPrice = isMileageCorrection ? selectedMeter?.sales_price : selectedService?.service_price;
  const defaultProductPrice = selectedProductUsed?.sale_price;

  // Pre-fill (or reset) every field whenever the dialog opens, based on
  // whether we're adding (serviceLine undefined) or editing/replacing
  // (its current values, including its linked meter entry if it has one).
  useEffect(() => {
    if (!open) return;
    if (serviceLine) {
      const entry = serviceLine.meter_entry_detail;
      setServiceId(serviceLine.service);
      setMeterId(entry?.meter ?? null);
      setSerialNumber(entry?.serial_number ?? "");
      setConditionNote(entry?.condition_note ?? "");
      setPreviousKm(entry?.previous_km != null ? String(entry.previous_km) : "");
      setCurrentKm(entry?.current_km != null ? String(entry.current_km) : "");
      setDeviceId(entry?.mileage_correction_device ?? null);
      setPrice(serviceLine.price_charged);
      setPriceEdited(true); // don't let the auto-default effect below clobber the loaded price
      setProductUsedId(serviceLine.product_used);
      setProductPrice(serviceLine.product_price);
      setProductPriceEdited(true);
      setAssetUsedId(serviceLine.asset_used);
    } else {
      setServiceId(null);
      setMeterId(null);
      setSerialNumber("");
      setConditionNote("");
      setPreviousKm("");
      setCurrentKm("");
      setDeviceId(null);
      setPrice("");
      setPriceEdited(false);
      setProductUsedId(null);
      setProductPrice("");
      setProductPriceEdited(false);
      setAssetUsedId(null);
    }
    setError(null);
  }, [open, serviceLine]);

  // Keep the price fields synced to their catalog defaults until the user
  // actually edits them themselves - never in plain edit mode (service/
  // meter/product there are usually fixed and the price should stay
  // whatever it already was billed at).
  useEffect(() => {
    if ((isEdit && !allowReplace) || priceEdited) return;
    setPrice(defaultPrice ?? "");
  }, [isEdit, allowReplace, priceEdited, defaultPrice]);

  useEffect(() => {
    if ((isEdit && !allowReplace) || productPriceEdited) return;
    setProductPrice(defaultProductPrice ?? "0");
  }, [isEdit, allowReplace, productPriceEdited, defaultProductPrice]);

  const serviceOptions: ComboboxOption[] = services.map((service) => ({
    value: service.id,
    label: service.name,
    description: `${service.category_name} · ৳${service.service_price}`,
  }));

  const meterOptions: ComboboxOption[] = meters.map((meter) => ({
    value: meter.id,
    label: meter.title,
    description: meter.memory_type,
  }));

  const deviceOptions: ComboboxOption[] = useMemo(() => {
    const compatible = selectedMeter ? compatibleCorrectionDevices(devices, selectedMeter.memory_type) : devices;
    return compatible.map((device) => ({ value: device.id, label: device.name }));
  }, [devices, selectedMeter]);

  const assetOptions: ComboboxOption[] = assets.map((asset) => ({ value: asset.id, label: asset.name }));
  const productOptions: ComboboxOption[] = products.map((product) => ({
    value: product.id,
    label: product.name,
    description: `${product.sku} · ৳${product.sale_price}`,
  }));

  const isValid =
    !!serviceId &&
    price !== "" &&
    (!isMileageCorrection || (!!meterId && !!conditionNote.trim()));

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid || !serviceId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const priceNumber = price === "" ? null : Number(price);
      const productPriceNumber = productPrice === "" ? null : Number(productPrice);

      if (isEdit && serviceLine) {
        await updateServiceLine(invoice.id, serviceLine.id, {
          ...(allowReplace && { service: serviceId }),
          price_charged: priceNumber,
          product_used: isMileageCorrection ? null : productUsedId,
          product_price: isMileageCorrection ? 0 : productPriceNumber,
          asset_used: isMileageCorrection ? undefined : assetUsedId,
          ...(isMileageCorrection && {
            ...(allowReplace && !meterLocked && { meter: meterId }),
            serial_number: serialNumber.trim(),
            condition_note: conditionNote.trim(),
            previous_km: previousKm === "" ? null : Number(previousKm),
            current_km: currentKm === "" ? null : Number(currentKm),
            mileage_correction_device: deviceId,
          }),
          ...(reason && { reason }),
        });
        toast.success(allowReplace ? "Service line replaced." : "Service updated.");
      } else {
        await addServiceLine(invoice.id, {
          service: serviceId,
          price_charged: priceNumber,
          product_used: isMileageCorrection ? null : productUsedId,
          product_price: isMileageCorrection ? 0 : productPriceNumber,
          asset_used: isMileageCorrection ? null : assetUsedId,
          ...(isMileageCorrection && {
            meter: meterId,
            serial_number: serialNumber.trim(),
            condition_note: conditionNote.trim(),
            previous_km: previousKm === "" ? null : Number(previousKm),
            current_km: currentKm === "" ? null : Number(currentKm),
            mileage_correction_device: deviceId,
          }),
        });
        toast.success("Service added.");
      }
      setOpen(false);
      onSaved();
    } catch (err) {
      const message =
        err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to save the service.";
      toast.error(message);
      setError(message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{allowReplace ? "Replace service" : isEdit ? "Edit service" : "Add a service"}</DialogTitle>
          <DialogDescription>
            {allowReplace
              ? "Change which service (and meter, if applicable) this line bills."
              : isEdit
                ? "Update this line's details."
                : "Search for a service - Mileage Correction expands to collect the meter's details."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Service <span className="text-destructive">*</span>
            </Label>
            <Combobox
              options={serviceOptions}
              value={serviceId}
              onChange={(value) => {
                setServiceId(value);
                setMeterId(null);
                setDeviceId(null);
                setAssetUsedId(null);
                setProductUsedId(null);
                setPriceEdited(false);
                setProductPriceEdited(false);
              }}
              disabled={serviceLocked}
              placeholder="Search services..."
              searchPlaceholder="Search services..."
            />
          </div>

          {isMileageCorrection && (
            <>
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
                    setPriceEdited(false);
                  }}
                  disabled={meterLocked}
                  placeholder="Search meters..."
                  searchPlaceholder="Search meters..."
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="service-line-serial">Serial number (optional)</Label>
                <Input
                  id="service-line-serial"
                  value={serialNumber}
                  onChange={(event) => setSerialNumber(event.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="service-line-condition">
                  Condition note <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="service-line-condition"
                  value={conditionNote}
                  onChange={(event) => setConditionNote(event.target.value)}
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2">
                  <Label htmlFor="service-line-previous-km">Previous KM (optional)</Label>
                  <Input
                    id="service-line-previous-km"
                    type="number"
                    min={0}
                    value={previousKm}
                    onChange={(event) => setPreviousKm(event.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="service-line-current-km">Current KM (optional)</Label>
                  <Input
                    id="service-line-current-km"
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
                  placeholder={selectedMeter ? "Optional" : "Pick a meter first"}
                  disabled={!selectedMeter}
                  emptyMessage="No compatible device"
                  searchPlaceholder="Search devices..."
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="service-line-price">
                  Price <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="service-line-price"
                  type="number"
                  min={0}
                  step="0.01"
                  value={price}
                  onChange={(event) => {
                    setPrice(event.target.value);
                    setPriceEdited(true);
                  }}
                />
                <p className="text-xs text-muted-foreground">
                  Defaults to the selected meter&apos;s sales price - edit to charge something else.
                </p>
              </div>
            </>
          )}

          {!isMileageCorrection && selectedService && (
            <>
              <div className="space-y-2">
                <Label htmlFor="service-line-charge">
                  Service Charge <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="service-line-charge"
                  type="number"
                  min={0}
                  step="0.01"
                  value={price}
                  onChange={(event) => {
                    setPrice(event.target.value);
                    setPriceEdited(true);
                  }}
                />
                <p className="text-xs text-muted-foreground">
                  Labor only - defaults to the service&apos;s own price, edit to charge something else.
                </p>
              </div>
              <div className="space-y-2">
                <Label>Product used (optional)</Label>
                <Combobox
                  options={productOptions}
                  value={productUsedId}
                  onChange={(value) => {
                    setProductUsedId(value);
                    setProductPriceEdited(false);
                  }}
                  allowClear
                  placeholder="Combination repairs only, e.g. a display panel or polarizer paper"
                  searchPlaceholder="Search products..."
                />
              </div>
              {productUsedId != null && (
                <div className="space-y-2">
                  <Label htmlFor="service-line-product-price">Product Price</Label>
                  <Input
                    id="service-line-product-price"
                    type="number"
                    min={0}
                    step="0.01"
                    value={productPrice}
                    onChange={(event) => {
                      setProductPrice(event.target.value);
                      setProductPriceEdited(true);
                    }}
                  />
                  <p className="text-xs text-muted-foreground">
                    Independent of the service charge - defaults to the product&apos;s sale price, edit to charge
                    something else.
                  </p>
                </div>
              )}
              <div className="space-y-2">
                <Label>Asset used</Label>
                <Combobox
                  options={assetOptions}
                  value={assetUsedId}
                  onChange={setAssetUsedId}
                  allowClear
                  placeholder={assetOptions.length ? "Optional — which tool did the repair?" : "No assets recorded yet"}
                  disabled={assetOptions.length === 0}
                  emptyMessage="No assets found"
                  searchPlaceholder="Search assets..."
                />
              </div>
            </>
          )}

          <ErrorBanner message={error} />
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Saving..." : allowReplace ? "Replace" : isEdit ? "Save changes" : "Add service"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
