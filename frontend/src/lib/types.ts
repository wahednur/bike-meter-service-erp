export type UserRole = "admin" | "staff";

export interface AuthUser {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  role: UserRole;
}

export interface LoginResponse {
  access: string;
  refresh: string;
  user: AuthUser;
}

export interface Customer {
  id: number;
  name: string;
  phone: string;
  address: string;
  email: string | null;
  is_red_listed: boolean;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface CustomerPayload {
  name: string;
  phone: string;
  address?: string;
  email?: string | null;
}

export interface Supplier {
  id: number;
  name: string;
  phone: string;
  address: string;
  note: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface SupplierPayload {
  name: string;
  phone: string;
  address?: string;
  note?: string;
}

export interface CustomerLedgerInvoice {
  id: number;
  invoice_no: string;
  status: InvoiceStatus;
  created_date: string;
  total_amount: string;
  paid_amount: string;
  outstanding_amount: string;
}

export interface CustomerLedger {
  customer: Customer;
  invoices: CustomerLedgerInvoice[];
  total_billed: string;
  total_paid: string;
  total_due: string;
}

export interface SupplierLedgerProduct {
  id: number;
  name: string;
  sku: string;
  buy_price: string;
  sale_price: string;
  current_stock_quantity: number;
  stock_value: string;
}

export interface SupplierLedger {
  supplier: Supplier;
  products: SupplierLedgerProduct[];
  total_purchase_amount: string;
  purchases_in_range: string;
  payment_status: string;
}

export interface SupplierProfitAnalysisRow {
  supplier_id: number | null;
  supplier_name: string;
  product_count: number;
  avg_buy_price: number | string;
  avg_sale_price: number | string;
  avg_profit_margin: number | string;
}

export interface Meter {
  id: number;
  brand: string;
  model: string;
  cc: number;
  memory_type: "EEPROM" | "MCU";
  ic_mcu_model: string;
  title: string;
  sales_price: string;
  image: string | null;
}

export interface MileageCorrectionDevice {
  id: number;
  name: string;
  purchase_price: string;
  memory_type_support: "EEPROM" | "MCU" | "BOTH";
}

export interface ServiceItem {
  id: number;
  category: number;
  category_name: string;
  name: string;
  service_price: string;
  description: string;
}

export interface ProductItem {
  id: number;
  name: string;
  sku: string;
  sale_price: string;
  current_stock_quantity: number;
}

export type InvoiceStatus = "UNPAID" | "PARTIAL" | "PAID" | "CANCELLED";

export interface InvoiceMeterEntry {
  id: number;
  invoice: number;
  meter: number;
  serial_number: string;
  condition_note: string;
  previous_km: number | null;
  current_km: number | null;
  mileage_correction_device: number | null;
  paid_share: string;
  service_date: string;
}

export interface InvoiceServiceLine {
  id: number;
  invoice: number;
  meter_entry: number | null;
  service: number;
  price_charged: string;
}

export interface InvoiceProductLine {
  id: number;
  invoice: number;
  product: number;
  quantity: number;
  price_charged: string;
  line_total: number;
}

export interface InvoiceDetail {
  id: number;
  customer: number;
  invoice_no: string;
  status: InvoiceStatus;
  total_amount: string;
  paid_amount: string;
  outstanding_amount: number;
  created_date: string;
  public_share_token: string;
  meter_entries: InvoiceMeterEntry[];
  service_lines: InvoiceServiceLine[];
  product_lines: InvoiceProductLine[];
}

export interface AddMeterEntryPayload {
  meter: number;
  serial_number: string;
  condition_note?: string;
  previous_km?: number | null;
  current_km?: number | null;
  mileage_correction_device?: number | null;
}

export interface AddServiceLinePayload {
  service: number;
  meter_entry?: number | null;
  price_charged?: number | null;
}

export interface AddProductLinePayload {
  product: number;
  quantity: number;
  price_charged?: number | null;
}

export interface PendingDues {
  invoice_count: number;
  total_due: string;
}

export interface LowStockProduct {
  id: number;
  name: string;
  sku: string;
  current_stock_quantity: number;
}

export interface UpcomingInstallment {
  loan_id: number;
  lender_name: string;
  installment_number: number;
  due_date: string;
  installment_amount: string;
}

export interface AdminDashboardSummary {
  date: string;
  today_income: string;
  pending_dues: PendingDues;
  red_listed_customers_count: number;
  low_stock_products: LowStockProduct[];
  low_stock_threshold: number;
  upcoming_loan_installments: UpcomingInstallment[];
  upcoming_days: number;
}

export interface IncomeReportRow {
  period_start: string;
  income: string;
}

export interface IncomeReport {
  period: string;
  rows: IncomeReportRow[];
  total_income: string;
}
