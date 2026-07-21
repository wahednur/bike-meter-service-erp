"use client";

import { useEffect, useState } from "react";

import { IncomeTrendChart } from "@/components/income-trend-chart";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ApiError, getAdminDashboard } from "@/lib/api";
import type { AdminDashboardSummary } from "@/lib/types";

function StatCard({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
          {label}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-2xl font-semibold">{value}</p>
        {hint && <p className="mt-1 text-xs text-muted-foreground">{hint}</p>}
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
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        {Array.from({ length: 5 }).map((_, index) => (
          <Skeleton key={index} className="h-24 w-full" />
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
        if (err instanceof ApiError && err.status === 403) {
          setError("This dashboard is Admin-only. Log in with an Admin account to view it.");
        } else if (err instanceof ApiError) {
          setError(err.message);
        } else {
          setError("Failed to load the dashboard.");
        }
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

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        <StatCard label="Today's Income" value={`৳${data.today_income}`} />
        <StatCard
          label="Pending Dues"
          value={`৳${data.pending_dues.total_due}`}
          hint={`${data.pending_dues.invoice_count} invoice(s)`}
        />
        <StatCard label="Red-Listed Customers" value={String(data.red_listed_customers_count)} />
        <StatCard
          label="Low-Stock Products"
          value={String(data.low_stock_products.length)}
          hint={`≤ ${data.low_stock_threshold} units`}
        />
        <StatCard
          label="Upcoming Installments"
          value={String(data.upcoming_loan_installments.length)}
          hint={`next ${data.upcoming_days} days`}
        />
      </div>

      <IncomeTrendChart />

      <section>
        <h2 className="mb-2 text-sm font-semibold">
          Low Stock Products{" "}
          <span className="font-normal text-muted-foreground">(&le; {data.low_stock_threshold} units)</span>
        </h2>
        {data.low_stock_products.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nothing low on stock.</p>
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
          <p className="text-sm text-muted-foreground">Nothing due soon.</p>
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
