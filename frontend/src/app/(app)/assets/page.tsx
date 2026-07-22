"use client";

import { Boxes, Plus, Search } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { AssetFormDialog } from "@/components/asset-form-dialog";
import { CostRecoveryBadge } from "@/components/cost-recovery-badge";
import { EmptyState } from "@/components/empty-state";
import { ListPagination } from "@/components/list-pagination";
import { RowActions } from "@/components/row-actions";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { usePaginatedList } from "@/hooks/use-paginated-list";
import { deleteAsset, getCostRecoveryReport, listAssets, listSuppliers } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Asset, CostRecoveryReportItem, Supplier } from "@/lib/types";

function matchesQuery(asset: Asset, query: string) {
  return asset.name.toLowerCase().includes(query);
}

export default function AssetsPage() {
  const [assets, setAssets] = useState<Asset[] | null>(null);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [recoveryByAssetId, setRecoveryByAssetId] = useState<Map<number, CostRecoveryReportItem>>(new Map());
  const [error, setError] = useState<string | null>(null);
  const [editingAsset, setEditingAsset] = useState<Asset | null>(null);

  const loadAssets = useCallback(() => {
    Promise.all([listAssets(), getCostRecoveryReport()])
      .then(([assetsResult, recoveryResult]) => {
        setAssets(assetsResult);
        setRecoveryByAssetId(
          new Map(recoveryResult.filter((row) => row.type === "asset").map((row) => [row.id, row])),
        );
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load assets."));
      });
  }, []);

  useEffect(() => {
    loadAssets();
    listSuppliers()
      .then(setSuppliers)
      .catch(() => {
        // suppliers are only needed for the add/edit dropdown
      });
  }, [loadAssets]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    assets ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Assets</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage shop assets.</p>
        </div>
        <AssetFormDialog
          suppliers={suppliers}
          trigger={
            <Button type="button" className="text-white">
              <Plus /> Add Asset
            </Button>
          }
          onSaved={loadAssets}
        />
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by name..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!assets && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : assets && assets.length === 0 ? (
        <EmptyState
          icon={Boxes}
          title="No assets yet"
          description="Add your first asset to get started."
          action={
            <AssetFormDialog
              suppliers={suppliers}
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Asset
                </Button>
              }
              onSaved={loadAssets}
            />
          }
        />
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Purchase Date</TableHead>
                  <TableHead className="text-right">Purchase Price</TableHead>
                  <TableHead className="text-right">Revenue</TableHead>
                  <TableHead>Warranty</TableHead>
                  <TableHead>Cost Recovery</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center text-muted-foreground">
                      No assets match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((asset) => {
                    const recovery = recoveryByAssetId.get(asset.id);
                    return (
                      <TableRow key={asset.id} className="cursor-pointer">
                        <TableCell className="font-medium">
                          <Link href={`/assets/${asset.id}`} className="block">
                            {asset.name}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <Link href={`/assets/${asset.id}`} className="block text-muted-foreground">
                            {asset.purchase_date}
                          </Link>
                        </TableCell>
                        <TableCell className="text-right">
                          <Link href={`/assets/${asset.id}`} className="block">
                            ৳{asset.purchase_price}
                          </Link>
                        </TableCell>
                        <TableCell className="text-right">
                          <Link href={`/assets/${asset.id}`} className="block text-muted-foreground">
                            {recovery ? `৳${recovery.total_revenue}` : "—"}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <Link href={`/assets/${asset.id}`} className="block">
                            {asset.has_warranty ? (
                              <Badge variant="outline">Warranty</Badge>
                            ) : (
                              <span className="text-muted-foreground">—</span>
                            )}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <Link href={`/assets/${asset.id}`} className="block">
                            {recovery ? (
                              <CostRecoveryBadge recovered={recovery.cost_recovered} hasUsage={recovery.has_usage} />
                            ) : (
                              <span className="text-muted-foreground">—</span>
                            )}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <RowActions
                            resourceLabel="Asset"
                            onEdit={() => setEditingAsset(asset)}
                            onDelete={() =>
                              deleteAsset(asset.id).then(() =>
                                setAssets((prev) => prev?.filter((item) => item.id !== asset.id) ?? prev),
                              )
                            }
                          />
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
          <ListPagination page={page} totalPages={totalPages} totalCount={totalCount} onPageChange={setPage} />
        </>
      )}

      <AssetFormDialog
        asset={editingAsset ?? undefined}
        suppliers={suppliers}
        open={editingAsset !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingAsset(null);
        }}
        onSaved={loadAssets}
      />
    </div>
  );
}
