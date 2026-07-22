from rest_framework import serializers

from apps.shop_profile.models import ShopProfile


class ShopProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShopProfile
        fields = [
            "id", "shop_name", "address", "phone", "invoice_footer_text",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]
