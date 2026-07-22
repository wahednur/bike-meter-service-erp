from rest_framework import serializers


class AuditFeedEntrySerializer(serializers.Serializer):
    """One row of the unified audit feed - see
    apps.audit.services.build_audit_feed(). Plain Serializer, not
    ModelSerializer: rows are merged dicts spanning two different tables
    (AuditLog + AuditLogEntry), not instances of one model."""

    id = serializers.CharField()
    timestamp = serializers.DateTimeField()
    user = serializers.CharField(allow_null=True)
    source = serializers.ChoiceField(choices=["AUTO", "BUSINESS_EVENT"])
    model = serializers.CharField()
    model_display = serializers.CharField()
    object_id = serializers.CharField()
    record = serializers.CharField()
    action = serializers.CharField()
    action_display = serializers.CharField()
    summary = serializers.CharField()
