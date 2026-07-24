from django.db import models

from apps.common.models import BaseModel


class ServiceCategory(BaseModel):
    class Name(models.TextChoices):
        MILEAGE_CORRECTION = "MILEAGE_CORRECTION", "Mileage Correction"
        METER_REPAIR = "METER_REPAIR", "Meter Repair"
        DISPLAY_REPAIR = "DISPLAY_REPAIR", "Display Repair"
        MAIN_BOARD_REPAIR = "MAIN_BOARD_REPAIR", "Main Board Repair"
        LIGHT_REPAIR = "LIGHT_REPAIR", "Light Repair"
        KILOMETER_FREEZE_REPAIR = "KILOMETER_FREEZE_REPAIR", "Kilometer Freeze Repair"
        POWER_PROBLEM_REPAIR = "POWER_PROBLEM_REPAIR", "Power Problem Repair"
        OTHERS = "OTHERS", "Others"

    name = models.CharField(max_length=30, choices=Name.choices, unique=True)

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "service categories"

    def __str__(self):
        return self.get_name_display()


class Service(BaseModel):
    """A billable repair/service (e.g. "LED IC problem" repair, "Mileage
    Correction"). Belongs to a ServiceCategory."""

    category = models.ForeignKey(ServiceCategory, on_delete=models.PROTECT, related_name="services")
    name = models.CharField(max_length=150)
    service_price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to="services/", null=True, blank=True)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["category__name", "name"]

    def __str__(self):
        return self.name

    @property
    def requires_mileage_correction_fields(self):
        """When this service is added to an invoice, meter_condition_note
        becomes required (previous_km/current_km stay optional). Enforced
        by ServiceSerializer.validate_invoice_line_fields, called from
        apps.invoices.services."""
        return self.category.name == ServiceCategory.Name.MILEAGE_CORRECTION
