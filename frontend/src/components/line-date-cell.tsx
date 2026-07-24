"use client";

import { useState } from "react";
import { toast } from "sonner";

import { DatePickerButton } from "@/components/date-picker-button";
import { ApiError } from "@/lib/api";
import { cleanInvoiceErrorMessage } from "@/lib/invoice-utils";

/** Inline per-row date editor for a service/product line's added_date
 * (rule 4) - kept separate from the full edit dialog so changing just the
 * date doesn't require opening it. Read-only text when `disabled`. */
export function LineDateCell({
  value,
  disabled,
  onChange,
}: {
  value: string;
  disabled: boolean;
  onChange: (nextValue: string) => Promise<unknown>;
}) {
  const [isSaving, setIsSaving] = useState(false);

  async function handleChange(next: string | undefined) {
    if (!next || next === value) return;
    setIsSaving(true);
    try {
      await onChange(next);
    } catch (err) {
      toast.error(err instanceof ApiError ? cleanInvoiceErrorMessage(err.message) : "Failed to update the date.");
    } finally {
      setIsSaving(false);
    }
  }

  if (disabled) {
    return <span className="text-muted-foreground">{value}</span>;
  }

  return (
    <DatePickerButton
      value={value}
      onChange={handleChange}
      size="sm"
      className={`w-32 ${isSaving ? "opacity-60" : ""}`}
    />
  );
}
