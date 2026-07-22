from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdmin, IsStaffOrAdmin
from apps.shop_profile.models import ShopProfile
from apps.shop_profile.serializers import ShopProfileSerializer


class ShopProfileView(APIView):
    """GET/PATCH /api/shop-profile/ - the single shop settings row.
    GET is any active system user (Staff needs it for app branding);
    PATCH stays Admin-only."""

    def get_permissions(self):
        if self.request.method == "PATCH":
            return [IsAdmin()]
        return [IsStaffOrAdmin()]

    def get(self, request):
        profile = ShopProfile.load()
        return Response(ShopProfileSerializer(profile).data)

    def patch(self, request):
        profile = ShopProfile.load(user=request.user)
        serializer = ShopProfileSerializer(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
