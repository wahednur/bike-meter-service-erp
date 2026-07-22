import { Badge } from "@/components/ui/badge";
import type { InvoiceStatus } from "@/lib/types";

export function InvoiceStatusBadge({ status }: { status: InvoiceStatus }) {
  switch (status) {
    case "UNPAID":
      return <Badge variant="destructive">Unpaid</Badge>;
    case "PARTIAL":
      return (
        <Badge className="border-transparent bg-amber-500/10 text-amber-600 dark:bg-amber-500/20 dark:text-amber-400">
          Partial Paid
        </Badge>
      );
    case "PAID":
      return (
        <Badge className="border-transparent bg-green-500/10 text-green-600 dark:bg-green-500/20 dark:text-green-400">
          Paid
        </Badge>
      );
    case "CANCELLED":
      return <Badge variant="secondary">Cancelled</Badge>;
  }
}
