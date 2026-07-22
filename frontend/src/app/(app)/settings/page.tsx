"use client";

import { useEffect, useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { updateShopProfile } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { reportError } from "@/lib/errors";
import { useShopProfile } from "@/lib/shop-profile-context";

function ReadOnlyRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs text-muted-foreground">{label}</dt>
      <dd className="text-sm">{value || "—"}</dd>
    </div>
  );
}

export default function SettingsPage() {
  const { user } = useAuth();
  const { shopProfile, isLoading, refresh } = useShopProfile();
  const isAdmin = user?.role === "admin";

  const [shopName, setShopName] = useState(shopProfile.shop_name);
  const [address, setAddress] = useState(shopProfile.address);
  const [phone, setPhone] = useState(shopProfile.phone);
  const [invoiceFooterText, setInvoiceFooterText] = useState(shopProfile.invoice_footer_text);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isLoading) return;
    setShopName(shopProfile.shop_name);
    setAddress(shopProfile.address);
    setPhone(shopProfile.phone);
    setInvoiceFooterText(shopProfile.invoice_footer_text);
  }, [isLoading, shopProfile]);

  const isValid = shopName.trim() && invoiceFooterText.trim();

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isValid) return;
    setError(null);
    setIsSubmitting(true);
    try {
      await updateShopProfile({
        shop_name: shopName.trim(),
        address: address.trim(),
        phone: phone.trim(),
        invoice_footer_text: invoiceFooterText.trim(),
      });
      toast.success("Shop profile updated.");
      refresh();
    } catch (err) {
      setError(reportError(err, "Failed to save the shop profile."));
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold">Settings</h1>
        <p className="text-sm text-muted-foreground">Shop profile shown on invoices and printouts.</p>
      </div>

      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle>Shop Profile</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-3">
              <Skeleton className="h-9 w-full" />
              <Skeleton className="h-9 w-full" />
              <Skeleton className="h-9 w-full" />
              <Skeleton className="h-20 w-full" />
            </div>
          ) : !isAdmin ? (
            <dl className="space-y-3">
              <ReadOnlyRow label="Shop Name" value={shopProfile.shop_name} />
              <ReadOnlyRow label="Address" value={shopProfile.address} />
              <ReadOnlyRow label="Phone" value={shopProfile.phone} />
              <ReadOnlyRow label="Invoice Footer Text" value={shopProfile.invoice_footer_text} />
              <p className="text-xs text-muted-foreground">Only Admins can edit the shop profile.</p>
            </dl>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-3">
              <div className="space-y-2">
                <Label htmlFor="shop-name">
                  Shop Name <span className="text-destructive">*</span>
                </Label>
                <Input id="shop-name" required value={shopName} onChange={(event) => setShopName(event.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="shop-address">Address</Label>
                <Textarea id="shop-address" value={address} onChange={(event) => setAddress(event.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="shop-phone">Phone</Label>
                <Input id="shop-phone" value={phone} onChange={(event) => setPhone(event.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="shop-footer">
                  Invoice Footer Text <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="shop-footer"
                  required
                  value={invoiceFooterText}
                  onChange={(event) => setInvoiceFooterText(event.target.value)}
                />
                <p className="text-xs text-muted-foreground">
                  Shown at the bottom of the printable/public invoice view.
                </p>
              </div>
              {error && <p className="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">{error}</p>}
              <Button type="submit" disabled={!isValid || isSubmitting}>
                {isSubmitting ? "Saving..." : "Save"}
              </Button>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
