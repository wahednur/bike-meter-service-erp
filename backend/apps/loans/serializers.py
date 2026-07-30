import io
import os

from django.core.files.uploadedfile import InMemoryUploadedFile
from PIL import Image
from rest_framework import serializers

from apps.loans import services as loan_services
from apps.loans.models import Loan, LoanInstallmentPayment


# Attachments are meant to be a quick receipt photo/scan, not document
# storage. Uploads may arrive up to 300KB, but images are re-encoded down
# under 50KB before saving so storage stays tiny regardless of what the
# customer's phone camera produced.
MAX_ATTACHMENT_SIZE_BYTES = 300 * 1024
MAX_COMPRESSED_IMAGE_SIZE_BYTES = 50 * 1024
ALLOWED_ATTACHMENT_EXTENSIONS = (".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf")
IMAGE_ATTACHMENT_EXTENSIONS = (".png", ".jpg", ".jpeg", ".gif", ".webp")


def compress_image_attachment(file_obj):
    """Re-encode an uploaded image as JPEG, stepping quality and then
    dimensions down until it fits under MAX_COMPRESSED_IMAGE_SIZE_BYTES."""
    file_obj.seek(0)
    image = Image.open(file_obj)
    image = image.convert("RGB")

    buffer = io.BytesIO()
    quality = 85
    image.save(buffer, format="JPEG", quality=quality, optimize=True)

    while buffer.tell() > MAX_COMPRESSED_IMAGE_SIZE_BYTES and quality > 10:
        quality -= 10
        buffer = io.BytesIO()
        image.save(buffer, format="JPEG", quality=quality, optimize=True)

    while buffer.tell() > MAX_COMPRESSED_IMAGE_SIZE_BYTES and min(image.size) > 100:
        image = image.resize((int(image.width * 0.8), int(image.height * 0.8)))
        buffer = io.BytesIO()
        image.save(buffer, format="JPEG", quality=quality, optimize=True)

    buffer.seek(0)
    name = os.path.splitext(file_obj.name)[0] + ".jpg"
    return InMemoryUploadedFile(
        buffer, None, name, "image/jpeg", buffer.getbuffer().nbytes, None,
    )


class LoanInstallmentPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoanInstallmentPayment
        fields = [
            "id", "loan", "amount_paid", "payment_date", "installment_number", "attachment",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    def validate_attachment(self, value):
        if value is None:
            return value
        extension = os.path.splitext(value.name)[1].lower()
        if extension not in ALLOWED_ATTACHMENT_EXTENSIONS:
            raise serializers.ValidationError("Attachment must be an image (png/jpg/gif/webp) or a PDF.")
        if value.size > MAX_ATTACHMENT_SIZE_BYTES:
            raise serializers.ValidationError("Attachment must be smaller than 300KB.")
        if extension in IMAGE_ATTACHMENT_EXTENSIONS:
            value = compress_image_attachment(value)
        return value


class LoanSerializer(serializers.ModelSerializer):
    """Used for both list and detail - every loan already carries its full
    computed summary, so the list endpoint doubles as an overview of all
    loans across every lender."""

    total_payable = serializers.ReadOnlyField()
    installments_paid_count = serializers.SerializerMethodField()
    installments_remaining = serializers.SerializerMethodField()
    amount_paid_so_far = serializers.SerializerMethodField()
    amount_remaining = serializers.SerializerMethodField()
    # The single earliest unpaid installment (see
    # apps.loans.services.compute_next_installment()) - null once the loan
    # is fully paid off. next_installment_is_overdue is null right along
    # with the other two in that case (there's nothing to be overdue on).
    next_installment_number = serializers.SerializerMethodField()
    next_installment_due_date = serializers.SerializerMethodField()
    next_installment_is_overdue = serializers.SerializerMethodField()

    class Meta:
        model = Loan
        fields = [
            "id", "lender_name", "lender_type", "loan_amount", "deposit_amount", "interest_amount",
            "total_payable", "total_installments", "installment_amount", "installment_frequency",
            "start_date", "installments_paid_count", "installments_remaining",
            "amount_paid_so_far", "amount_remaining",
            "next_installment_number", "next_installment_due_date", "next_installment_is_overdue",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    def get_installments_paid_count(self, obj):
        return loan_services.compute_loan_stats(obj)["installments_paid_count"]

    def get_installments_remaining(self, obj):
        return loan_services.compute_loan_stats(obj)["installments_remaining"]

    def get_amount_paid_so_far(self, obj):
        return loan_services.compute_loan_stats(obj)["amount_paid_so_far"]

    def get_amount_remaining(self, obj):
        return loan_services.compute_loan_stats(obj)["amount_remaining"]

    def _next_installment(self, obj):
        # SerializerMethodField calls each getter independently with no
        # shared cache, so stash the (possibly None) result on the
        # instance for the run of this one serialization instead of
        # recomputing the schedule three times per loan.
        if not hasattr(obj, "_next_installment_cache"):
            obj._next_installment_cache = loan_services.compute_next_installment(obj)
        return obj._next_installment_cache

    def get_next_installment_number(self, obj):
        next_installment = self._next_installment(obj)
        return next_installment["installment_number"] if next_installment else None

    def get_next_installment_due_date(self, obj):
        next_installment = self._next_installment(obj)
        return next_installment["due_date"] if next_installment else None

    def get_next_installment_is_overdue(self, obj):
        next_installment = self._next_installment(obj)
        return next_installment["is_overdue"] if next_installment else None
