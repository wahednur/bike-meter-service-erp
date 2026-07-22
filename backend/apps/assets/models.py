from django.db import models

from apps.common.models import BaseModel
from apps.suppliers.models import Supplier


class Asset(BaseModel):
    """A shop accessory/tool (e.g. a soldering iron, a testing rig) -
    conceptually the same as a Meter app MileageCorrectionDevice (capital
    equipment with a cost to recover), but not tied to a specific billable
    job, so kept in its own app."""

    name = models.CharField(max_length=150)
    purchase_price = models.DecimalField(max_digits=10, decimal_places=2)
    purchase_date = models.DateField()
    supplier = models.ForeignKey(
        Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name="assets",
    )
    has_warranty = models.BooleanField(default=False)
    warranty_note = models.TextField(blank=True)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class AssetIncident(BaseModel):
    """A damage or repair event against an Asset."""

    class Type(models.TextChoices):
        DAMAGED = "DAMAGED", "Damaged"
        REPAIRED = "REPAIRED", "Repaired"

    asset = models.ForeignKey(Asset, on_delete=models.CASCADE, related_name="incidents")
    type = models.CharField(max_length=10, choices=Type.choices)
    cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    date = models.DateField()
    note = models.TextField(blank=True)

    class Meta:
        ordering = ["-date"]

    def __str__(self):
        return f"{self.get_type_display()} - {self.asset.name} ({self.date})"
