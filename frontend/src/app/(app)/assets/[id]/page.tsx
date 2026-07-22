"use client";

import { AlertTriangle, ArrowLeft, Pencil, TrendingUp } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { AssetFormDialog } from "@/components/asset-form-dialog";
import { CostRecoveryBadge } from "@/components/cost-recovery-badge";
import { EmptyState } from "@/components/empty-state";
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
import {
  getAsset,
  getCostRecoveryReport,
  listAssetIncidents,
  listSuppliers,
} from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Asset, AssetIncident, CostRecoveryReportItem, Supplier } from "@/lib/types";

export default function AssetDetailPage() {
  const params = useParams<{ id: string }>();
  const assetId = Number(params.id);

  const [asset, setAsset] = useState<Asset | null>(null);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [recovery, setRecovery] = useState<CostRecoveryReportItem | null>(null);
  const [incidents, setIncidents] = useState<AssetIncident[]>([]);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([
      getAsset(assetId),
      getCostRecoveryReport(),
      listAssetIncidents(assetId),
      listSuppliers(),
    ])
      .then(([assetResult, recoveryResult, incidentsResult, suppliersResult]) => {
        setAsset(assetResult);
        setRecovery(recoveryResult.find((row) => row.type === "asset" && row.id === assetId) ?? null);
        setIncidents(incidentsResult);
        setSuppliers(suppliersResult);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this asset."));
      });
  }, [assetId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!asset) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  const supplierName = suppliers.find((supplier) => supplier.id === asset.supplier)?.name ?? "—";

  return (
    <div className="space-y-4">
      <Link href="/assets" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to assets
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{asset.name}</CardTitle>
            {asset.has_warranty && <Badge variant="outline">Warranty</Badge>}
            {recovery && <CostRecoveryBadge recovered={recovery.cost_recovered} hasUsage={recovery.has_usage} />}
          </div>
          <AssetFormDialog
            asset={asset}
            suppliers={suppliers}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
        <CardContent className="space-y-4">
          <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
            <div>
              <dt className="text-xs text-muted-foreground">Purchase Price</dt>
              <dd>৳{asset.purchase_price}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Purchase Date</dt>
              <dd>{asset.purchase_date}</dd>
            </div>
            <div>
              <dt className="text-xs text-muted-foreground">Supplier</dt>
              <dd>{supplierName}</dd>
            </div>
            {asset.has_warranty && asset.warranty_note && (
              <div>
                <dt className="text-xs text-muted-foreground">Warranty Note</dt>
                <dd>{asset.warranty_note}</dd>
              </div>
            )}
          </dl>
          {asset.description && (
            <div>
              <dt className="mb-1 text-xs text-muted-foreground">Description</dt>
              <dd className="text-sm">{asset.description}</dd>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-2 space-y-0">
          <CardTitle>Cost Recovery</CardTitle>
          {recovery && <CostRecoveryBadge recovered={recovery.cost_recovered} hasUsage={recovery.has_usage} />}
        </CardHeader>
        <CardContent>
          {!recovery ? (
            <EmptyState icon={TrendingUp} title="No cost-recovery data available" />
          ) : !recovery.has_usage ? (
            <p className="text-sm text-muted-foreground">
              Not yet linked to any service. Tag this asset as the &quot;Asset used&quot; on a repair&apos;s service
              line to start tracking the revenue it generates.
            </p>
          ) : (
            <dl className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
              <div>
                <dt className="text-xs text-muted-foreground">Purchase Price</dt>
                <dd className="text-lg font-semibold">৳{asset.purchase_price}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Incident Costs</dt>
                <dd className="text-lg font-semibold">৳{recovery.total_incident_cost}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Total Cost Incurred</dt>
                <dd className="text-lg font-semibold">৳{recovery.total_cost_incurred}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Revenue Generated ({recovery.total_jobs_count} job
                  {recovery.total_jobs_count === 1 ? "" : "s"})
                </dt>
                <dd className="text-lg font-semibold">৳{recovery.total_revenue}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Profit / Loss</dt>
                <dd className="text-lg font-semibold">৳{recovery.profit_loss}</dd>
              </div>
            </dl>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Incidents</CardTitle>
        </CardHeader>
        <CardContent>
          {incidents.length === 0 ? (
            <EmptyState icon={AlertTriangle} title="No damage/repair incidents recorded" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Type</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Note</TableHead>
                    <TableHead className="text-right">Cost</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {incidents.map((incident) => (
                    <TableRow key={incident.id}>
                      <TableCell>
                        <Badge variant={incident.type === "DAMAGED" ? "destructive" : "secondary"}>
                          {incident.type === "DAMAGED" ? "Damaged" : "Repaired"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{incident.date}</TableCell>
                      <TableCell className="text-muted-foreground">{incident.note || "—"}</TableCell>
                      <TableCell className="text-right">৳{incident.cost}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
