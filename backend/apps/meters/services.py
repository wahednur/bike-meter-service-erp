from decimal import Decimal

from django.db.models import Sum


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
