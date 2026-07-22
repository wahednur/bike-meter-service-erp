"use client";

import { ArrowLeft, Pencil, Wrench } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { formatCategoryName, ServiceCategoryFormDialog } from "@/components/service-category-form-dialog";
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
import { getServiceCategory, listServiceCategories, listServices } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ServiceCategory, ServiceItem } from "@/lib/types";

export default function ServiceCategoryDetailPage() {
  const params = useParams<{ id: string }>();
  const categoryId = Number(params.id);

  const [category, setCategory] = useState<ServiceCategory | null>(null);
  const [allCategories, setAllCategories] = useState<ServiceCategory[]>([]);
  const [services, setServices] = useState<ServiceItem[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([getServiceCategory(categoryId), listServiceCategories(), listServices()])
      .then(([categoryResult, categoriesResult, servicesResult]) => {
        setCategory(categoryResult);
        setAllCategories(categoriesResult);
        setServices(servicesResult.filter((service) => service.category === categoryId));
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this category."));
      });
  }, [categoryId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!category || !services) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-64 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link
        href="/service-categories"
        className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> Back to categories
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <CardTitle className="text-xl">{category.name_display || formatCategoryName(category.name)}</CardTitle>
          <ServiceCategoryFormDialog
            category={category}
            existingNames={allCategories.map((item) => item.name)}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Services in this category</CardTitle>
        </CardHeader>
        <CardContent>
          {services.length === 0 ? (
            <EmptyState icon={Wrench} title="No services in this category yet" />
          ) : (
            <div className="rounded-lg border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead className="text-right">Price</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {services.map((service) => (
                    <TableRow key={service.id}>
                      <TableCell className="font-medium">
                        <Link href={`/services/${service.id}`} className="block">
                          {service.name}
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">৳{service.service_price}</TableCell>
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
