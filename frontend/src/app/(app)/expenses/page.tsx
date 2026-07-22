"use client";

import { Plus, Receipt } from "lucide-react";
import { useCallback, useEffect, useState } from "react";

import { DatePickerButton } from "@/components/date-picker-button";
import { EmptyState } from "@/components/empty-state";
import { ExpenseFormDialog } from "@/components/expense-form-dialog";
import { ListPagination } from "@/components/list-pagination";
import { RowActions } from "@/components/row-actions";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { deleteExpense, listExpenses } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { Expense, ExpenseCategory } from "@/lib/types";

const PAGE_SIZE = 15;
const CATEGORY_OPTIONS: { value: ExpenseCategory | "ALL"; label: string }[] = [
  { value: "ALL", label: "All categories" },
  { value: "RENT", label: "Rent" },
  { value: "ELECTRICITY", label: "Electricity" },
  { value: "TRANSPORT", label: "Transport" },
  { value: "MISC", label: "Misc" },
];

export default function ExpensesPage() {
  const [expenses, setExpenses] = useState<Expense[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [editingExpense, setEditingExpense] = useState<Expense | null>(null);

  const [category, setCategory] = useState<ExpenseCategory | "ALL">("ALL");
  const [dateFrom, setDateFrom] = useState<string | undefined>(undefined);
  const [dateTo, setDateTo] = useState<string | undefined>(undefined);

  const loadExpenses = useCallback(() => {
    listExpenses({
      category: category === "ALL" ? undefined : category,
      dateFrom,
      dateTo,
    })
      .then(setExpenses)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load expenses."));
      });
  }, [category, dateFrom, dateTo]);

  useEffect(() => {
    setPage(1);
    loadExpenses();
  }, [loadExpenses]);

  const totalPages = Math.max(1, Math.ceil((expenses?.length ?? 0) / PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const pageItems = (expenses ?? []).slice((currentPage - 1) * PAGE_SIZE, currentPage * PAGE_SIZE);
  const totalAmount = (expenses ?? []).reduce((sum, expense) => sum + Number(expense.amount), 0);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Expenses</h1>
          <p className="text-sm text-muted-foreground">Track shop expenses like rent, electricity, and transport.</p>
        </div>
        <ExpenseFormDialog
          trigger={
            <Button type="button">
              <Plus /> Add Expense
            </Button>
          }
          onSaved={loadExpenses}
        />
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="w-44 space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">Category</label>
          <Select value={category} onValueChange={(value) => setCategory(value as ExpenseCategory | "ALL")}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {CATEGORY_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">From</label>
          <DatePickerButton value={dateFrom} onChange={setDateFrom} placeholder="Any" />
        </div>
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">To</label>
          <DatePickerButton value={dateTo} onChange={setDateTo} placeholder="Any" />
        </div>
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!expenses && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : expenses && expenses.length === 0 ? (
        <EmptyState icon={Receipt} title="No expenses match these filters" />
      ) : (
        <>
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Note</TableHead>
                  <TableHead className="text-right">Amount</TableHead>
                  <TableHead className="w-16" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.map((expense) => (
                  <TableRow key={expense.id}>
                    <TableCell className="text-muted-foreground">{expense.date}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{expense.category_display}</Badge>
                    </TableCell>
                    <TableCell className="max-w-xs truncate text-muted-foreground">{expense.note || "—"}</TableCell>
                    <TableCell className="text-right font-medium">৳{expense.amount}</TableCell>
                    <TableCell>
                      <RowActions
                        resourceLabel="Expense"
                        onEdit={() => setEditingExpense(expense)}
                        onDelete={() =>
                          deleteExpense(expense.id).then(() =>
                            setExpenses((prev) => prev?.filter((item) => item.id !== expense.id) ?? prev),
                          )
                        }
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              Total: <span className="font-medium text-foreground">৳{totalAmount.toFixed(2)}</span>
            </p>
            <ListPagination
              page={currentPage}
              totalPages={totalPages}
              totalCount={expenses?.length ?? 0}
              onPageChange={setPage}
            />
          </div>
        </>
      )}

      <ExpenseFormDialog
        expense={editingExpense ?? undefined}
        open={editingExpense !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingExpense(null);
        }}
        onSaved={loadExpenses}
      />
    </div>
  );
}
