"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { Combobox, type ComboboxOption } from "@/components/combobox";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { listCustomers, startInvoice } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Customer } from "@/lib/types";

export default function NewInvoicePage() {
  const router = useRouter();
  const [customers, setCustomers] = useState<Customer[] | null>(null);
  const [customerId, setCustomerId] = useState<number | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isStarting, setIsStarting] = useState(false);

  useEffect(() => {
    listCustomers()
      .then(setCustomers)
      .catch((err: unknown) => {
        setLoadError(reportError(err, "Failed to load customers."));
      });
  }, []);

  const options: ComboboxOption[] = (customers ?? []).map((customer) => ({
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
      router.push(`/invoices/${invoice.id}`);
    } catch (err) {
      setError(reportError(err, "Failed to start the invoice."));
      setIsStarting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">New Invoice</h1>
        <p className="text-sm text-muted-foreground">
          Pick a customer to start a visit. If they already have an open invoice, it will be resumed instead of
          creating a new one.
        </p>
      </div>

      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle>Start a visit</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {loadError ? (
            <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{loadError}</p>
          ) : !customers ? (
            <Skeleton className="h-9 w-full" />
          ) : (
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
          )}
          {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
        </CardContent>
      </Card>
    </div>
  );
}
