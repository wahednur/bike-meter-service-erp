"use client";

import { Package, PackagePlus, Plus, Search, ShoppingCart } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";

import { EmptyState } from "@/components/empty-state";
import { ImageThumbnail } from "@/components/image-thumbnail";
import { ListPagination } from "@/components/list-pagination";
import { NewPurchaseDialog } from "@/components/new-purchase-dialog";
import { ProductFormDialog } from "@/components/product-form-dialog";
import { RestockDialog } from "@/components/restock-dialog";
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
import { deleteProduct, listProducts, listSuppliers } from "@/lib/api";
import { reportError } from "@/lib/errors";
import type { ProductItem, Supplier } from "@/lib/types";

const LOW_STOCK_THRESHOLD = 5;

function matchesQuery(product: ProductItem, query: string) {
  return product.name.toLowerCase().includes(query) || product.sku.toLowerCase().includes(query);
}

export default function ProductsPage() {
  const [products, setProducts] = useState<ProductItem[] | null>(null);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [editingProduct, setEditingProduct] = useState<ProductItem | null>(null);

  const loadProducts = useCallback(() => {
    listProducts()
      .then(setProducts)
      .catch((err: unknown) => {
        setError(reportError(err, "Failed to load products."));
      });
  }, []);

  useEffect(() => {
    loadProducts();
    listSuppliers()
      .then(setSuppliers)
      .catch(() => {
        // suppliers are only needed for the add/edit dropdown - a failure
        // here shouldn't block viewing the product list itself
      });
  }, [loadProducts]);

  const supplierById = new Map(suppliers.map((supplier) => [supplier.id, supplier.name]));

  const { search, setSearch, page, setPage, totalPages, pageItems, totalCount } = usePaginatedList(
    products ?? [],
    matchesQuery,
  );

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-xl font-semibold">Products</h1>
          <p className="text-sm text-muted-foreground">Browse, search, and manage product inventory.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <NewPurchaseDialog
            suppliers={suppliers}
            products={products ?? []}
            trigger={
              <Button type="button" variant="outline">
                <ShoppingCart /> New Purchase
              </Button>
            }
            onSaved={loadProducts}
          />
          <ProductFormDialog
            suppliers={suppliers}
            trigger={
              <Button type="button">
                <Plus /> Add Product
              </Button>
            }
            onSaved={loadProducts}
          />
        </div>
      </div>

      <div className="relative max-w-sm">
        <Search className="pointer-events-none absolute top-1/2 left-2.5 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-8"
          placeholder="Search by name or SKU..."
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
      </div>

      {error && <p className="rounded-md bg-destructive/10 px-4 py-3 text-sm text-destructive">{error}</p>}

      {!products && !error ? (
        <Skeleton className="h-64 w-full" />
      ) : products && products.length === 0 ? (
        <EmptyState
          icon={Package}
          title="No products yet"
          description="Add your first product to get started."
          action={
            <ProductFormDialog
              suppliers={suppliers}
              trigger={
                <Button type="button" variant="outline">
                  <Plus /> Add Product
                </Button>
              }
              onSaved={loadProducts}
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
                  <TableHead>SKU</TableHead>
                  <TableHead>Supplier</TableHead>
                  <TableHead className="text-right">Buy Price</TableHead>
                  <TableHead className="text-right">Sale Price</TableHead>
                  <TableHead className="text-right">Stock</TableHead>
                  <TableHead className="text-right">Add Stock</TableHead>
                  <TableHead className="w-12" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageItems.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={8} className="text-center text-muted-foreground">
                      No products match your search.
                    </TableCell>
                  </TableRow>
                ) : (
                  pageItems.map((product) => (
                    <TableRow key={product.id}>
                      <TableCell className="font-medium">
                        <Link href={`/products/${product.id}`} className="flex items-center gap-2">
                          <ImageThumbnail src={product.image} alt={product.name} size="sm" />
                          {product.name}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/products/${product.id}`} className="block text-muted-foreground">
                          {product.sku}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <Link href={`/products/${product.id}`} className="block text-muted-foreground">
                          {supplierById.get(product.supplier) ?? "—"}
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/products/${product.id}`} className="block">
                          ৳{product.buy_price}
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/products/${product.id}`} className="block">
                          ৳{product.sale_price}
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <Link href={`/products/${product.id}`} className="block">
                          {product.current_stock_quantity <= LOW_STOCK_THRESHOLD ? (
                            <Badge variant="destructive">{product.current_stock_quantity} left</Badge>
                          ) : (
                            product.current_stock_quantity
                          )}
                        </Link>
                      </TableCell>
                      <TableCell className="text-right">
                        <RestockDialog
                          product={product}
                          trigger={
                            <Button type="button" variant="outline" size="icon-sm" title="Add stock">
                              <PackagePlus />
                            </Button>
                          }
                          onSaved={loadProducts}
                        />
                      </TableCell>
                      <TableCell>
                        <RowActions
                          resourceLabel="Product"
                          onEdit={() => setEditingProduct(product)}
                          onDelete={() =>
                            deleteProduct(product.id).then(() =>
                              setProducts((prev) => prev?.filter((item) => item.id !== product.id) ?? prev),
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

      <ProductFormDialog
        product={editingProduct ?? undefined}
        suppliers={suppliers}
        open={editingProduct !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setEditingProduct(null);
        }}
        onSaved={loadProducts}
      />
    </div>
  );
}
