import { Badge } from "@/components/ui/badge";

export function CostRecoveryBadge({
  recovered,
  hasUsage = true,
}: {
  recovered: boolean;
  /** False means this asset/device has never been tagged on a billed
   * invoice line - distinct from "tagged, but earned ৳0 so far". Showing
   * "Not recovered" in that case would wrongly imply real usage data. */
  hasUsage?: boolean;
}) {
  if (!hasUsage) {
    return (
      <Badge variant="outline" className="text-muted-foreground">
        Not yet linked
      </Badge>
    );
  }

  return recovered ? (
    <Badge className="border-transparent bg-green-500/10 text-green-600 dark:bg-green-500/20 dark:text-green-400">
      Recovered
    </Badge>
  ) : (
    <Badge className="border-transparent bg-amber-500/10 text-amber-600 dark:bg-amber-500/20 dark:text-amber-400">
      Not recovered
    </Badge>
  );
}
