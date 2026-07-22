"use client";

import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { toast } from "sonner";

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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { createMileageCorrectionDevice, updateMileageCorrectionDevice } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { MileageCorrectionDevice, MileageCorrectionDevicePayload } from "@/lib/types";

type MemoryTypeSupport = "EEPROM" | "MCU" | "BOTH";

export function DeviceFormDialog({
  device,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  device?: MileageCorrectionDevice;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (device: MileageCorrectionDevice) => void;
}) {
  const isEdit = !!device;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [name, setName] = useState(device?.name ?? "");
  const [purchasePrice, setPurchasePrice] = useState(device?.purchase_price ?? "");
  const [purchaseDate, setPurchaseDate] = useState(device?.purchase_date ?? "");
  const [memoryTypeSupport, setMemoryTypeSupport] = useState<MemoryTypeSupport>(
    device?.memory_type_support ?? "BOTH",
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName(device?.name ?? "");
    setPurchasePrice(device?.purchase_price ?? "");
    setPurchaseDate(device?.purchase_date ?? "");
    setMemoryTypeSupport(device?.memory_type_support ?? "BOTH");
    setError(null);
  }, [open, device]);

  const isValid = name.trim() && purchasePrice && purchaseDate;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: MileageCorrectionDevicePayload = {
        name: name.trim(),
        purchase_price: Number(purchasePrice),
        purchase_date: purchaseDate,
        memory_type_support: memoryTypeSupport,
      };
      const saved = device
        ? await updateMileageCorrectionDevice(device.id, payload)
        : await createMileageCorrectionDevice(payload);
      toast.success(isEdit ? "Device updated." : "Device added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the device."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit device" : "Add device"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this mileage correction device's details." : "Create a new mileage correction device."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="device-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input id="device-name" required value={name} onChange={(event) => setName(event.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="device-purchase-price">
                Purchase Price <span className="text-destructive">*</span>
              </Label>
              <Input
                id="device-purchase-price"
                type="number"
                min={0}
                step="0.01"
                required
                value={purchasePrice}
                onChange={(event) => setPurchasePrice(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="device-purchase-date">
                Purchase Date <span className="text-destructive">*</span>
              </Label>
              <Input
                id="device-purchase-date"
                type="date"
                required
                value={purchaseDate}
                onChange={(event) => setPurchaseDate(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label>
              Memory Type Support <span className="text-destructive">*</span>
            </Label>
            <Select
              value={memoryTypeSupport}
              onValueChange={(value) => setMemoryTypeSupport(value as MemoryTypeSupport)}
            >
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="EEPROM">EEPROM</SelectItem>
                <SelectItem value="MCU">MCU</SelectItem>
                <SelectItem value="BOTH">Both</SelectItem>
              </SelectContent>
            </Select>
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting}>
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
