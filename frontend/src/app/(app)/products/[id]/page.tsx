"use client";

import { ArrowLeft, PackagePlus, Pencil } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { ImageThumbnail } from "@/components/image-thumbnail";
import { ProductFormDialog } from "@/components/product-form-dialog";
import { RestockDialog } from "@/components/restock-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { getProduct, listSuppliers } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ProductItem, Supplier } from "@/lib/types";

const LOW_STOCK_THRESHOLD = 5;

export default function ProductDetailPage() {
  const params = useParams<{ id: string }>();
  const productId = Number(params.id);

  const [product, setProduct] = useState<ProductItem | null>(null);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    Promise.all([getProduct(productId), listSuppliers()])
      .then(([productResult, suppliersResult]) => {
        setProduct(productResult);
        setSuppliers(suppliersResult);
      })
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load this product."));
      });
  }, [productId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>;
  }

  if (!product) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-6 w-48" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  const supplierName = suppliers.find((supplier) => supplier.id === product.supplier)?.name ?? "—";

  return (
    <div className="space-y-4">
      <Link href="/products" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to products
      </Link>

      <Card>
        <CardHeader className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2">
            <CardTitle className="text-xl">{product.name}</CardTitle>
            {product.current_stock_quantity <= LOW_STOCK_THRESHOLD && (
              <Badge variant="destructive">{product.current_stock_quantity} left</Badge>
            )}
          </div>
          <div className="flex flex-wrap gap-2">
            <RestockDialog
              product={product}
              trigger={
                <Button type="button" size="sm">
                  <PackagePlus /> Add Stock
                </Button>
              }
              onSaved={load}
            />
            <ProductFormDialog
              product={product}
              suppliers={suppliers}
              trigger={
                <Button type="button" variant="outline" size="sm">
                  <Pencil /> Edit
                </Button>
              }
              onSaved={load}
            />
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 sm:flex-row">
            <ImageThumbnail src={product.image} alt={product.name} size="lg" />
            <dl className="grid flex-1 grid-cols-2 gap-3 text-sm sm:grid-cols-4">
              <div>
                <dt className="text-xs text-muted-foreground">SKU</dt>
                <dd>{product.sku}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Supplier</dt>
                <dd>{supplierName}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Stock Quantity</dt>
                <dd>{product.current_stock_quantity}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Avg Buy Price</dt>
                <dd>৳{product.buy_price}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Sale Price</dt>
                <dd>৳{product.sale_price}</dd>
              </div>
              <div>
                <dt className="text-xs text-muted-foreground">Profit Margin</dt>
                <dd>৳{product.profit_margin}</dd>
              </div>
            </dl>
          </div>
          {product.description && (
            <div>
              <dt className="mb-1 text-xs text-muted-foreground">Description</dt>
              <dd className="text-sm">{product.description}</dd>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
