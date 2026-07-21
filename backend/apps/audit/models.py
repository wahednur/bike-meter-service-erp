from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models

from apps.common.models import BaseModel


class AuditLogEntry(BaseModel):
    """Generic 'who did what, when' trail for any model. BaseModel's
    created_by/created_at already cover who/when - this adds what happened
    and to which record, via a generic FK so any app can log against it."""

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveBigIntegerField()
    content_object = GenericForeignKey("content_type", "object_id")

    action = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["content_type", "object_id"])]

    def __str__(self):
        return f"{self.action} on {self.content_type} #{self.object_id}"


class AuditLog(BaseModel):
    """Automatic create/update/delete trail for every business-app model -
    populated entirely by signal handlers (apps.audit.signals), no per-app
    logging code required. BaseModel's created_by/created_at are who
    performed the tracked action and when (consistent with AuditLogEntry).

    Distinct from AuditLogEntry above: that one is a hand-curated log of
    specific business events (e.g. "payment_added") written explicitly by
    the invoices app; this one is a blanket, automatic technical CRUD trail
    that fires for every tracked model without any app needing to call it.

    object_id is a CharField (not an integer FK-style field) because not
    every model uses an integer pk - accounts.User's pk is a UUID.

    Known limitation: Django never fires save/delete signals for
    queryset-level bulk operations (.update(), .bulk_create(),
    .bulk_update(), or a queryset .delete()) - only for individual model
    instance .save()/.delete() calls. Those bulk paths won't appear here.
    """

    class Action(models.TextChoices):
        CREATE = "CREATE", "Create"
        UPDATE = "UPDATE", "Update"
        DELETE = "DELETE", "Delete"

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.CharField(max_length=64)
    content_object = GenericForeignKey("content_type", "object_id")
    object_repr = models.CharField(max_length=255, blank=True)

    action = models.CharField(max_length=10, choices=Action.choices)
    changed_fields = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["content_type", "object_id"])]

    def __str__(self):
        return f"{self.action} {self.content_type} #{self.object_id}"
