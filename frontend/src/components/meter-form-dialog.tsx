"use client";

import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { toast } from "sonner";

import { ImageUploadField } from "@/components/image-upload-field";
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
import { Textarea } from "@/components/ui/textarea";
import { createMeter, updateMeter } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Meter, MeterPayload } from "@/lib/types";

export function MeterFormDialog({
  meter,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  meter?: Meter;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (meter: Meter) => void;
}) {
  const isEdit = !!meter;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [brand, setBrand] = useState(meter?.brand ?? "");
  const [model, setModel] = useState(meter?.model ?? "");
  const [cc, setCc] = useState(meter ? String(meter.cc) : "");
  const [memoryType, setMemoryType] = useState<"EEPROM" | "MCU">(meter?.memory_type ?? "EEPROM");
  const [icMcuModel, setIcMcuModel] = useState(meter?.ic_mcu_model ?? "");
  const [salesPrice, setSalesPrice] = useState(meter?.sales_price ?? "");
  const [description, setDescription] = useState(meter?.description ?? "");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setBrand(meter?.brand ?? "");
    setModel(meter?.model ?? "");
    setCc(meter ? String(meter.cc) : "");
    setMemoryType(meter?.memory_type ?? "EEPROM");
    setIcMcuModel(meter?.ic_mcu_model ?? "");
    setSalesPrice(meter?.sales_price ?? "");
    setDescription(meter?.description ?? "");
    setImageFile(null);
    setError(null);
  }, [open, meter]);

  const isValid = brand.trim() && model.trim() && cc && icMcuModel.trim() && salesPrice;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: MeterPayload = {
        brand: brand.trim(),
        model: model.trim(),
        cc: Number(cc),
        memory_type: memoryType,
        ic_mcu_model: icMcuModel.trim(),
        sales_price: Number(salesPrice),
        description: description.trim(),
        image: imageFile ?? undefined,
      };
      const saved = meter ? await updateMeter(meter.id, payload) : await createMeter(payload);
      toast.success(isEdit ? "Meter updated." : "Meter added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the meter."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit meter" : "Add meter"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this meter's details." : "Create a new meter record."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="meter-brand">
                Brand <span className="text-destructive">*</span>
              </Label>
              <Input id="meter-brand" required value={brand} onChange={(event) => setBrand(event.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="meter-model">
                Model <span className="text-destructive">*</span>
              </Label>
              <Input id="meter-model" required value={model} onChange={(event) => setModel(event.target.value)} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="meter-cc">
                CC <span className="text-destructive">*</span>
              </Label>
              <Input
                id="meter-cc"
                type="number"
                min={1}
                required
                value={cc}
                onChange={(event) => setCc(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>
                Memory Type <span className="text-destructive">*</span>
              </Label>
              <Select value={memoryType} onValueChange={(value) => setMemoryType(value as "EEPROM" | "MCU")}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="EEPROM">EEPROM</SelectItem>
                  <SelectItem value="MCU">MCU</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="meter-ic-mcu-model">
              IC/MCU Model <span className="text-destructive">*</span>
            </Label>
            <Input
              id="meter-ic-mcu-model"
              required
              value={icMcuModel}
              onChange={(event) => setIcMcuModel(event.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="meter-sales-price">
              Sales Price <span className="text-destructive">*</span>
            </Label>
            <Input
              id="meter-sales-price"
              type="number"
              min={0}
              step="0.01"
              required
              value={salesPrice}
              onChange={(event) => setSalesPrice(event.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="meter-description">Description</Label>
            <Textarea
              id="meter-description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>
          <ImageUploadField existingImageUrl={meter?.image} value={imageFile} onChange={setImageFile} />
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
