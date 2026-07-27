from datetime import date

from django.db import migrations

DEVICES = [
    {"name": "VVDI Prog", "purchase_price": "70000.00", "memory_type_support": "MCU"},
    {"name": "RT809F", "purchase_price": "7500.00", "memory_type_support": "EEPROM"},
    {"name": "UPA USB 1.3", "purchase_price": "7000.00", "memory_type_support": "EEPROM"},
    {"name": "TOP2013", "purchase_price": "15000.00", "memory_type_support": "EEPROM"},
    {"name": "EasyPro2025", "purchase_price": "3500.00", "memory_type_support": "EEPROM"},
]


def seed_devices(apps, schema_editor):
    MileageCorrectionDevice = apps.get_model("meters", "MileageCorrectionDevice")
    today = date.today()
    for device in DEVICES:
        MileageCorrectionDevice.objects.get_or_create(
            name=device["name"],
            defaults={
                "purchase_price": device["purchase_price"],
                "memory_type_support": device["memory_type_support"],
                "purchase_date": today,
            },
        )


def unseed_devices(apps, schema_editor):
    MileageCorrectionDevice = apps.get_model("meters", "MileageCorrectionDevice")
    MileageCorrectionDevice.objects.filter(name__in=[d["name"] for d in DEVICES]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('meters', '0002_mileagecorrectiondevice'),
    ]

    operations = [
        migrations.RunPython(seed_devices, unseed_devices),
    ]
