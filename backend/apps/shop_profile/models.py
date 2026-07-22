from django.db import models

from apps.common.models import BaseModel


class ShopProfile(BaseModel):
    """Singleton settings row - shop details shown on invoices/printouts.
    Always load/save through ShopProfile.load(), which pins the row to
    pk=1 so there's only ever one, instead of trusting callers to look it
    up correctly."""

    shop_name = models.CharField(max_length=150, default="Nurain Motorcycle Meter Service Center")
    address = models.TextField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    invoice_footer_text = models.CharField(max_length=255, default="Development by Wahed Nur")

    class Meta:
        verbose_name = "Shop Profile"
        verbose_name_plural = "Shop Profile"

    def __str__(self):
        return self.shop_name

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        # Singleton settings row - never actually removable via the API;
        # a stray delete() call (e.g. from the admin) is a no-op.
        pass

    @classmethod
    def load(cls, user=None):
        obj, _ = cls.objects.get_or_create(pk=1, defaults={"created_by": user})
        return obj
