"use client";

import { Landmark, Plus, Search } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ListPagination } from "@/components/list-pagination";
import { LoanFormDialog } from "@/components/loan-form-dialog";
import { RowActions } from "@/components/row-actions";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Progress } from "@/components/ui/progress";
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
import { deleteLoan, listLoans } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Loan } from "@/lib/types";

function matchesQuery(loan: Loan, query: string) {
  return loan.lender_name.toLowerCase().includes(query);
}

export default function LoansPage() {
  const [loans, setLoans] = useState<Loan[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [editingLoan, setEditingLoan] = useState<Loan | null>(null);

  const loadLoans = useCallback(() => {
    listLoans()
      .then(setLoans)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load loans."));
      });
  }, []);

  useEffect(() => {
    loadLoans();
  }, [loadLoans]);

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    loans ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Loans</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage loans and installments.</p>
        </div>
        <LoanFormDialog
          trigger={
            <Button type="button" className="text-white">
              <Plus /> Add Loan
            </Button>
          }
          onSaved={loadLoans}
        />
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by lender name..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!loans && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : loans && loans.length === 0 ? (
        <EmptyState
          icon={Landmark}
          title="No loans yet"
          description="Add your first loan to get started."
          action={
            <LoanFormDialog
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Loan
                </Button>
              }
              onSaved={loadLoans}
            />
          }
        />
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Lender</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead className="text-right">Total Payable</TableHead>
                  <TableHead className="w-48">Installments</TableHead>
                  <TableHead className="text-right">Remaining</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-muted-foreground">
                      No loans match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((loan) => {
                    const progress =
                      loan.total_installments > 0
                        ? (loan.installments_paid_count / loan.total_installments) * 100
                        : 0;
                    return (
                      <TableRow key={loan.id} className="cursor-pointer">
                        <TableCell className="font-medium">
                          <Link href={`/loans/${loan.id}`} className="block">
                            {loan.lender_name}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <Link href={`/loans/${loan.id}`} className="block">
                            <Badge variant="outline">{loan.lender_type}</Badge>
                          </Link>
                        </TableCell>
                        <TableCell className="text-right">
                          <Link href={`/loans/${loan.id}`} className="block">
                            ৳{loan.total_payable}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <Link href={`/loans/${loan.id}`} className="block space-y-1">
                            <Progress value={progress} />
                            <span className="text-xs text-muted-foreground">
                              {loan.installments_paid_count} / {loan.total_installments}
                            </span>
                          </Link>
                        </TableCell>
                        <TableCell className="text-right">
                          <Link href={`/loans/${loan.id}`} className="block">
                            ৳{loan.amount_remaining}
                          </Link>
                        </TableCell>
                        <TableCell>
                          <RowActions
                            resourceLabel="Loan"
                            onEdit={() => setEditingLoan(loan)}
                            onDelete={() =>
                              deleteLoan(loan.id).then(() =>
                                setLoans((prev) => prev?.filter((item) => item.id !== loan.id) ?? prev),
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

      <LoanFormDialog
        loan={editingLoan ?? undefined}
        open={editingLoan !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingLoan(null);
        }}
        onSaved={loadLoans}
      />
    </div>
  );
}
