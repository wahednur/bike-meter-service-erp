from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User


class LoginSerializer(TokenObtainPairSerializer):
    """Accepts either email or phone in `identifier`, plus `password`."""

    identifier = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Replace SimpleJWT's default username field with our own.
        self.fields.pop(self.username_field, None)

    def validate(self, attrs):
        identifier = attrs.get("identifier")
        password = attrs.get("password")

        user = authenticate(
            request=self.context.get("request"),
            username=identifier,
            password=password,
        )
        if user is None:
            raise serializers.ValidationError("Invalid credentials.")
        if not user.is_active:
            raise serializers.ValidationError("This account is inactive.")

        refresh = RefreshToken.for_user(user)
        refresh["role"] = user.role
        refresh["name"] = user.name

        return {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "user": {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "role": user.role,
            },
        }


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate_refresh(self, value):
        try:
            self._token = RefreshToken(value)
        except TokenError as exc:
            raise serializers.ValidationError(str(exc))
        return value

    def save(self, **kwargs):
        try:
            self._token.blacklist()
        except TokenError as exc:
            raise serializers.ValidationError(str(exc))


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "name", "email", "phone", "role",
            "is_active", "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    def validate(self, attrs):
        email = attrs.get("email", getattr(self.instance, "email", None))
        phone = attrs.get("phone", getattr(self.instance, "phone", None))
        if not email and not phone:
            raise serializers.ValidationError("Provide an email or a phone number.")
        return attrs


class UserCreateSerializer(UserSerializer):
    password = serializers.CharField(write_only=True)

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ["password"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        request = self.context.get("request")
        created_by = getattr(request, "user", None) if request else None
        user = User.objects.create_user(
            password=password, created_by=created_by, **validated_data
        )
        return user
