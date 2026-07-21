from django.db import models

from apps.common.models import BaseModel


class Meter(BaseModel):
    """A meter/speedometer product (e.g. Bajaj Discover 125's meter unit)."""

    class MemoryType(models.TextChoices):
        EEPROM = "EEPROM", "EEPROM"
        MCU = "MCU", "MCU"

    # Business rule: which physical devices can perform a mileage correction,
    # keyed by memory_type. MCU meters can only be corrected with VVDI Prog;
    # EEPROM meters allow any of the listed programmers. Invoice-time
    # enforcement comes later - this is the single source of truth both the
    # model and the serializer validation method rely on.
    ALLOWED_CORRECTION_TOOLS = {
        MemoryType.MCU: ["VVDI Prog"],
        MemoryType.EEPROM: ["RT809F", "TOP2013", "UPA USB 1.3", "EasyPro2025"],
    }

    brand = models.CharField(max_length=100)
    model = models.CharField(max_length=100)
    cc = models.PositiveIntegerField()
    memory_type = models.CharField(max_length=10, choices=MemoryType.choices)
    ic_mcu_model = models.CharField(max_length=100)
    sales_price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to="meters/", null=True, blank=True)

    class Meta:
        ordering = ["brand", "model"]

    def __str__(self):
        return self.title

    @property
    def title(self):
        return f"{self.brand} {self.model} {self.cc}cc"

    def allowed_correction_tools(self):
        return self.ALLOWED_CORRECTION_TOOLS.get(self.memory_type, [])


class MileageCorrectionDevice(BaseModel):
    """A physical programmer (e.g. VVDI Prog, RT809F) used to perform
    mileage corrections. Names here should line up with the tool strings in
    Meter.ALLOWED_CORRECTION_TOOLS, since invoice-time validation will match
    against them."""

    class MemoryTypeSupport(models.TextChoices):
        EEPROM = "EEPROM", "EEPROM"
        MCU = "MCU", "MCU"
        BOTH = "BOTH", "Both"

    name = models.CharField(max_length=100, unique=True)
    purchase_price = models.DecimalField(max_digits=10, decimal_places=2)
    purchase_date = models.DateField()
    memory_type_support = models.CharField(max_length=10, choices=MemoryTypeSupport.choices)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name
