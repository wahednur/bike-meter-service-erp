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
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { createAsset, updateAsset } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Asset, AssetPayload, Supplier } from "@/lib/types";

export function AssetFormDialog({
  asset,
  suppliers,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  asset?: Asset;
  suppliers: Supplier[];
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (asset: Asset) => void;
}) {
  const isEdit = !!asset;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [name, setName] = useState(asset?.name ?? "");
  const [purchasePrice, setPurchasePrice] = useState(asset?.purchase_price ?? "");
  const [purchaseDate, setPurchaseDate] = useState(asset?.purchase_date ?? "");
  const [supplierId, setSupplierId] = useState<number | null>(asset?.supplier ?? null);
  const [hasWarranty, setHasWarranty] = useState(asset?.has_warranty ?? false);
  const [warrantyNote, setWarrantyNote] = useState(asset?.warranty_note ?? "");
  const [description, setDescription] = useState(asset?.description ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName(asset?.name ?? "");
    setPurchasePrice(asset?.purchase_price ?? "");
    setPurchaseDate(asset?.purchase_date ?? "");
    setSupplierId(asset?.supplier ?? null);
    setHasWarranty(asset?.has_warranty ?? false);
    setWarrantyNote(asset?.warranty_note ?? "");
    setDescription(asset?.description ?? "");
    setError(null);
  }, [open, asset]);

  const isValid = name.trim() && purchasePrice && purchaseDate;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: AssetPayload = {
        name: name.trim(),
        purchase_price: Number(purchasePrice),
        purchase_date: purchaseDate,
        supplier: supplierId,
        has_warranty: hasWarranty,
        warranty_note: warrantyNote.trim(),
        description: description.trim(),
      };
      const saved = asset ? await updateAsset(asset.id, payload) : await createAsset(payload);
      toast.success(isEdit ? "Asset updated." : "Asset added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the asset."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit asset" : "Add asset"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this asset's details." : "Create a new shop asset."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label htmlFor="asset-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input id="asset-name" required value={name} onChange={(event) => setName(event.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="asset-purchase-price">
                Purchase Price <span className="text-destructive">*</span>
              </Label>
              <Input
                id="asset-purchase-price"
                type="number"
                min={0}
                step="0.01"
                required
                value={purchasePrice}
                onChange={(event) => setPurchasePrice(event.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="asset-purchase-date">
                Purchase Date <span className="text-destructive">*</span>
              </Label>
              <Input
                id="asset-purchase-date"
                type="date"
                required
                value={purchaseDate}
                onChange={(event) => setPurchaseDate(event.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Supplier</Label>
            <Select
              value={supplierId ? String(supplierId) : "none"}
              onValueChange={(value) => setSupplierId(value === "none" ? null : Number(value))}
            >
              <SelectTrigger className="w-full">
                <SelectValue placeholder="No supplier" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="none">— None —</SelectItem>
                {suppliers.map((supplier) => (
                  <SelectItem key={supplier.id} value={String(supplier.id)}>
                    {supplier.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex items-center justify-between rounded-lg border px-3 py-2.5">
            <Label htmlFor="asset-has-warranty" className="cursor-pointer">
              Has warranty
            </Label>
            <Switch id="asset-has-warranty" checked={hasWarranty} onCheckedChange={setHasWarranty} />
          </div>
          {hasWarranty && (
            <div className="space-y-2">
              <Label htmlFor="asset-warranty-note">Warranty note</Label>
              <Textarea
                id="asset-warranty-note"
                value={warrantyNote}
                onChange={(event) => setWarrantyNote(event.target.value)}
              />
            </div>
          )}
          <div className="space-y-2">
            <Label htmlFor="asset-description">Description</Label>
            <Textarea
              id="asset-description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!isValid || isSubmitting} className="text-white">
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
