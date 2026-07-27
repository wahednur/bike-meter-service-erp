from decimal import Decimal

from django.db.models import Count, Max, Sum


def compute_meter_service_stats(meter):
    """Real per-meter service history: every InvoiceServiceLine tied to a
    meter entry for this meter, aggregated for totals plus a per-service
    breakdown. Mirrors compute_mileage_correction_device_stats() below.
    """
    from apps.invoices.models import InvoiceServiceLine

    lines = InvoiceServiceLine.objects.filter(meter_entry__meter=meter)
    total_services_count = lines.count()
    total_revenue = lines.aggregate(total=Sum("price_charged"))["total"] or Decimal("0")
    last_service_date = lines.aggregate(latest=Max("meter_entry__service_date"))["latest"]

    breakdown = (
        lines.values("service__name")
        .annotate(count=Count("id"), revenue=Sum("price_charged"))
        .order_by("-count")
    )

    return {
        "total_services_count": total_services_count,
        "total_revenue": total_revenue,
        "last_service_date": last_service_date,
        "service_breakdown": [
            {"service_name": row["service__name"], "count": row["count"], "revenue": row["revenue"]}
            for row in breakdown
        ],
    }


def compute_meter_service_history(meter):
    """Every individual visit this meter has been brought in for, one row
    per InvoiceMeterEntry, newest first. The itemized list behind
    compute_meter_service_stats() above (which only aggregates) - lets the
    frontend show each visit's own recorded condition_note tags."""
    from apps.invoices.models import InvoiceMeterEntry

    entries = (
        InvoiceMeterEntry.objects.filter(meter=meter)
        .select_related("invoice", "invoice__customer")
        .order_by("-service_date")
    )
    return [
        {
            "id": entry.id,
            "invoice_id": entry.invoice_id,
            "invoice_no": entry.invoice.invoice_no,
            "customer_name": entry.invoice.customer.name,
            "serial_number": entry.serial_number,
            "condition_note": entry.condition_note,
            "previous_km": entry.previous_km,
            "current_km": entry.current_km,
            "service_date": entry.service_date,
        }
        for entry in entries
    ]


def compute_mileage_correction_device_stats(device):
    """Now that the Invoice app exists, a device's job count/revenue can be
    computed for real: every InvoiceServiceLine for a Mileage Correction
    service, on a meter entry where this specific device was used.

    (Deferred imports: apps.invoices depends on apps.meters, so importing
    it back here at module load time would be circular - importing inside
    the function, at call time, is safe.)
    """
    from apps.invoices.models import InvoiceServiceLine
    from apps.services.models import ServiceCategory

    lines = InvoiceServiceLine.objects.filter(
        meter_entry__mileage_correction_device=device,
        service__category__name=ServiceCategory.Name.MILEAGE_CORRECTION,
    )
    total_jobs_count = lines.count()
    total_revenue_generated = lines.aggregate(total=Sum("price_charged"))["total"] or Decimal("0")

    return {
        "total_jobs_count": total_jobs_count,
        "total_revenue_generated": total_revenue_generated,
        "cost_recovered": total_revenue_generated >= device.purchase_price,
    }
