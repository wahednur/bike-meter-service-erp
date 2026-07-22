from decimal import Decimal

from django.db.models import Sum


def compute_asset_stats(asset):
    """Real revenue now: every InvoiceServiceLine tagged with this asset via
    its opt-in asset_used FK (see apps.invoices.services.add_service_line()).
    Tagging is optional - not every repair names the specific tool used - so
    zero tagged lines means "not yet linked to any service", which is a
    different, honest thing to report than "generated zero revenue" (that
    would wrongly imply the asset has been used and simply earned nothing).
    `has_usage` lets callers distinguish the two.

    cost_recovered compares against total_cost_incurred (purchase_price +
    incident/repair costs), not raw purchase_price - repairing a damaged
    asset is real money sunk into it that also needs recovering, and this
    keeps cost_recovered consistent with the profit_loss figure computed
    from the same total_cost_incurred in build_cost_recovery_report().
    """
    from apps.invoices.models import InvoiceServiceLine

    total_incident_cost = asset.incidents.aggregate(total=Sum("cost"))["total"] or Decimal("0")
    total_cost_incurred = asset.purchase_price + total_incident_cost

    lines = InvoiceServiceLine.objects.filter(asset_used=asset)
    total_jobs_count = lines.count()
    total_revenue_generated = lines.aggregate(total=Sum("price_charged"))["total"] or Decimal("0")
    has_usage = total_jobs_count > 0

    return {
        "total_incident_cost": total_incident_cost,
        "total_cost_incurred": total_cost_incurred,
        "total_jobs_count": total_jobs_count,
        "total_revenue_generated": total_revenue_generated,
        "has_usage": has_usage,
        "cost_recovered": has_usage and total_revenue_generated >= total_cost_incurred,
    }


def _profit_loss_status(profit_loss):
    if profit_loss > 0:
        return "PROFIT"
    if profit_loss < 0:
        return "LOSS"
    return "BREAK_EVEN"


def _cost_recovery_status(has_usage, profit_loss):
    """NOT_LINKED takes priority over PROFIT/LOSS/BREAK_EVEN: an asset or
    device that's never been tagged/used on a single invoice line would
    otherwise show as "LOSS" (revenue 0 minus a positive cost), which reads
    as "this was a bad purchase" rather than the true "no data yet"."""
    if not has_usage:
        return "NOT_LINKED"
    return _profit_loss_status(profit_loss)


def build_cost_recovery_report():
    """One combined report covering every Asset and every
    MileageCorrectionDevice (Phase 4): purchase_price vs. revenue earned,
    and a profit/loss status for each.
    """
    from apps.assets.models import Asset
    from apps.meters.models import MileageCorrectionDevice
    from apps.meters.services import compute_mileage_correction_device_stats

    rows = []

    for asset in Asset.objects.all():
        stats = compute_asset_stats(asset)
        profit_loss = stats["total_revenue_generated"] - stats["total_cost_incurred"]
        rows.append({
            "type": "asset",
            "id": asset.id,
            "name": asset.name,
            "purchase_price": asset.purchase_price,
            "total_incident_cost": stats["total_incident_cost"],
            "total_cost_incurred": stats["total_cost_incurred"],
            "total_revenue": stats["total_revenue_generated"],
            "total_jobs_count": stats["total_jobs_count"],
            "has_usage": stats["has_usage"],
            "profit_loss": profit_loss,
            "status": _cost_recovery_status(stats["has_usage"], profit_loss),
            "cost_recovered": stats["cost_recovered"],
        })

    for device in MileageCorrectionDevice.objects.all():
        stats = compute_mileage_correction_device_stats(device)
        profit_loss = stats["total_revenue_generated"] - device.purchase_price
        has_usage = stats["total_jobs_count"] > 0
        rows.append({
            "type": "mileage_correction_device",
            "id": device.id,
            "name": device.name,
            "purchase_price": device.purchase_price,
            "total_incident_cost": Decimal("0"),
            "total_cost_incurred": device.purchase_price,
            "total_revenue": stats["total_revenue_generated"],
            "total_jobs_count": stats["total_jobs_count"],
            "has_usage": has_usage,
            "profit_loss": profit_loss,
            "status": _cost_recovery_status(has_usage, profit_loss),
            "cost_recovered": stats["cost_recovered"],
        })

    return rows
