# Converts InvoiceMeterEntry.condition_note from a free-text TextField to a
# JSONField storing a list of tags (presets and/or custom text, e.g.
# ["Power IC Problem", "Display Problem"]). Done as add-new-field /
# migrate-data / drop-old-field / rename, rather than a plain AlterField,
# because a straight type change would try to json.loads() each existing
# raw string (e.g. "Casing intact, screen fine") and fail - it isn't valid
# JSON. Every pre-existing note is preserved as a single custom tag;
# genuinely blank notes become ["Good"], matching the new default.

from django.db import migrations, models


def condition_note_text_to_list(apps, schema_editor):
    InvoiceMeterEntry = apps.get_model("invoices", "InvoiceMeterEntry")
    for entry in InvoiceMeterEntry.objects.all():
        old_value = (entry.condition_note or "").strip()
        entry.condition_note_tags = [old_value] if old_value else ["Good"]
        entry.save(update_fields=["condition_note_tags"])


def condition_note_list_to_text(apps, schema_editor):
    InvoiceMeterEntry = apps.get_model("invoices", "InvoiceMeterEntry")
    for entry in InvoiceMeterEntry.objects.all():
        entry.condition_note = ", ".join(entry.condition_note_tags or [])
        entry.save(update_fields=["condition_note"])


class Migration(migrations.Migration):

    dependencies = [
        ('invoices', '0005_invoice_waived_amount_invoice_waived_note_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='invoicemeterentry',
            name='condition_note_tags',
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.RunPython(condition_note_text_to_list, condition_note_list_to_text),
        migrations.RemoveField(
            model_name='invoicemeterentry',
            name='condition_note',
        ),
        migrations.RenameField(
            model_name='invoicemeterentry',
            old_name='condition_note_tags',
            new_name='condition_note',
        ),
    ]
