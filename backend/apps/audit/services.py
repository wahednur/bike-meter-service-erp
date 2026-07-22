from django.contrib.contenttypes.models import ContentType

from apps.audit.models import AuditLog, AuditLogEntry


def log_action(instance, action, description="", user=None):
    """Records a single audit trail entry against `instance`."""
    return AuditLogEntry.objects.create(
        content_type=ContentType.objects.get_for_model(instance),
        object_id=instance.pk,
        action=action,
        description=description,
        created_by=user,
    )


# --- unified, browsable audit feed - see apps.audit.views.AuditLogView ---------
#
# Merges two different tables with different shapes into one chronological
# list:
#   - AuditLog      - automatic CREATE/UPDATE/DELETE trail (apps.audit.signals)
#   - AuditLogEntry - hand-curated business events (e.g. "payment_added")
#
# Known scale limitation: build_audit_feed() loads the *entire* filtered
# result set into memory and sorts it there; the view slices a page out of
# that. For a small shop's day-to-day audit trail this is simple and
# correct. If this table ever grows into the millions of rows, the real fix
# is a cross-table cursor (or a materialized/denormalized feed table)
# rather than this in-memory merge - not needed yet, so not built yet.

def _model_display_name(content_type):
    model_class = content_type.model_class()
    if model_class is None:
        return content_type.model.title()
    return str(model_class._meta.verbose_name).title()


def _object_repr_map(pairs):
    """{(content_type_id, object_id_str): "str(obj)"} for a batch of
    (content_type_id, object_id) pairs - used for AuditLogEntry rows, which
    (unlike AuditLog) don't freeze a representation at write time. Batches
    one query per content type instead of one per row, and reads through
    each model's all_objects manager (falling back to the default manager
    for models without one) so a soft-deleted record still resolves to
    something readable instead of vanishing from its own history."""
    by_content_type = {}
    for content_type_id, object_id in pairs:
        by_content_type.setdefault(content_type_id, set()).add(object_id)

    reprs = {}
    for content_type_id, object_ids in by_content_type.items():
        content_type = ContentType.objects.get_for_id(content_type_id)
        model_class = content_type.model_class()
        if model_class is None:
            continue
        manager = getattr(model_class, "all_objects", model_class._default_manager)
        for obj in manager.filter(pk__in=object_ids):
            reprs[(content_type_id, str(obj.pk))] = str(obj)
    return reprs


def _auto_change_summary(action, changed_fields):
    if action == AuditLog.Action.CREATE:
        return "Record created."
    if action == AuditLog.Action.DELETE:
        return "Record soft-deleted." if changed_fields else "Record permanently deleted."
    if changed_fields:
        return f"Changed: {', '.join(changed_fields)}."
    return "Record updated."


def _humanize_action(action):
    return action.replace("_", " ").title()


def build_audit_feed(from_date=None, to_date=None, user_id=None, model=None, action=None):
    """Returns every AuditLog + AuditLogEntry row matching the given
    filters (identically applied to both sources), merged and sorted
    newest-first. The view is responsible for slicing a page out of this.
    """
    auto_qs = AuditLog.objects.select_related("content_type", "created_by")
    event_qs = AuditLogEntry.objects.select_related("content_type", "created_by")

    if from_date:
        auto_qs = auto_qs.filter(created_at__date__gte=from_date)
        event_qs = event_qs.filter(created_at__date__gte=from_date)
    if to_date:
        auto_qs = auto_qs.filter(created_at__date__lte=to_date)
        event_qs = event_qs.filter(created_at__date__lte=to_date)
    if user_id:
        auto_qs = auto_qs.filter(created_by_id=user_id)
        event_qs = event_qs.filter(created_by_id=user_id)
    if model:
        auto_qs = auto_qs.filter(content_type__model=model.lower())
        event_qs = event_qs.filter(content_type__model=model.lower())
    if action:
        # Same filter applied to both sources rather than special-cased per
        # source: AuditLog's actions are only ever CREATE/UPDATE/DELETE and
        # AuditLogEntry's are only ever business-event strings like
        # "payment_added", so an action value naturally only ever matches
        # rows from the one source it's meaningful for.
        auto_qs = auto_qs.filter(action__iexact=action)
        event_qs = event_qs.filter(action__iexact=action)

    auto_rows = list(auto_qs)
    event_rows = list(event_qs)

    repr_map = _object_repr_map({(row.content_type_id, str(row.object_id)) for row in event_rows})

    rows = []
    for row in auto_rows:
        model_display = _model_display_name(row.content_type)
        record = (
            f"{model_display}: {row.object_repr}" if row.object_repr
            else f"{model_display} #{row.object_id}"
        )
        rows.append({
            "id": f"auto-{row.id}",
            "timestamp": row.created_at,
            "user": row.created_by.name if row.created_by else None,
            "source": "AUTO",
            "model": row.content_type.model,
            "model_display": model_display,
            "object_id": str(row.object_id),
            "record": record,
            "action": row.action,
            "action_display": row.get_action_display(),
            "summary": _auto_change_summary(row.action, row.changed_fields),
        })

    for row in event_rows:
        model_display = _model_display_name(row.content_type)
        object_repr = repr_map.get((row.content_type_id, str(row.object_id)))
        record = (
            f"{model_display}: {object_repr}" if object_repr
            else f"{model_display} #{row.object_id} (deleted)"
        )
        rows.append({
            "id": f"event-{row.id}",
            "timestamp": row.created_at,
            "user": row.created_by.name if row.created_by else None,
            "source": "BUSINESS_EVENT",
            "model": row.content_type.model,
            "model_display": model_display,
            "object_id": str(row.object_id),
            "record": record,
            "action": row.action,
            "action_display": _humanize_action(row.action),
            "summary": row.description or _humanize_action(row.action),
        })

    rows.sort(key=lambda r: r["timestamp"], reverse=True)
    return rows
