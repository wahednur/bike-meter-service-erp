from decimal import Decimal

from django.db.models import Sum


def compute_asset_stats(asset):
    """An Asset (tool/accessory) isn't referenced anywhere on an invoice
    line - unlike a MileageCorrectionDevice, there's no data linking it to
    specific billed revenue, so total_revenue_generated is honestly 0/not
    tracked rather than guessed. What IS real: repair/damage costs (rule:
    "Add damage/repair tracking") add to the total cost sunk into the
    asset, which is what it actually needs to "recover".
    """
    total_incident_cost = asset.incidents.aggregate(total=Sum("cost"))["total"] or Decimal("0")
    total_cost_incurred = asset.purchase_price + total_incident_cost
    total_revenue_generated = Decimal("0")

    return {
        "total_incident_cost": total_incident_cost,
        "total_cost_incurred": total_cost_incurred,
        "total_revenue_generated": total_revenue_generated,
        "cost_recovered": total_revenue_generated >= total_cost_incurred,
    }


def _profit_loss_status(profit_loss):
    if profit_loss > 0:
        return "PROFIT"
    if profit_loss < 0:
        return "LOSS"
    return "BREAK_EVEN"


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
            "profit_loss": profit_loss,
            "status": _profit_loss_status(profit_loss),
            "cost_recovered": stats["cost_recovered"],
        })

    for device in MileageCorrectionDevice.objects.all():
        stats = compute_mileage_correction_device_stats(device)
        profit_loss = stats["total_revenue_generated"] - device.purchase_price
        rows.append({
            "type": "mileage_correction_device",
            "id": device.id,
            "name": device.name,
            "purchase_price": device.purchase_price,
            "total_incident_cost": Decimal("0"),
            "total_cost_incurred": device.purchase_price,
            "total_revenue": stats["total_revenue_generated"],
            "profit_loss": profit_loss,
            "status": _profit_loss_status(profit_loss),
            "cost_recovered": stats["cost_recovered"],
        })

    return rows
