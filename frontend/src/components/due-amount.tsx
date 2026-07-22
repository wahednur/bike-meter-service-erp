import { Badge } from "@/components/ui/badge";
import type { InvoiceStatus } from "@/lib/types";

/** Shared "Due Amount" display for the invoice list/detail pages - shows a
 * green "Paid" badge instead of a ৳0 figure once nothing is owed. */
export function DueAmount({ amount, status }: { amount: string; status: InvoiceStatus }) {
  const isSettled = status === "PAID" || Number(amount) <= 0;

  if (isSettled) {
    return (
      <Badge className="border-transparent bg-green-500/10 text-green-600 dark:bg-green-500/20 dark:text-green-400">
        Paid
      </Badge>
    );
  }

  return <span className="font-medium text-destructive">৳{amount}</span>;
}
