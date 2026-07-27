"""Populates the database with realistic, interconnected demo data across
every app, for manually testing the API/admin/frontend. Goes through the
same service-layer functions the real API uses (get_or_create_open_invoice,
restock_product, place_order, ...) rather than raw ORM inserts, so every
business rule (open-invoice reuse, weighted-average cost, red-listing,
mileage-correction validation, stock decrement, ...) produces genuinely
correct data - not just plausible-looking rows.

Safe to re-run: reference data (customers, suppliers, meters, services,
products, assets, loans) is created with get_or_create, and invoices/orders
are skipped for a customer/phone that already has one, so re-running won't
pile up duplicates.
"""
from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.assets.models import Asset, AssetIncident
from apps.customers.models import Customer
from apps.ecommerce import services as ecommerce_services
from apps.ecommerce.models import Order
from apps.invoices import services as invoice_services
from apps.invoices.models import Invoice
from apps.loans import services as loan_services
from apps.loans.models import Loan
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.notifications import services as notification_services
from apps.products import services as product_services
from apps.products.models import Product
from apps.services.models import Service, ServiceCategory
from apps.suppliers.models import Supplier

User = get_user_model()


class Command(BaseCommand):
    help = "Seeds the database with realistic demo/test data across every app."

    def handle(self, *args, **options):
        with transaction.atomic():
            admin, admin_created, staff, staff_created = self._seed_users()
            customers = self._seed_customers(admin)
            suppliers = self._seed_suppliers(admin)
            meters, devices = self._seed_meters(admin)
            services = self._seed_services(admin)
            products = self._seed_products(suppliers, admin)
            self._seed_assets(suppliers, admin)
            self._seed_loans(admin)
            invoices = self._seed_invoices(customers, meters, devices, services, products, admin)
            orders = self._seed_ecommerce_orders(products, admin)

        notification_result = notification_services.run_daily_notification_check(upcoming_days=14)

        self._print_summary(
            admin, admin_created, staff, staff_created, customers, products, invoices, orders, notification_result,
        )

    # --- users -----------------------------------------------------------------

    def _seed_users(self):
        admin = User.objects.filter(is_superuser=True).first()
        admin_created = False
        if not admin:
            admin = User.objects.create_superuser(
                email="demo_admin@bikemeter.local", phone="01700000001",
                password="DemoAdmin123!", name="Demo Admin",
            )
            admin_created = True

        staff, staff_created = User.objects.get_or_create(
            email="demo_staff@bikemeter.local",
            defaults={"name": "Demo Staff", "phone": "01700000002", "role": User.Role.STAFF},
        )
        if staff_created:
            staff.set_password("DemoStaff123!")
            staff.save()

        return admin, admin_created, staff, staff_created

    # --- reference data ----------------------------------------------------------

    def _seed_customers(self, admin):
        rows = [
            {"name": "Rahim Uddin", "phone": "01711000001", "address": "Mirpur, Dhaka", "email": "rahim.uddin@example.com"},
            {"name": "Karim Sheikh", "phone": "01711000002", "address": "Uttara, Dhaka"},
            {"name": "Nasrin Akter", "phone": "01711000003", "address": "Gulshan, Dhaka"},
            {"name": "Shorif Ahmed", "phone": "01711000004", "address": "Mohammadpur, Dhaka"},
            {"name": "Jasim Uddin", "phone": "01711000005", "address": "Banani, Dhaka"},
        ]
        customers = {}
        for row in rows:
            phone = row.pop("phone")
            customer, _ = Customer.objects.get_or_create(phone=phone, defaults={**row, "created_by": admin})
            customers[customer.name] = customer
        return customers

    def _seed_suppliers(self, admin):
        rows = [
            {"name": "ABC Traders", "phone": "01811000001", "address": "Chawkbazar, Dhaka"},
            {"name": "Rangs Auto Parts", "phone": "01811000002", "address": "Tejgaon, Dhaka"},
            {"name": "Zenith Auto Parts", "phone": "01811000003", "address": "Bangshal, Dhaka"},
        ]
        suppliers = {}
        for row in rows:
            phone = row.pop("phone")
            supplier, _ = Supplier.objects.get_or_create(phone=phone, defaults={**row, "created_by": admin})
            suppliers[supplier.name] = supplier
        return suppliers

    def _seed_meters(self, admin):
        rows = [
            {"brand": "Bajaj", "model": "Discover 125", "cc": 125, "memory_type": Meter.MemoryType.MCU, "ic_mcu_model": "R5F10CMEL", "sales_price": "1500.00"},
            {"brand": "Yamaha", "model": "FZ V2", "cc": 150, "memory_type": Meter.MemoryType.EEPROM, "ic_mcu_model": "93C66", "sales_price": "1800.00"},
            {"brand": "Suzuki", "model": "SF 150", "cc": 150, "memory_type": Meter.MemoryType.EEPROM, "ic_mcu_model": "93C66", "sales_price": "1750.00"},
            {"brand": "Honda", "model": "CB Shine", "cc": 125, "memory_type": Meter.MemoryType.MCU, "ic_mcu_model": "R5F10CMEL", "sales_price": "1600.00"},
        ]
        meters = {}
        for row in rows:
            brand, model = row["brand"], row["model"]
            meter, _ = Meter.objects.get_or_create(
                brand=brand, model=model,
                defaults={"cc": row["cc"], "memory_type": row["memory_type"], "ic_mcu_model": row["ic_mcu_model"],
                          "sales_price": row["sales_price"], "created_by": admin},
            )
            meters[f"{brand} {model}"] = meter

        # seeded by the meters app's own data migration - just fetch them
        devices = {
            "VVDI Prog": MileageCorrectionDevice.objects.get(name="VVDI Prog"),
            "RT809F": MileageCorrectionDevice.objects.get(name="RT809F"),
            "EasyPro2025": MileageCorrectionDevice.objects.get(name="EasyPro2025"),
        }
        return meters, devices

    def _seed_services(self, admin):
        rows = [
            (ServiceCategory.Name.MILEAGE_CORRECTION, "Mileage Correction", "500.00"),
            (ServiceCategory.Name.METER_REPAIR, "LED IC problem repair", "300.00"),
            (ServiceCategory.Name.DISPLAY_REPAIR, "Damaged LED replace", "350.00"),
            (ServiceCategory.Name.MAIN_BOARD_REPAIR, "Main board repair", "600.00"),
            (ServiceCategory.Name.LIGHT_REPAIR, "Headlight repair", "400.00"),
            (ServiceCategory.Name.POWER_PROBLEM_REPAIR, "Power circuit repair", "450.00"),
        ]
        services = {}
        for category_name, service_name, price in rows:
            category, _ = ServiceCategory.objects.get_or_create(name=category_name, defaults={"created_by": admin})
            service, _ = Service.objects.get_or_create(
                category=category, name=service_name, defaults={"service_price": price, "created_by": admin},
            )
            services[service_name] = service
        return services

    def _seed_products(self, suppliers, admin):
        supplier_cycle = list(suppliers.values())
        rows = [
            {"name": "Universal Meter Casing", "sku": "CASING-001", "sale_price": "150.00", "restock_qty": 20, "restock_price": "80.00"},
            {"name": "LED Strip", "sku": "LED-001", "sale_price": "120.00", "restock_qty": 30, "restock_price": "60.00"},
            {"name": "Headlight Bulb", "sku": "BULB-001", "sale_price": "180.00", "restock_qty": 25, "restock_price": "100.00"},
            {"name": "Speed Sensor", "sku": "SENSOR-001", "sale_price": "350.00", "restock_qty": 3, "restock_price": "200.00"},  # deliberately low stock
            {"name": "Odometer Gear", "sku": "GEAR-001", "sale_price": "55.00", "restock_qty": 40, "restock_price": "25.00"},
        ]
        products = {}
        for index, row in enumerate(rows):
            supplier = supplier_cycle[index % len(supplier_cycle)]
            product, created = Product.objects.get_or_create(
                sku=row["sku"],
                defaults={"name": row["name"], "supplier": supplier, "sale_price": row["sale_price"], "created_by": admin},
            )
            if created:
                product_services.restock_product(
                    product, quantity=row["restock_qty"], unit_price=Decimal(row["restock_price"]),
                )
            products[row["sku"]] = product
        return products

    def _seed_assets(self, suppliers, admin):
        supplier = next(iter(suppliers.values()))
        purchase_date = timezone.now().date() - timedelta(days=60)
        rows = [
            {"name": "60W Soldering Iron", "purchase_price": "2500.00", "has_warranty": True, "warranty_note": "1 year seller warranty"},
            {"name": "Digital Multimeter", "purchase_price": "1200.00", "has_warranty": False, "warranty_note": ""},
            {"name": "Crimping Tool", "purchase_price": "1800.00", "has_warranty": False, "warranty_note": ""},
        ]
        for row in rows:
            asset, created = Asset.objects.get_or_create(
                name=row["name"],
                defaults={
                    "purchase_price": row["purchase_price"], "purchase_date": purchase_date, "supplier": supplier,
                    "has_warranty": row["has_warranty"], "warranty_note": row["warranty_note"], "created_by": admin,
                },
            )
            if created and asset.name == "60W Soldering Iron":
                AssetIncident.objects.create(
                    asset=asset, type=AssetIncident.Type.REPAIRED, cost=Decimal("300.00"),
                    date=purchase_date + timedelta(days=30), note="Tip replaced", created_by=admin,
                )

    def _seed_loans(self, admin):
        rows = [
            {
                "lender_name": "City Bank", "lender_type": Loan.LenderType.BANK,
                "loan_amount": "100000.00", "deposit_amount": "5000.00", "interest_amount": "15000.00",
                "total_installments": 12, "installment_amount": "10000.00",
                "installment_frequency": Loan.InstallmentFrequency.MONTHLY,
                "start_date": timezone.now().date() - timedelta(days=60), "paid_installments": 2,
            },
            {
                "lender_name": "Grameen Support NGO", "lender_type": Loan.LenderType.NGO,
                "loan_amount": "30000.00", "deposit_amount": "0", "interest_amount": "3000.00",
                "total_installments": 6, "installment_amount": "5500.00",
                "installment_frequency": Loan.InstallmentFrequency.WEEKLY,
                "start_date": timezone.now().date() - timedelta(days=14), "paid_installments": 1,
            },
        ]
        for row in rows:
            paid_installments = row.pop("paid_installments")
            loan, created = Loan.objects.get_or_create(
                lender_name=row["lender_name"], defaults={**row, "created_by": admin},
            )
            if created:
                for i in range(1, paid_installments + 1):
                    loan_services.add_installment_payment(
                        loan, amount_paid=Decimal(loan.installment_amount),
                        payment_date=loan.start_date + timedelta(days=1),
                        installment_number=i, user=admin,
                    )

    # --- invoices (the interesting part - exercises every Phase 6/7 rule) --------

    def _seed_invoices(self, customers, meters, devices, services, products, admin):
        created_invoices = []

        # Rahim Uddin - fully paid in one go, 2 meters + a product line
        rahim = customers["Rahim Uddin"]
        if not Invoice.objects.filter(customer=rahim).exists():
            invoice, _ = invoice_services.get_or_create_open_invoice(rahim, user=admin)
            entry1 = invoice_services.add_meter_entry(
                invoice, meters["Bajaj Discover 125"], serial_number="MCU-DEMO-001",
                condition_note=["Display Problem", "Casing scratched"], previous_km=45210, current_km=12000,
                mileage_correction_device=devices["VVDI Prog"], user=admin,
            )
            invoice_services.add_service_line(invoice, services["Mileage Correction"], meter_entry=entry1, user=admin)
            entry2 = invoice_services.add_meter_entry(
                invoice, meters["Yamaha FZ V2"], serial_number="EEP-DEMO-001",
                condition_note=["Light IC Problem", "LED strip flickering"], user=admin,
            )
            invoice_services.add_service_line(invoice, services["LED IC problem repair"], meter_entry=entry2, user=admin)
            invoice_services.add_product_line(invoice, products["CASING-001"], quantity=1, user=admin)

            invoice.refresh_from_db()
            invoice_services.add_payment(invoice, amount=invoice.outstanding_amount, payment_method="CASH", user=admin)
            created_invoices.append(invoice)

        # Karim Sheikh - partial payment (tests the Due Report / Partial Paid status)
        karim = customers["Karim Sheikh"]
        if not Invoice.objects.filter(customer=karim).exists():
            invoice, _ = invoice_services.get_or_create_open_invoice(karim, user=admin)
            entry = invoice_services.add_meter_entry(
                invoice, meters["Suzuki SF 150"], serial_number="EEP-DEMO-002",
                condition_note=["Kilometer Problem", "Odometer frozen, needs correction"],
                previous_km=30500, current_km=5000,
                mileage_correction_device=devices["RT809F"], user=admin,
            )
            invoice_services.add_service_line(invoice, services["Mileage Correction"], meter_entry=entry, user=admin)
            invoice.refresh_from_db()
            half = (invoice.total_amount / 2).quantize(Decimal("0.01"))
            invoice_services.add_payment(invoice, amount=half, payment_method="BKASH", user=admin)
            created_invoices.append(invoice)

        # Nasrin Akter - unpaid, meter repair + product, no payment at all
        nasrin = customers["Nasrin Akter"]
        if not Invoice.objects.filter(customer=nasrin).exists():
            invoice, _ = invoice_services.get_or_create_open_invoice(nasrin, user=admin)
            entry = invoice_services.add_meter_entry(
                invoice, meters["Honda CB Shine"], serial_number="MCU-DEMO-002",
                condition_note=["IC Problem", "Main board burnt smell"], user=admin,
            )
            invoice_services.add_service_line(invoice, services["Main board repair"], meter_entry=entry, user=admin)
            invoice_services.add_product_line(invoice, products["LED-001"], quantity=2, user=admin)
            created_invoices.append(invoice)

        # Shorif Ahmed - two consecutive invoices with a payment shortfall,
        # to demonstrate the customer red-listing rule (Phase 7g) actually firing
        shorif = customers["Shorif Ahmed"]
        if not Invoice.objects.filter(customer=shorif).exists():
            for service_name, price in [("Headlight repair", "300.00"), ("Power circuit repair", "450.00")]:
                invoice, _ = invoice_services.get_or_create_open_invoice(shorif, user=admin)
                invoice_services.add_service_line(invoice, services[service_name], price_charged=Decimal(price), user=admin)
                invoice.refresh_from_db()
                shortfall_first = (invoice.total_amount * Decimal("0.7")).quantize(Decimal("0.01"))
                invoice_services.add_payment(invoice, amount=shortfall_first, payment_method="CASH", user=admin)
                invoice.refresh_from_db()
                invoice_services.add_payment(invoice, amount=invoice.outstanding_amount, payment_method="CASH", user=admin)
                created_invoices.append(invoice)

        # Jasim Uddin - a cancelled invoice, so that status path has a real example too
        jasim = customers["Jasim Uddin"]
        if not Invoice.objects.filter(customer=jasim).exists():
            invoice, _ = invoice_services.get_or_create_open_invoice(jasim, user=admin)
            invoice_services.add_service_line(invoice, services["Damaged LED replace"], price_charged=Decimal("350.00"), user=admin)
            invoice_services.cancel_invoice(invoice, user=admin)
            created_invoices.append(invoice)

        return created_invoices

    # --- ecommerce -----------------------------------------------------------------

    def _seed_ecommerce_orders(self, products, admin):
        orders = []
        rows = [
            {
                "customer_name": "Farhana Yasmin", "customer_phone": "01911000001", "customer_address": "Banani, Dhaka",
                "items": [{"product": products["BULB-001"], "quantity": 2}], "final_status": None,
            },
            {
                "customer_name": "Mizanur Rahman", "customer_phone": "01911000002", "customer_address": "Dhanmondi, Dhaka",
                "items": [{"product": products["CASING-001"], "quantity": 1}, {"product": products["GEAR-001"], "quantity": 3}],
                "final_status": Order.Status.CONFIRMED,
            },
            {
                "customer_name": "Tania Islam", "customer_phone": "01911000003", "customer_address": "Uttara, Dhaka",
                "items": [{"product": products["LED-001"], "quantity": 1}], "final_status": Order.Status.DELIVERED,
            },
        ]
        for row in rows:
            if Order.objects.filter(customer_phone=row["customer_phone"]).exists():
                continue
            order = ecommerce_services.place_order(
                customer_name=row["customer_name"], customer_phone=row["customer_phone"],
                customer_address=row["customer_address"], items=row["items"],
            )
            if row["final_status"]:
                ecommerce_services.update_order_status(order, row["final_status"], user=admin)
            orders.append(order)
        return orders

    # --- summary -----------------------------------------------------------------

    def _print_summary(self, admin, admin_created, staff, staff_created, customers, products, invoices, orders, notif_result):
        w = self.stdout.write
        s = self.style

        w(s.SUCCESS("\nDemo data seeded successfully.\n"))

        w(s.MIGRATE_HEADING("Login credentials"))
        if admin_created:
            w(f"  Admin : {admin.email} / DemoAdmin123!")
        else:
            w(f"  Admin : using existing superuser '{admin.email}' (password unchanged)")
        if staff_created:
            w(f"  Staff : {staff.email} / DemoStaff123!")
        else:
            w(f"  Staff : demo_staff@bikemeter.local already existed (password unchanged)")

        w(s.MIGRATE_HEADING("\nThings worth looking at"))
        w(f"  Red-listed customer : Shorif Ahmed (2 consecutive underpaid invoices)")
        low_stock = products["SENSOR-001"]
        w(f"  Low-stock product   : {low_stock.name} (sku {low_stock.sku}, {low_stock.current_stock_quantity} left)")

        if invoices:
            sample_invoice = invoices[0]
            w(f"  Public invoice link : /api/public/invoices/{sample_invoice.public_share_token}/  ({sample_invoice.invoice_no})")
        if orders:
            sample_order = orders[0]
            w(f"  Order tracking link : /api/public/orders/{sample_order.tracking_token}/  ({sample_order.order_no})")

        w(f"  Notifications       : {notif_result['due_invoice_notifications_created']} due-invoice, "
          f"{notif_result['loan_installment_notifications_created']} loan-installment (see /api/notifications/)")

        w(s.MIGRATE_HEADING("\nTry these endpoints"))
        for line in [
            "GET  /api/reports/admin-dashboard/",
            "GET  /api/reports/summary/",
            "GET  /api/reports/due/",
            "GET  /api/reports/cashbook/",
            "GET  /api/customers/  (look for is_red_listed=true)",
            "GET  /api/public/products/",
            "GET  /api/invoices/",
            "GET  /api/orders/",
        ]:
            w(f"  {line}")
        w("")
