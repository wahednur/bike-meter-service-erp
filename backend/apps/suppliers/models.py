from django.db import models

from apps.common.models import BaseModel


class Supplier(BaseModel):
    """Suppliers never log in - they only exist as records, created by an
    Admin or permitted Staff."""

    name = models.CharField(max_length=150)
    phone = models.CharField(max_length=20, unique=True)
    address = models.TextField(blank=True)
    note = models.TextField(blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name
