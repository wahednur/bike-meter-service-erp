# Nurain Motorcycle Meter Service Center — ERP System

> A full-stack business management system built for a motorcycle meter repair and parts business — replacing manual bookkeeping with a structured, auditable digital workflow for invoicing, inventory, customer relationships, and financial reporting.

**Live use case:** Purpose-built for a real, operating business handling meter repairs, mileage correction services, spare-parts sales, and multi-week installment payments from walk-in customers.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django + Django REST Framework |
| Database | PostgreSQL |
| Frontend | Next.js 16 (App Router, TypeScript) |
| UI | shadcn/ui + Tailwind CSS (custom theme) |
| Auth | JWT (djangorestframework-simplejwt) |
| Architecture | Monorepo (`backend/` + `frontend/`) |

---

## Overview

This system manages the full operational and financial lifecycle of a bike meter repair shop:

- **Customers & Suppliers** — record-only entities (no login required) with full transaction history
- **Meters** — brand/model/CC/memory-type (EEPROM/MCU) reference data with hardware-aware validation
- **Services** — categorized repair and mileage-correction offerings with live performance stats
- **Products & Inventory** — supplier-linked stock with weighted-average cost recalculation on restock
- **Invoices** — the core of the system (see below)
- **Assets & Devices** — tool/equipment cost-recovery tracking
- **Loans** — multi-lender installment tracking
- **Reports** — income, expense, profit/loss, stock, ledgers, and customer analytics
- **Audit Log** — full change history across every model, plus hand-curated business events

---

## The Invoice Engine (core design challenge)

Invoicing in a repair shop doesn't follow a simple "one transaction, one invoice" model — customers bring in multiple items over days or weeks and pay in installments. This system was built around that reality:

- **Open-invoice lifecycle** — a customer's invoice stays open and accumulates new work/products until fully settled; a new invoice is never created while one is still outstanding.
- **Automatic payment-splitting** — when a customer underpays across multiple serviced items in one invoice, the paid amount is distributed proportionally across those line items, preserving an accurate per-item paid/due history.
- **Hardware-aware validation** — mileage correction services are validated against the target meter's memory type (EEPROM vs. MCU), restricting which correction devices can legally be selected for that job.
- **Manual close & write-off** — invoices can be force-closed with a documented reason when a shop owner accepts a shortfall as final; the written-off amount is tracked separately from intentional discounts, feeding into customer risk analytics rather than disappearing from the books.
- **Full auditability** — discounts, backdating, write-offs, and edits to already-paid invoices are all logged with who/when/why, while remaining fully editable to accommodate real-world correction needs.
- **No-login public sharing** — each invoice generates a short, tokenized public link (shareable via WhatsApp/IMO) showing a clean customer-facing summary, with internal-only details (e.g. correction device used) excluded.

---

## Other Notable Features

- **Weighted-average inventory costing** with proportional shared-cost (e.g. delivery charge) distribution across multi-product purchases
- **Auto-generated SKUs** derived from supplier and product name patterns
- **Customer risk-flagging** — automatic red-listing based on repeated payment shortfalls
- **CSV bulk import** with column-mapping for onboarding existing customer data
- **Dashboard analytics** — daily/weekly/monthly income and expense breakdowns, run-rate-based monthly income projections, and business-health indicators at a glance
- **Role-based access control** — Admin vs. Staff permission boundaries enforced at the API layer
- **Automated audit trail** — every create/update/delete across the system logged via Django signals, browsable through a dedicated admin view

---

## Project Structure

```
bike_meter_erp/
├── backend/     # Django + DRF API
│   └── apps/     # accounts, customers, suppliers, meters, services,
│                  # products, inventory, invoices, assets, loans,
│                  # reports, ecommerce, audit
└── frontend/     # Next.js 16 + shadcn/ui
```

---

## Getting Started

### Backend
```bash
cd backend
python -m venv venv
source venv/Scripts/activate   # or venv/bin/activate on macOS/Linux
pip install -r requirements.txt
cp .env.example .env           # fill in your database credentials
python manage.py migrate
python manage.py runserver
```

### Frontend
```bash
cd frontend
npm install
cp .env.example .env.local     # fill in your API base URL
npm run dev
```

---

## Author

**Wahed Nur**
Built for Nurain Motorcycle Meter Service Center — designed, specified, and iteratively developed to reflect the real day-to-day operations of an active repair business.
