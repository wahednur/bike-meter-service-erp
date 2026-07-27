import { Badge } from "@/components/ui/badge";

/** Small badges/chips for InvoiceMeterEntry.condition_note - reused
 * wherever a meter entry's recorded conditions are shown (invoice detail,
 * public invoice view, meter service history). Renders nothing for an
 * empty/missing list rather than an empty row. */
export function ConditionNoteBadges({ conditions }: { conditions: string[] | null | undefined }) {
  if (!conditions || conditions.length === 0) return null;
  return (
    <div className="flex flex-wrap gap-1">
      {conditions.map((condition) => (
        <Badge key={condition} variant="outline" className="text-xs font-normal">
          {condition}
        </Badge>
      ))}
    </div>
  );
}
