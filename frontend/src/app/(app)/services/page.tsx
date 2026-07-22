"use client";

import { Plus, Search, Wrench } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ImageThumbnail } from "@/components/image-thumbnail";
import { ListPagination } from "@/components/list-pagination";
import { RowActions } from "@/components/row-actions";
import { ServiceFormDialog } from "@/components/service-form-dialog";
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
import { deleteService, listServiceCategories, listServices } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ServiceCategory, ServiceItem } from "@/lib/types";

function matchesQuery(service: ServiceItem, query: string) {
  return service.name.toLowerCase().includes(query) || service.category_name.toLowerCase().includes(query);
}

export default function ServicesPage() {
  const [services, setServices] = useState<ServiceItem[] | null>(null);
  const [categories, setCategories] = useState<ServiceCategory[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [editingService, setEditingService] = useState<ServiceItem | null>(null);

  const loadServices = useCallback(() => {
    listServices()
      .then(setServices)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load services."));
      });
  }, []);

  useEffect(() => {
    loadServices();
    listServiceCategories()
      .then(setCategories)
      .catch(() => {
        // categories are only needed for the add/edit dropdown - a failure
        // here shouldn't block viewing the service list itself
      });
  }, [loadServices]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    services ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Services</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage service records.</p>
        </div>
        <ServiceFormDialog
          categories={categories}
          trigger={
            <Button type="button">
              <Plus /> Add Service
            </Button>
          }
          onSaved={loadServices}
        />
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by name or category..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!services && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : services && services.length === 0 ? (
        <EmptyState
          icon={Wrench}
          title="No services yet"
          description="Add your first service to get started."
          action={
            <ServiceFormDialog
              categories={categories}
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Service
                </Button>
              }
              onSaved={loadServices}
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
                  <TableHead>Category</TableHead>
                  <TableHead className="text-right">Price</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center text-muted-foreground">
                      No services match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((service) => (
                    <TableRow key={service.id} className="cursor-pointer">
                      <TableCell className="font-medium">
                        <Link href={`/services/${service.id}`} className="flex items-center gap-2">
                          <ImageThumbnail src={service.image} alt={service.name} size="sm" />
                          {service.name}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/services/${service.id}`} className="block">
                          <Badge variant="outline">{service.category_name}</Badge>
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/services/${service.id}`} className="block">
                          ৳{service.service_price}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <RowActions
                          resourceLabel="Service"
                          onEdit={() => setEditingService(service)}
                          onDelete={() =>
                            deleteService(service.id).then(() =>
                              setServices((prev) => prev?.filter((item) => item.id !== service.id) ?? prev),
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

      <ServiceFormDialog
        service={editingService ?? undefined}
        categories={categories}
        open={editingService !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingService(null);
        }}
        onSaved={loadServices}
      />
    </div>
  );
}
