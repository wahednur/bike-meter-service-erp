"use client";

import { Plus, Tags } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { RowActions } from "@/components/row-actions";
import { formatCategoryName, ServiceCategoryFormDialog } from "@/components/service-category-form-dialog";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { deleteServiceCategory, listServiceCategories } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ServiceCategory } from "@/lib/types";

export default function ServiceCategoriesPage() {
  const [categories, setCategories] = useState<ServiceCategory[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [editingCategory, setEditingCategory] = useState<ServiceCategory | null>(null);

  const loadCategories = useCallback(() => {
    listServiceCategories()
      .then(setCategories)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load service categories."));
      });
  }, []);

  useEffect(() => {
    loadCategories();
  }, [loadCategories]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Service Categories</h1>
          <p className="text-sm text-muted-foreground">
            A fixed set of up to 8 categories used to classify services.
          </p>
        </div>
        <ServiceCategoryFormDialog
          existingNames={categories?.map((category) => category.name) ?? []}
          trigger={
            <Button type="button">
              <Plus /> Add Category
            </Button>
          }
          onSaved={loadCategories}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!categories && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : categories && categories.length === 0 ? (
        <EmptyState
          icon={Tags}
          title="No service categories yet"
          description="Add your first category to get started."
          action={
            <ServiceCategoryFormDialog
              existingNames={[]}
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Category
                </Button>
              }
              onSaved={loadCategories}
            />
          }
        />
      ) : (
        <div className="rounded-lg border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Category</TableHead>
                <TableHead>Key</TableHead>
                <TableHead className="w-12" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {categories?.map((category) => (
                <TableRow key={category.id} className="cursor-pointer">
                  <TableCell className="font-medium">
                    <Link href={`/service-categories/${category.id}`} className="block">
                      {category.name_display || formatCategoryName(category.name)}
                    </Link>
                  </TableCell>
                  <TableCell>
                    <Link href={`/service-categories/${category.id}`} className="block text-muted-foreground">
                      {category.name}
                    </Link>
                  </TableCell>
                  <TableCell>
                    <RowActions
                      resourceLabel="Category"
                      onEdit={() => setEditingCategory(category)}
                      onDelete={() =>
                        deleteServiceCategory(category.id).then(() =>
                          setCategories((prev) => prev?.filter((item) => item.id !== category.id) ?? prev),
                        )
                      }
                    />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <ServiceCategoryFormDialog
        category={editingCategory ?? undefined}
        existingNames={categories?.map((category) => category.name) ?? []}
        open={editingCategory !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingCategory(null);
        }}
        onSaved={loadCategories}
      />
    </div>
  );
}
