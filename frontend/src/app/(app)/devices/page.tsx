"use client";

import { Plus, Search, Wand2 } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { CostRecoveryBadge } from "@/components/cost-recovery-badge";
import { DeviceFormDialog } from "@/components/device-form-dialog";
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
import { deleteMileageCorrectionDevice, listMileageCorrectionDevices } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { MileageCorrectionDevice } from "@/lib/types";

function matchesQuery(device: MileageCorrectionDevice, query: string) {
  return device.name.toLowerCase().includes(query);
}

export default function DevicesPage() {
  const [devices, setDevices] = useState<MileageCorrectionDevice[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [editingDevice, setEditingDevice] = useState<MileageCorrectionDevice | null>(null);

  const loadDevices = useCallback(() => {
    listMileageCorrectionDevices()
      .then(setDevices)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load mileage correction devices."));
      });
  }, []);

  useEffect(() => {
    loadDevices();
  }, [loadDevices]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    devices ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Mileage Correction Devices</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage correction devices.</p>
        </div>
        <DeviceFormDialog
          trigger={
            <Button type="button">
              <Plus /> Add Device
            </Button>
          }
          onSaved={loadDevices}
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

      {!devices && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : devices && devices.length === 0 ? (
        <EmptyState
          icon={Wand2}
          title="No devices yet"
          description="Add your first mileage correction device to get started."
          action={
            <DeviceFormDialog
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Device
                </Button>
              }
              onSaved={loadDevices}
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
                  <TableHead>Memory Type Support</TableHead>
                  <TableHead className="text-right">Purchase Price</TableHead>
                  <TableHead className="text-right">Revenue Generated</TableHead>
                  <TableHead>Cost Recovery</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-muted-foreground">
                      No devices match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((device) => (
                    <TableRow key={device.id} className="cursor-pointer">
                      <TableCell className="font-medium">
                        <Link href={`/devices/${device.id}`} className="block">
                          {device.name}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/devices/${device.id}`} className="block">
                          <Badge variant="outline">{device.memory_type_support}</Badge>
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/devices/${device.id}`} className="block">
                          ৳{device.purchase_price}
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/devices/${device.id}`} className="block text-muted-foreground">
                          ৳{device.total_revenue_generated}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/devices/${device.id}`} className="block">
                          <CostRecoveryBadge recovered={device.cost_recovered} hasUsage={device.total_jobs_count > 0} />
                        </Link>
                      </TableCell>
                      <TableCell>
                        <RowActions
                          resourceLabel="Device"
                          onEdit={() => setEditingDevice(device)}
                          onDelete={() =>
                            deleteMileageCorrectionDevice(device.id).then(() =>
                              setDevices((prev) => prev?.filter((item) => item.id !== device.id) ?? prev),
                            )
                          }
                        />
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
          <ListPagination page={page} totalPages={totalPages} totalCount={totalCount} onPageChange={setPage} />
        </>
      )}

      <DeviceFormDialog
        device={editingDevice ?? undefined}
        open={editingDevice !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingDevice(null);
        }}
        onSaved={loadDevices}
      />
    </div>
  );
}
