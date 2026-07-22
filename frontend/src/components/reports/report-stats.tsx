export function ReportStats({ items }: { items: { label: string; value: string }[] }) {
  return (
    <dl className="grid grid-cols-2 gap-4 rounded-lg border p-4 sm:grid-cols-4">
      {items.map((item) => (
        <div key={item.label}>
          <dt className="text-xs text-muted-foreground uppercase">{item.label}</dt>
          <dd className="text-lg font-semibold">{item.value}</dd>
        </div>
      ))}
    </dl>
  );
}
