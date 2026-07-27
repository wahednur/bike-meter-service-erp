"use client";

import { ArrowLeft, Pencil, Wrench } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { ConditionNoteBadges } from "@/components/condition-note-badges";
import { EmptyState } from "@/components/empty-state";
import { ImageThumbnail } from "@/components/image-thumbnail";
import { MeterFormDialog } from "@/components/meter-form-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getMeter, getMeterServiceHistory, getMeterStats } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Meter, MeterServiceHistoryEntry, MeterServiceStats } from "@/lib/types";

function ServiceStatsCard({ stats }: { stats: MeterServiceStats }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Service Stats</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
          <div>
            <dt className="text-xs text-muted-foreground">Total Services</dt>
            <dd className="text-lg font-semibold">{stats.total_services_count}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Total Revenue</dt>
            <dd className="text-lg font-semibold">৳{stats.total_revenue}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted-foreground">Last Service Date</dt>
            <dd className="text-lg font-semibold">
              {stats.last_service_date ? new Date(stats.last_service_date).toLocaleDateString() : "—"}
            </dd>
          </div>
        </dl>

        {stats.service_breakdown.length === 0 ? (
          <EmptyState icon={Wrench} title="No services performed on this meter yet" />
        ) : (
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Service</TableHead>
                  <TableHead className="text-right">Count</TableHead>
                  <TableHead className="text-right">Revenue</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {stats.service_breakdown.map((row) => (
                  <TableRow key={row.service_name}>
                    <TableCell className="font-medium">{row.service_name}</TableCell>
                    <TableCell className="text-right">{row.count}</TableCell>
                    <TableCell className="text-right">৳{row.revenue}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function ServiceHistoryCard({ history }: { history: MeterServiceHistoryEntry[] }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Service History</CardTitle>
      </CardHeader>
      <CardContent>
        {history.length === 0 ? (
          <EmptyState icon={Wrench} title="No visits recorded for this meter yet" />
        ) : (
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Invoice</TableHead>
                  <TableHead>Serial</TableHead>
                  <TableHead>Condition</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {history.map((entry) => (
                  <TableRow key={entry.id}>
                    <TableCell className="text-muted-foreground">
                      {new Date(entry.service_date).toLocaleDateString()}
                    </TableCell>
                    <TableCell>
                      <Link href={`/invoices/${entry.invoice_id}`} className="font-medium hover:underline">
                        {entry.invoice_no}
                      </Link>
                      <p className="text-xs text-muted-foreground">{entry.customer_name}</p>
                    </TableCell>
                    <TableCell className="text-muted-foreground">{entry.serial_number ?? "—"}</TableCell>
                    <TableCell>
                      <ConditionNoteBadges conditions={entry.condition_note} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

export default function MeterDetailPage() {
  const params = useParams<{ id: string }>();
  const meterId = Number(params.id);

  const [meter, setMeter] = useState<Meter | null>(null);
  const [stats, setStats] = useState<MeterServiceStats | null>(null);
  const [history, setHistory] = useState<MeterServiceHistoryEntry[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([getMeter(meterId), getMeterStats(meterId), getMeterServiceHistory(meterId)])
      .then(([meterResult, statsResult, historyResult]) => {
        setMeter(meterResult);
        setStats(statsResult);
        setHistory(historyResult);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this meter."));
      });
  }, [meterId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!meter || !stats || !history) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link href="/meters" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to meters
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{meter.title}</CardTitle>
            <Badge variant="outline">{meter.memory_type}</Badge>
          </div>
          <MeterFormDialog
            meter={meter}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 sm:flex-row">
            <ImageThumbnail src={meter.image} alt={meter.title} size="lg" />
            <dl className="grid flex-1 grid-cols-2 gap-3 text-sm sm:grid-cols-4">
              <div>
                <dt className="text-xs text-muted-foreground">Brand</dt>
                <dd>{meter.brand}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Model</dt>
                <dd>{meter.model}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">CC</dt>
                <dd>{meter.cc}cc</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">IC/MCU Model</dt>
                <dd>{meter.ic_mcu_model}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Sales Price</dt>
                <dd>৳{meter.sales_price}</dd>
              </div>
            </dl>
          </div>
          {meter.description && (
            <div>
              <dt className="mb-1 text-xs text-muted-foreground">Description</dt>
              <dd className="text-sm">{meter.description}</dd>
            </div>
          )}
        </CardContent>
      </Card>

      <ServiceStatsCard stats={stats} />
      <ServiceHistoryCard history={history} />
    </div>
  );
}
