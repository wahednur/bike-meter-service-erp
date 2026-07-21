"""Wires up automatic AuditLog entries for every tracked model, without any
app needing to call logging code itself. Connected with sender=None (i.e.
"every model saved/deleted anywhere") from AuditConfig.ready().

Tracking is an ALLOWLIST of this project's actual business apps, not a
denylist of "known Django internals" - a denylist is a whack-a-mole game
(e.g. django.db.migrations.recorder.Migration, app_label "migrations", is
Django's own bookkeeping model for which migrations have run; firing this
signal for it corrupts migration application itself, since it's not even
part of the normal app registry). An allowlist can't be caught out by an
internal model we didn't think to exclude.
"""
from django.contrib.contenttypes.models import ContentType
from django.db.models.signals import post_delete, post_save, pre_save

from apps.audit.context import get_current_user

# auto_now=True on updated_at means it changes on literally every .save()
# call, even ones that touch no other field - excluded from the diff so a
# true no-op save doesn't get reported as a meaningless "update".
IGNORED_FIELDS = {"updated_at"}

TRACKED_APP_LABELS = {
    "accounts",
    "customers",
    "suppliers",
    "meters",
    "services",
    "products",
    "invoices",
    "assets",
    "loans",
    "notifications",
    "ecommerce",
}


def _is_tracked(sender):
    return sender._meta.app_label in TRACKED_APP_LABELS


def _get_old_values(sender, instance):
    manager = getattr(sender, "all_objects", sender.objects)
    try:
        old = manager.get(pk=instance.pk)
    except sender.DoesNotExist:
        return None
    return {f.name: getattr(old, f.name) for f in sender._meta.fields}


def _capture_pre_save_state(sender, instance, **kwargs):
    if not _is_tracked(sender):
        return
    instance._audit_old_values = _get_old_values(sender, instance) if instance.pk else None


def _log_save(sender, instance, created, **kwargs):
    if not _is_tracked(sender):
        return
    from apps.audit.models import AuditLog

    old_values = getattr(instance, "_audit_old_values", None)
    action = AuditLog.Action.CREATE
    changed_fields = []

    if not created:
        if old_values is None:
            return  # no prior snapshot to diff against - nothing meaningful to report
        for f in sender._meta.fields:
            if f.name in IGNORED_FIELDS:
                continue
            if old_values.get(f.name) != getattr(instance, f.name):
                changed_fields.append(f.name)
        if not changed_fields:
            return  # .save() called but nothing actually changed
        action = AuditLog.Action.UPDATE
        # BaseModel.delete() is a soft delete implemented as a plain
        # save() that flips is_deleted - report that transition as DELETE,
        # not a confusing "UPDATE of is_deleted".
        if "is_deleted" in changed_fields and getattr(instance, "is_deleted", False):
            action = AuditLog.Action.DELETE

    AuditLog.objects.create(
        content_type=ContentType.objects.get_for_model(sender),
        object_id=str(instance.pk),
        object_repr=str(instance)[:255],
        action=action,
        changed_fields=changed_fields,
        created_by=get_current_user(),
    )


def _log_hard_delete(sender, instance, **kwargs):
    if not _is_tracked(sender):
        return
    from apps.audit.models import AuditLog

    AuditLog.objects.create(
        content_type=ContentType.objects.get_for_model(sender),
        object_id=str(instance.pk),
        object_repr=str(instance)[:255],
        action=AuditLog.Action.DELETE,
        changed_fields=[],
        created_by=get_current_user(),
    )


def register_signals():
    pre_save.connect(_capture_pre_save_state, dispatch_uid="audit_pre_save")
    post_save.connect(_log_save, dispatch_uid="audit_post_save")
    post_delete.connect(_log_hard_delete, dispatch_uid="audit_post_delete")
