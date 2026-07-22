"use client";

import { ArrowLeft, Pencil } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { CostRecoveryBadge } from "@/components/cost-recovery-badge";
import { DeviceFormDialog } from "@/components/device-form-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { getMileageCorrectionDevice } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { MileageCorrectionDevice } from "@/lib/types";

export default function DeviceDetailPage() {
  const params = useParams<{ id: string }>();
  const deviceId = Number(params.id);

  const [device, setDevice] = useState<MileageCorrectionDevice | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    getMileageCorrectionDevice(deviceId)
      .then(setDevice)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this device."));
      });
  }, [deviceId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!device) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link href="/devices" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to devices
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{device.name}</CardTitle>
            <Badge variant="outline">{device.memory_type_support}</Badge>
            <CostRecoveryBadge recovered={device.cost_recovered} hasUsage={device.total_jobs_count > 0} />
          </div>
          <DeviceFormDialog
            device={device}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
            <div>
              <dt className="text-xs text-muted-foreground">Purchase Price</dt>
              <dd>৳{device.purchase_price}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Purchase Date</dt>
              <dd>{device.purchase_date}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Memory Type Support</dt>
              <dd>{device.memory_type_support}</dd>
            </div>
          </dl>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Cost Recovery</CardTitle>
        </CardHeader>
        <CardContent>
          <dl className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
            <div>
              <dt className="text-xs text-muted-foreground">Total Jobs</dt>
              <dd className="text-lg font-semibold">{device.total_jobs_count}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Revenue Generated</dt>
              <dd className="text-lg font-semibold">৳{device.total_revenue_generated}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Status</dt>
              <dd>
                <CostRecoveryBadge recovered={device.cost_recovered} hasUsage={device.total_jobs_count > 0} />
              </dd>
            </div>
          </dl>
        </CardContent>
      </Card>
    </div>
  );
}
