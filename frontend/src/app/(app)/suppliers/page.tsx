"use client";

import { Plus, Search } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { ListPagination } from "@/components/list-pagination";
import { SupplierFormDialog } from "@/components/supplier-form-dialog";
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
import { ApiError, listSuppliers } from "@/lib/api";
import type { Supplier } from "@/lib/types";

function matchesQuery(supplier: Supplier, query: string) {
  return supplier.name.toLowerCase().includes(query) || supplier.phone.toLowerCase().includes(query);
}

export default function SuppliersPage() {
  const [suppliers, setSuppliers] = useState<Supplier[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadSuppliers = useCallback(() => {
    listSuppliers()
      .then(setSuppliers)
      .catch((err: unknown) => {
        setError(err instanceof ApiError ? err.message : "Failed to load suppliers.");
      });
  }, []);

  useEffect(() => {
    loadSuppliers();
  }, [loadSuppliers]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    suppliers ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Suppliers</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage supplier records.</p>
        </div>
        <SupplierFormDialog
          trigger={
            <Button type="button">
              <Plus /> Add Supplier
            </Button>
          }
          onSaved={loadSuppliers}
        />
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by name or phone..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!suppliers && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : suppliers && suppliers.length === 0 ? (
        <p className="text-sm text-muted-foreground">No suppliers yet.</p>
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Address</TableHead>
                  <TableHead>Note</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center text-muted-foreground">
                      No suppliers match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((supplier) => (
                    <TableRow key={supplier.id} className="cursor-pointer">
                      <TableCell className="font-medium">
                        <Link href={`/suppliers/${supplier.id}`} className="block">
                          {supplier.name}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/suppliers/${supplier.id}`} className="block">
                          {supplier.phone}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/suppliers/${supplier.id}`} className="block text-muted-foreground">
                          {supplier.address || "—"}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link
                          href={`/suppliers/${supplier.id}`}
                          className="block max-w-xs truncate text-muted-foreground"
                        >
                          {supplier.note || "—"}
                        </Link>
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
    </div>
  );
}
