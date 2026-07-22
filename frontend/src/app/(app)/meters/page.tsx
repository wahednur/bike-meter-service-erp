"use client";

import { Gauge, Plus, Search } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ImageThumbnail } from "@/components/image-thumbnail";
import { ListPagination } from "@/components/list-pagination";
import { MeterFormDialog } from "@/components/meter-form-dialog";
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
import { deleteMeter, listMeters } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Meter } from "@/lib/types";

function matchesQuery(meter: Meter, query: string) {
  return (
    meter.title.toLowerCase().includes(query) ||
    meter.brand.toLowerCase().includes(query) ||
    meter.model.toLowerCase().includes(query) ||
    meter.ic_mcu_model.toLowerCase().includes(query)
  );
}

export default function MetersPage() {
  const [meters, setMeters] = useState<Meter[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [editingMeter, setEditingMeter] = useState<Meter | null>(null);

  const loadMeters = useCallback(() => {
    listMeters()
      .then(setMeters)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load meters."));
      });
  }, []);

  useEffect(() => {
    loadMeters();
  }, [loadMeters]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    meters ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Meters</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage meter records.</p>
        </div>
        <MeterFormDialog
          trigger={
            <Button type="button">
              <Plus /> Add Meter
            </Button>
          }
          onSaved={loadMeters}
        />
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by brand, model, or IC/MCU..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!meters && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : meters && meters.length === 0 ? (
        <EmptyState
          icon={Gauge}
          title="No meters yet"
          description="Add your first meter to get started."
          action={
            <MeterFormDialog
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Meter
                </Button>
              }
              onSaved={loadMeters}
            />
          }
        />
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Title</TableHead>
                  <TableHead>Brand</TableHead>
                  <TableHead>Model</TableHead>
                  <TableHead>CC</TableHead>
                  <TableHead>Memory Type</TableHead>
                  <TableHead>IC/MCU Model</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center text-muted-foreground">
                      No meters match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((meter) => (
                    <TableRow key={meter.id} className="cursor-pointer">
                      <TableCell className="font-medium">
                        <Link href={`/meters/${meter.id}`} className="flex items-center gap-2">
                          <ImageThumbnail src={meter.image} alt={meter.title} size="sm" />
                          {meter.title}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/meters/${meter.id}`} className="block">
                          {meter.brand}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/meters/${meter.id}`} className="block">
                          {meter.model}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/meters/${meter.id}`} className="block">
                          {meter.cc}cc
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/meters/${meter.id}`} className="block">
                          <Badge variant="outline">{meter.memory_type}</Badge>
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/meters/${meter.id}`} className="block text-muted-foreground">
                          {meter.ic_mcu_model}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <RowActions
                          resourceLabel="Meter"
                          onEdit={() => setEditingMeter(meter)}
                          onDelete={() =>
                            deleteMeter(meter.id).then(() =>
                              setMeters((prev) => prev?.filter((item) => item.id !== meter.id) ?? prev),
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

      <MeterFormDialog
        meter={editingMeter ?? undefined}
        open={editingMeter !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingMeter(null);
        }}
        onSaved={loadMeters}
      />
    </div>
  );
}
