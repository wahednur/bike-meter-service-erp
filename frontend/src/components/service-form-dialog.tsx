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
import { createService, updateService } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ServiceCategory, ServiceItem, ServicePayload } from "@/lib/types";

export function ServiceFormDialog({
  service,
  categories,
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  service?: ServiceItem;
  categories: ServiceCategory[];
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (service: ServiceItem) => void;
}) {
  const isEdit = !!service;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const [categoryId, setCategoryId] = useState<number | null>(service?.category ?? categories[0]?.id ?? null);
  const [name, setName] = useState(service?.name ?? "");
  const [servicePrice, setServicePrice] = useState(service?.service_price ?? "");
  const [description, setDescription] = useState(service?.description ?? "");
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setCategoryId(service?.category ?? categories[0]?.id ?? null);
    setName(service?.name ?? "");
    setServicePrice(service?.service_price ?? "");
    setDescription(service?.description ?? "");
    setImageFile(null);
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, service]);

  const isValid = categoryId && name.trim() && servicePrice;

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid || !categoryId) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const payload: ServicePayload = {
        category: categoryId,
        name: name.trim(),
        service_price: Number(servicePrice),
        description: description.trim(),
        image: imageFile ?? undefined,
      };
      const saved = service ? await updateService(service.id, payload) : await createService(payload);
      toast.success(isEdit ? "Service updated." : "Service added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the service."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit service" : "Add service"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update this service's details." : "Create a new service."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Category <span className="text-destructive">*</span>
            </Label>
            <Select
              value={categoryId ? String(categoryId) : undefined}
              onValueChange={(value) => setCategoryId(Number(value))}
              disabled={categories.length === 0}
            >
              <SelectTrigger className="w-full">
                <SelectValue placeholder={categories.length ? "Select a category" : "No categories yet"} />
              </SelectTrigger>
              <SelectContent>
                {categories.map((category) => (
                  <SelectItem key={category.id} value={String(category.id)}>
                    {category.name_display}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="service-name">
              Name <span className="text-destructive">*</span>
            </Label>
            <Input id="service-name" required value={name} onChange={(event) => setName(event.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="service-price">
              Price <span className="text-destructive">*</span>
            </Label>
            <Input
              id="service-price"
              type="number"
              min={0}
              step="0.01"
              required
              value={servicePrice}
              onChange={(event) => setServicePrice(event.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="service-description">Description</Label>
            <Textarea
              id="service-description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </div>
          <ImageUploadField existingImageUrl={service?.image} value={imageFile} onChange={setImageFile} />
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
