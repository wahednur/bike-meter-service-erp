from django.contrib.contenttypes.models import ContentType

from apps.audit.models import AuditLogEntry


def log_action(instance, action, description="", user=None):
    """Records a single audit trail entry against `instance`."""
    return AuditLogEntry.objects.create(
        content_type=ContentType.objects.get_for_model(instance),
        object_id=instance.pk,
        action=action,
        description=description,
        created_by=user,
    )
