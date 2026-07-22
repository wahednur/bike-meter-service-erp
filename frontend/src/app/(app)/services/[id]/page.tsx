"use client";

import { ArrowLeft, Pencil } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { ImageThumbnail } from "@/components/image-thumbnail";
import { ServiceFormDialog } from "@/components/service-form-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { getService, listServiceCategories } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ServiceCategory, ServiceItem } from "@/lib/types";

export default function ServiceDetailPage() {
  const params = useParams<{ id: string }>();
  const serviceId = Number(params.id);

  const [service, setService] = useState<ServiceItem | null>(null);
  const [categories, setCategories] = useState<ServiceCategory[]>([]);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([getService(serviceId), listServiceCategories()])
      .then(([serviceResult, categoriesResult]) => {
        setService(serviceResult);
        setCategories(categoriesResult);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this service."));
      });
  }, [serviceId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!service) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Link href="/services" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to services
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{service.name}</CardTitle>
            <Badge variant="outline">{service.category_name}</Badge>
          </div>
          <ServiceFormDialog
            service={service}
            categories={categories}
            trigger={
              <Button type="button" variant="outline" size="sm">
                <Pencil /> Edit
              </Button>
            }
            onSaved={load}
          />
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 sm:flex-row">
            <ImageThumbnail src={service.image} alt={service.name} size="lg" />
            <dl className="grid flex-1 grid-cols-2 gap-3 text-sm sm:grid-cols-3">
              <div>
                <dt className="text-xs text-muted-foreground">Price</dt>
                <dd className="text-lg font-semibold">৳{service.service_price}</dd>
              </div>
            </dl>
          </div>
          {service.description && (
            <div>
              <dt className="mb-1 text-xs text-muted-foreground">Description</dt>
              <dd className="text-sm">{service.description}</dd>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
