"use client";

import { Area, AreaChart, CartesianGrid, XAxis } from "recharts";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { type ChartConfig, ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";

export interface TrendPoint {
  date: string;
  value: number;
}

export function ReportTrendChart({
  title,
  description,
  data,
  colorVar,
  valueLabel,
}: {
  title: string;
  description?: string;
  data: TrendPoint[];
  colorVar: string;
  valueLabel: string;
}) {
  const chartConfig = {
    value: { label: valueLabel, color: colorVar },
  } satisfies ChartConfig;

  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        {description && <CardDescription>{description}</CardDescription>}
      </CardHeader>
      <CardContent>
        {data.length === 0 ? (
          <p className="text-sm text-muted-foreground">No data for this range yet.</p>
        ) : (
          <ChartContainer config={chartConfig} className="h-64 w-full">
            <AreaChart data={data} margin={{ left: 12, right: 12 }}>
              <CartesianGrid vertical={false} />
              <XAxis dataKey="date" tickLine={false} axisLine={false} tickMargin={8} minTickGap={24} />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Area
                dataKey="value"
                type="monotone"
                fill="var(--color-value)"
                fillOpacity={0.2}
                stroke="var(--color-value)"
              />
            </AreaChart>
          </ChartContainer>
        )}
      </CardContent>
    </Card>
  );
}
