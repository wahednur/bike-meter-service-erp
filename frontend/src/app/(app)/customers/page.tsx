"use client";

import { Plus, Search } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { CustomerFormDialog } from "@/components/customer-form-dialog";
import { ListPagination } from "@/components/list-pagination";
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
import { ApiError, listCustomers } from "@/lib/api";
import type { Customer } from "@/lib/types";

function matchesQuery(customer: Customer, query: string) {
  return (
    customer.name.toLowerCase().includes(query) ||
    customer.phone.toLowerCase().includes(query) ||
    (customer.email ?? "").toLowerCase().includes(query)
  );
}

export default function CustomersPage() {
  const [customers, setCustomers] = useState<Customer[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadCustomers = useCallback(() => {
    listCustomers()
      .then(setCustomers)
      .catch((err: unknown) => {
        setError(err instanceof ApiError ? err.message : "Failed to load customers.");
      });
  }, []);

  useEffect(() => {
    loadCustomers();
  }, [loadCustomers]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    customers ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Customers</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage customer records.</p>
        </div>
        <CustomerFormDialog
          trigger={
            <Button type="button">
              <Plus /> Add Customer
            </Button>
          }
          onSaved={loadCustomers}
        />
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by name, phone, or email..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!customers && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : customers && customers.length === 0 ? (
        <p className="text-sm text-muted-foreground">No customers yet.</p>
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center text-muted-foreground">
                      No customers match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((customer) => (
                    <TableRow key={customer.id} className="cursor-pointer">
                      <TableCell className="font-medium">
                        <Link href={`/customers/${customer.id}`} className="block">
                          {customer.name}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/customers/${customer.id}`} className="block">
                          {customer.phone}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/customers/${customer.id}`} className="block text-muted-foreground">
                          {customer.email ?? "—"}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/customers/${customer.id}`} className="block">
                          {customer.is_red_listed ? (
                            <Badge variant="destructive">Red-listed</Badge>
                          ) : (
                            <Badge variant="secondary">Good standing</Badge>
                          )}
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
