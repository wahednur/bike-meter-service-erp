from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend
from django.db.models import Q


class EmailOrPhoneBackend(ModelBackend):
    """Authenticate using either the email or the phone field as the identifier."""

    def authenticate(self, request, username=None, password=None, **kwargs):
        identifier = username or kwargs.get("identifier")
        if identifier is None or password is None:
            return None

        User = get_user_model()
        try:
            user = User.objects.get(
                Q(email__iexact=identifier) | Q(phone=identifier),
                is_deleted=False,
            )
        except User.DoesNotExist:
            return None
        except User.MultipleObjectsReturned:
            return None

        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
