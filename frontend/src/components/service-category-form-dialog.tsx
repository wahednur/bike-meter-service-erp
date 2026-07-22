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
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { createServiceCategory, updateServiceCategory } from "@/lib/api";
import { reportError } from "@/lib/errors";
import { SERVICE_CATEGORY_NAMES, type ServiceCategory, type ServiceCategoryName } from "@/lib/types";

export function formatCategoryName(name: string): string {
  return name
    .split("_")
    .map((word) => word.charAt(0) + word.slice(1).toLowerCase())
    .join(" ");
}

export function ServiceCategoryFormDialog({
  category,
  existingNames = [],
  trigger,
  open: openProp,
  onOpenChange: onOpenChangeProp,
  onSaved,
}: {
  category?: ServiceCategory;
  existingNames?: string[];
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  onSaved: (category: ServiceCategory) => void;
}) {
  const isEdit = !!category;
  const [internalOpen, setInternalOpen] = useState(false);
  const open = openProp ?? internalOpen;
  const setOpen = onOpenChangeProp ?? setInternalOpen;
  const availableNames = SERVICE_CATEGORY_NAMES.filter(
    (name) => name === category?.name || !existingNames.includes(name),
  );
  const [name, setName] = useState<ServiceCategoryName | "">(category?.name ?? availableNames[0] ?? "");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName(category?.name ?? availableNames[0] ?? "");
    setError(null);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, category]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!name) return;
    setError(null);
    setIsSubmitting(true);
    try {
      const saved = category
        ? await updateServiceCategory(category.id, { name })
        : await createServiceCategory({ name });
      toast.success(isEdit ? "Category updated." : "Category added.");
      setOpen(false);
      onSaved(saved);
    } catch (err) {
      setError(reportError(err, "Failed to save the category."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {trigger && <DialogTrigger asChild>{trigger}</DialogTrigger>}
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit category" : "Add category"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Change this service category." : "Create a new service category."}
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="space-y-2">
            <Label>
              Category <span className="text-destructive">*</span>
            </Label>
            {availableNames.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                All service categories already exist — nothing left to add.
              </p>
            ) : (
              <Select value={name} onValueChange={(value) => setName(value as ServiceCategoryName)}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {availableNames.map((option) => (
                    <SelectItem key={option} value={option}>
                      {formatCategoryName(option)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )}
          </div>
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
          <DialogFooter>
            <Button type="submit" disabled={!name || isSubmitting}>
              {isSubmitting ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
