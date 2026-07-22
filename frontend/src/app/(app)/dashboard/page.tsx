"use client";

import {
  AlertTriangle,
  CalendarClock,
  FileText,
  PackageX,
  PiggyBank,
  UserX,
  Wallet,
  Wrench,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/empty-state";
import { IncomeTrendChart } from "@/components/income-trend-chart";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ApiError, getAdminDashboard } from "@/lib/api";
import type { AdminDashboardSummary } from "@/lib/types";

// Cycled across --chart-1..5 - with 8 stat cards and only 5 theme accent
// colors, a couple of cards repeat a color, but no two adjacent cards share
// one, which is enough to make each block visually distinct at a glance.
//
// Applied via inline style (not Tailwind arbitrary-value classes) on
// purpose: Tailwind's build-time scanner only generates CSS for utility
// classes it finds as complete, literal strings in the source, and even a
// fully-spelled-out class list here would depend on `bg-[var(--chart-1)]/15`
// -style opacity-modifier-on-a-CSS-variable being supported, which this
// project's Tailwind v4 setup does not resolve. Inline style sidesteps both
// problems and renders identically in both themes since it reads the same
// CSS custom properties globals.css already defines per theme.
function accentColor(index: number): string {
  return `var(--chart-${(index % 5) + 1})`;
}

function StatCard({
  label,
  value,
  hint,
  icon: Icon,
  accentIndex,
}: {
  label: string;
  value: string;
  hint?: string;
  icon: LucideIcon;
  accentIndex: number;
}) {
  const color = accentColor(accentIndex);

  return (
    <Card className="border-l-4" style={{ borderLeftColor: color }}>
      <CardContent className="flex items-start gap-3">
        <div
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg"
          style={{ backgroundColor: `color-mix(in oklab, ${color} 18%, transparent)`, color }}
        >
          <Icon className="h-4.5 w-4.5" />
        </div>
        <div className="min-w-0">
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">{label}</p>
          <p className="text-xl font-semibold">{value}</p>
          {hint && <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p>}
        </div>
      </CardContent>
    </Card>
  );
}

function DashboardSkeleton() {
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-4 w-24" />
      </div>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        {Array.from({ length: 8 }).map((_, index) => (
          <Skeleton key={index} className="h-20 w-full" />
        ))}
      </div>
      <Skeleton className="h-80 w-full" />
    </div>
  );
}

function DashboardContent() {
  const [data, setData] = useState<AdminDashboardSummary | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    getAdminDashboard()
      .then((result) => {
        if (isMounted) setData(result);
      })
      .catch((err: unknown) => {
        if (!isMounted) return;
        const message =
          err instanceof ApiError && err.status === 403
            ? "This dashboard is Admin-only. Log in with an Admin account to view it."
            : err instanceof ApiError
              ? err.message
              : "Failed to load the dashboard.";
        toast.error(message);
        setError(message);
      })
      .finally(() => {
        if (isMounted) setIsLoading(false);
      });
    return () => {
      isMounted = false;
    };
  }, []);

  if (isLoading) return <DashboardSkeleton />;
  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }
  if (!data) return null;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-xl font-semibold">Admin Dashboard</h1>
        <p className="text-sm text-muted-foreground">{data.date}</p>
      </div>

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        <StatCard label="Today's Income" value={`৳${data.today_income}`} icon={Wallet} accentIndex={0} />
        <StatCard
          label="Pending Dues"
          value={`৳${data.pending_dues.total_due}`}
          hint={`${data.pending_dues.invoice_count} invoice(s)`}
          icon={AlertTriangle}
          accentIndex={1}
        />
        <StatCard
          label="Red-Listed Customers"
          value={String(data.red_listed_customers_count)}
          icon={UserX}
          accentIndex={2}
        />
        <StatCard
          label="Low-Stock Products"
          value={String(data.low_stock_products.length)}
          hint={`≤ ${data.low_stock_threshold} units`}
          icon={PackageX}
          accentIndex={3}
        />
        <StatCard
          label="Upcoming Installments"
          value={String(data.upcoming_loan_installments.length)}
          hint={`next ${data.upcoming_days} days`}
          icon={CalendarClock}
          accentIndex={4}
        />
        <StatCard
          label="Today's Invoices Created"
          value={String(data.today_invoice_count)}
          icon={FileText}
          accentIndex={0}
        />
        <StatCard
          label="Today's Total Work Value"
          value={`৳${data.today_total_amount}`}
          icon={Wrench}
          accentIndex={1}
        />
        <StatCard
          label="Total Income (All Time)"
          value={`৳${data.total_income_all_time}`}
          icon={PiggyBank}
          accentIndex={2}
        />
      </div>

      <IncomeTrendChart />

      <section>
        <h2 className="mb-2 text-sm font-semibold">
          Low Stock Products{" "}
          <span className="font-normal text-muted-foreground">(&le; {data.low_stock_threshold} units)</span>
        </h2>
        {data.low_stock_products.length === 0 ? (
          <EmptyState icon={PackageX} title="Nothing low on stock" />
        ) : (
          <Card className="py-0">
            <ul className="divide-y">
              {data.low_stock_products.map((product) => (
                <li key={product.id} className="flex items-center justify-between px-4 py-2.5 text-sm">
                  <span>
                    {product.name} <span className="text-muted-foreground">({product.sku})</span>
                  </span>
                  <Badge variant="secondary">{product.current_stock_quantity} left</Badge>
                </li>
              ))}
            </ul>
          </Card>
        )}
      </section>

      <section>
        <h2 className="mb-2 text-sm font-semibold">
          Upcoming Loan Installments{" "}
          <span className="font-normal text-muted-foreground">(next {data.upcoming_days} days)</span>
        </h2>
        {data.upcoming_loan_installments.length === 0 ? (
          <EmptyState icon={CalendarClock} title="Nothing due soon" />
        ) : (
          <Card className="py-0">
            <ul className="divide-y">
              {data.upcoming_loan_installments.map((installment) => (
                <li
                  key={`${installment.loan_id}-${installment.installment_number}`}
                  className="flex items-center justify-between px-4 py-2.5 text-sm"
                >
                  <span>
                    {installment.lender_name} — installment #{installment.installment_number}
                  </span>
                  <span className="text-muted-foreground">
                    ৳{installment.installment_amount} due {installment.due_date}
                  </span>
                </li>
              ))}
            </ul>
          </Card>
        )}
      </section>
    </div>
  );
}

export default function DashboardPage() {
  return <DashboardContent />;
}
