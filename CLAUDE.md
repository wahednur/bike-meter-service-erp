# Bike Meter ERP

## Project structure
- `backend/` — Django + Django REST Framework
- `frontend/` — Next.js 16
- Always be clear about which folder any given piece of work belongs in.

## Business rules

- Customers and Suppliers never log in — only System Users (Admin/Staff) log in.
- An invoice stays "open" until fully paid — do not create a new invoice for a customer while they still have an unpaid/partially-paid invoice.
- When a customer underpays across multiple meters in one invoice, the paid amount is split evenly (averaged) across those meter entries.
- Product cost is recalculated using a weighted average when restocked — never create a duplicate product entry.
- Every model should support soft delete (never hard-delete records).
- Every model should have `created_at`, `updated_at`, and `created_by` fields for audit purposes.
