"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Area, AreaChart, CartesianGrid, XAxis } from "recharts";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { type ChartConfig, ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { Skeleton } from "@/components/ui/skeleton";
import { ApiError, getIncomeReport } from "@/lib/api";

const chartConfig = {
  income: {
    label: "Income",
    color: "var(--chart-1)",
  },
} satisfies ChartConfig;

interface TrendPoint {
  date: string;
  income: number;
}

/** Local (not UTC) YYYY-MM-DD - avoids the date rolling over near midnight
 * that toISOString() would cause in timezones behind UTC. */
function toDateKey(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function buildLast30Days(): string[] {
  const days: string[] = [];
  const today = new Date();
  for (let i = 29; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    days.push(toDateKey(date));
  }
  return days;
}

function formatAxisDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

function formatTooltipDate(value: ReactNode) {
  if (typeof value !== "string") return value;
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export function IncomeTrendChart() {
  const [rows, setRows] = useState<TrendPoint[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    const days = buildLast30Days();

    getIncomeReport({ period: "daily", fromDate: days[0], toDate: days[days.length - 1] })
      .then((report) => {
        if (!isMounted) return;
        const incomeByDate = new Map(report.rows.map((row) => [row.period_start, Number(row.income)]));
        setRows(days.map((date) => ({ date, income: incomeByDate.get(date) ?? 0 })));
      })
      .catch((err: unknown) => {
        if (!isMounted) return;
        setError(err instanceof ApiError ? err.message : "Failed to load the income trend.");
      });

    return () => {
      isMounted = false;
    };
  }, []);

  const total = useMemo(() => rows?.reduce((sum, row) => sum + row.income, 0) ?? 0, [rows]);

  return (
    <Card>
      <CardHeader>
        <CardTitle>Income Trend</CardTitle>
        <CardDescription>Last 30 days{rows ? ` · ৳${total.toLocaleString()} total` : ""}</CardDescription>
      </CardHeader>
      <CardContent>
        {error ? (
          <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>
        ) : !rows ? (
          <Skeleton className="h-64 w-full" />
        ) : (
          <ChartContainer config={chartConfig} className="h-64 w-full">
            <AreaChart data={rows} margin={{ left: 12, right: 12 }}>
              <CartesianGrid vertical={false} />
              <XAxis
                dataKey="date"
                tickLine={false}
                axisLine={false}
                tickMargin={8}
                minTickGap={24}
                tickFormatter={formatAxisDate}
              />
              <ChartTooltip content={<ChartTooltipContent labelFormatter={formatTooltipDate} />} />
              <Area
                dataKey="income"
                type="monotone"
                fill="var(--color-income)"
                fillOpacity={0.2}
                stroke="var(--color-income)"
              />
            </AreaChart>
          </ChartContainer>
        )}
      </CardContent>
    </Card>
  );
}
