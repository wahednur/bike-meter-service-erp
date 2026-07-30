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
  description: string;
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
  description?: string;
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
  // Force-close write-off (see Invoice.waived_amount) - separate from a
  // discount, so it's shown on its own in the ledger too.
  waived_amount: string;
  waived_note: string;
}

export interface CustomerLedger {
  customer: Customer;
  invoices: CustomerLedgerInvoice[];
  total_billed: string;
  total_paid: string;
  total_due: string;
}

export interface CustomerCsvPreview {
  headers: string[];
  rows: Record<string, string>[];
}

export interface CustomerCsvColumnMapping {
  name: string;
  phone: string;
}

export interface CustomerCsvSkippedRow {
  row: number;
  phone: string;
  reason: string;
}

export interface CustomerCsvFailedRow {
  row: number;
  reason: string;
}

export interface CustomerCsvImportResult {
  total: number;
  created_count: number;
  skipped_count: number;
  failed_count: number;
  created: Customer[];
  skipped: CustomerCsvSkippedRow[];
  failed: CustomerCsvFailedRow[];
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
  description: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface MeterPayload {
  brand: string;
  model: string;
  cc: number;
  memory_type: "EEPROM" | "MCU";
  ic_mcu_model: string;
  sales_price: number;
  description?: string;
  /** undefined = don't touch the existing image (PATCH); null is not a
   * valid value here - there's no "clear image" affordance yet. */
  image?: File;
}

export interface MeterServiceBreakdownItem {
  service_name: string;
  count: number;
  revenue: string;
}

export interface MeterServiceStats {
  total_services_count: number;
  total_revenue: string;
  last_service_date: string | null;
  service_breakdown: MeterServiceBreakdownItem[];
}

/** GET /api/meters/{id}/service-history/ - one row per visit (itemized,
 * unlike the aggregated MeterServiceStats above), newest first. */
export interface MeterServiceHistoryEntry {
  id: number;
  invoice_id: number;
  invoice_no: string;
  customer_name: string;
  serial_number: string | null;
  condition_note: string[];
  previous_km: number | null;
  current_km: number | null;
  service_date: string;
}

export interface MileageCorrectionDevice {
  id: number;
  name: string;
  purchase_price: string;
  purchase_date: string;
  memory_type_support: "EEPROM" | "MCU" | "BOTH";
  total_jobs_count: number;
  total_revenue_generated: string;
  cost_recovered: boolean;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface MileageCorrectionDevicePayload {
  name: string;
  purchase_price: number;
  purchase_date: string;
  memory_type_support: "EEPROM" | "MCU" | "BOTH";
}

export const SERVICE_CATEGORY_NAMES = [
  "MILEAGE_CORRECTION",
  "METER_REPAIR",
  "DISPLAY_REPAIR",
  "MAIN_BOARD_REPAIR",
  "LIGHT_REPAIR",
  "KILOMETER_FREEZE_REPAIR",
  "POWER_PROBLEM_REPAIR",
  "OTHERS",
] as const;

export type ServiceCategoryName = (typeof SERVICE_CATEGORY_NAMES)[number];

export interface ServiceCategory {
  id: number;
  name: ServiceCategoryName;
  name_display: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface ServiceCategoryPayload {
  name: ServiceCategoryName;
}

export interface ServiceItem {
  id: number;
  category: number;
  category_name: string;
  name: string;
  service_price: string;
  description: string;
  image: string | null;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface ServicePayload {
  category: number;
  name: string;
  service_price: number;
  description?: string;
  image?: File;
}

export interface ProductItem {
  id: number;
  name: string;
  sku: string;
  supplier: number;
  buy_price: string;
  sale_price: string;
  image: string | null;
  description: string;
  current_stock_quantity: number;
  profit_margin: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface ProductPayload {
  name: string;
  sku?: string;
  supplier: number;
  sale_price: number;
  description?: string;
  image?: File;
}

export interface RestockPayload {
  quantity: number;
  unit_price: number;
  extra_costs?: number;
}

/** GET /api/purchases/ (list/retrieve) - a multi-product purchase, with
 * shared_extra_costs already split proportionally across line_items (see
 * apps.products.services.compute_purchase_line_shares()). */
export interface PurchaseLineItem {
  id: number;
  purchase: number;
  product: number;
  product_name: string;
  quantity: number;
  unit_price: string;
  subtotal: string;
  extra_cost_share: string;
  landed_unit_cost: string;
}

export interface Purchase {
  id: number;
  supplier: number;
  supplier_name: string;
  purchase_date: string;
  shared_extra_costs: string;
  note: string;
  is_processed: boolean;
  processed_at: string | null;
  line_items: PurchaseLineItem[];
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface CreatePurchaseLineItemPayload {
  product: number;
  quantity: number;
  unit_price: number;
}

export interface CreatePurchasePayload {
  supplier: number;
  purchase_date: string;
  shared_extra_costs?: number;
  note?: string;
  line_items: CreatePurchaseLineItemPayload[];
}

export type InvoiceStatus = "UNPAID" | "PARTIAL" | "PAID" | "CANCELLED";

export interface InvoiceMeterEntry {
  id: number;
  invoice: number;
  meter: number;
  meter_title: string;
  meter_brand: string;
  meter_model: string;
  meter_cc: number;
  // Optional - a meter entry can be recorded without one.
  serial_number: string | null;
  // A mix of CONDITION_TAG_PRESETS (see lib/invoice-utils.ts) and/or
  // free-text entries, e.g. ["Power IC Problem", "Display Problem"].
  // Optional - defaults to ["Good"] server-side when nothing is selected.
  condition_note: string[];
  previous_km: number | null;
  current_km: number | null;
  // Absent entirely on the public invoice view - the shop owner doesn't
  // want customers seeing which programmer was used for a correction.
  mileage_correction_device?: number | null;
  mileage_correction_device_name?: string | null;
  paid_share: string;
  service_date: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface InvoiceServiceLine {
  id: number;
  invoice: number;
  meter_entry: number | null;
  // Full nested entry, not just the id - this is the only place a
  // mileage-correction line's meter shows up; there is no separate
  // top-level meter list anywhere. Null when this line has no linked
  // meter entry (a regular repair service with nothing to attach to).
  meter_entry_detail: InvoiceMeterEntry | null;
  service: number;
  service_name: string;
  // The labor/service portion of the charge.
  price_charged: string;
  // Combination-repair part (e.g. Display Repair's polarizer paper vs a
  // full panel swap) - independent of price_charged, never combined.
  product_used: number | null;
  product_used_name: string | null;
  product_price: string;
  line_total: string;
  asset_used: number | null;
  asset_used_name: string | null;
  // When the work was actually done - independent of created_at.
  added_date: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface InvoiceProductLine {
  id: number;
  invoice: number;
  product: number;
  product_name: string;
  quantity: number;
  price_charged: string;
  line_total: string;
  // When the product was actually sold - independent of created_at.
  added_date: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export type PaymentMethod = "CASH" | "BKASH" | "NAGAD" | "BANK_TRANSFER" | "CARD" | "OTHER";

export interface InvoicePayment {
  id: number;
  invoice: number;
  invoice_no: string;
  customer_name: string;
  amount: string;
  payment_method: PaymentMethod;
  payment_date: string;
  note: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface PaymentListFilters {
  customer?: number;
  dateFrom?: string;
  dateTo?: string;
}

export interface AddPaymentPayload {
  amount: number;
  payment_method?: PaymentMethod;
  payment_date?: string;
  note?: string;
}

export interface ApplyDiscountPayload {
  discount_amount: number;
  discount_note?: string;
}

export interface InvoiceAuditLogEntry {
  id: number;
  action: string;
  description: string;
  /** Omitted entirely (not just null) on the public share-link view - the
   * shop owner doesn't want customers seeing which staff member performed
   * an action, e.g. who applied a discount. */
  user?: string | null;
  created_at: string;
}

/** GET /api/invoices/ (list) - lighter than InvoiceDetail, no nested lines. */
export interface Invoice {
  id: number;
  customer: number;
  customer_name: string;
  customer_phone: string;
  invoice_no: string;
  status: InvoiceStatus;
  total_amount: string;
  paid_amount: string;
  due_amount: string;
  discount_amount: string;
  discount_note: string;
  // Force-close write-off (rule 11) - kept separate from discount_amount.
  waived_amount: string;
  waived_note: string;
  // Editable (Admin only) - see updateInvoiceCreatedDate().
  created_date: string;
  public_share_token: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface InvoiceDetail extends Invoice {
  // No top-level meter list - a Mileage Correction line's meter lives
  // entirely inside its service_lines entry (meter_entry_detail).
  service_lines: InvoiceServiceLine[];
  product_lines: InvoiceProductLine[];
  payments: InvoicePayment[];
  history: InvoiceAuditLogEntry[];
}

/** GET /api/public/invoices/{token}/ - no auth. Same as InvoiceDetail, but
 * a mileage-correction line's meter_entry_detail never carries
 * mileage_correction_device*, and it carries shop branding for the page/
 * footer since the public page can't call the (Staff/Admin-only)
 * shop-profile endpoint itself. */
export interface PublicInvoiceDetail extends InvoiceDetail {
  shop_name: string;
  invoice_footer_text: string;
}

export interface InvoiceListFilters {
  status?: InvoiceStatus;
  customer?: number;
  dateFrom?: string;
  dateTo?: string;
}

/** POST /api/invoices/{id}/service-lines/ - the merged endpoint. For a
 * Mileage Correction service, include `meter` + the usual meter-entry
 * fields instead of a pre-existing `meter_entry` id - the server creates
 * the InvoiceMeterEntry and this line together in one call.
 * `product_used`/`product_price` are for combination repairs - two
 * independent amounts, never folded into price_charged. */
export interface AddServiceLinePayload {
  service: number;
  meter_entry?: number | null;
  price_charged?: number | null;
  product_used?: number | null;
  product_price?: number | null;
  asset_used?: number | null;
  added_date?: string | null;
  meter?: number | null;
  serial_number?: string;
  condition_note?: string[];
  previous_km?: number | null;
  current_km?: number | null;
  mileage_correction_device?: number | null;
}

/** PATCH /api/invoices/{id}/service-lines/{lineId}/ - every field is
 * optional; omit a key entirely (don't send it as undefined/null) to leave
 * that field untouched on the line/its linked meter entry. `service` lets
 * the line be fully replaced (swap which service it bills) without a
 * delete+recreate - pass `meter` (+ the meter-entry fields) in the same
 * request if swapping to Mileage Correction and the line doesn't already
 * have a meter entry. `reason` is required only if the invoice is Paid/
 * force-closed (Admin only in that case). */
export interface UpdateServiceLinePayload {
  service?: number;
  meter?: number | null;
  price_charged?: number | null;
  product_used?: number | null;
  product_price?: number | null;
  asset_used?: number | null;
  added_date?: string;
  serial_number?: string;
  condition_note?: string[];
  previous_km?: number | null;
  current_km?: number | null;
  mileage_correction_device?: number | null;
  reason?: string;
}

export interface AddProductLinePayload {
  product: number;
  quantity: number;
  price_charged?: number | null;
  added_date?: string | null;
}

/** PATCH /api/invoices/{id}/product-lines/{lineId}/ - `product` lets the
 * line be fully replaced (rule 8) without a delete+recreate. `reason` is
 * required only if the invoice is Paid/force-closed. */
export interface UpdateProductLinePayload {
  product?: number;
  quantity?: number;
  price_charged?: number | null;
  added_date?: string;
  reason?: string;
}

/** Body accepted by DELETE on a service/product line - only meaningful
 * (and only required) when the invoice is no longer in its normal
 * editable state (Paid/force-closed). */
export interface DeleteLinePayload {
  reason?: string;
}

/** POST /api/invoices/{id}/force-close/ - Admin only. `note` is
 * mandatory: explains why the remaining balance is being written off. */
export interface ForceCloseInvoicePayload {
  note: string;
}

/** POST /api/invoices/{id}/created-date/ - Admin only. `reason` is
 * required only if the invoice is Paid/force-closed. */
export interface UpdateInvoiceCreatedDatePayload {
  created_date: string;
  reason?: string;
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
  // A loan can contribute both an overdue row and a separate upcoming row
  // at once (e.g. installment 3 is unpaid and overdue while installment 4
  // is unpaid and due soon) - this distinguishes them rather than one
  // silently replacing the other.
  is_overdue: boolean;
}

export interface TopExpenseCategory {
  category: string;
  category_display: string;
  amount: string;
}

export interface AdminDashboardSummary {
  date: string;
  today_income: string;
  today_invoice_count: number;
  today_total_amount: string;
  total_income_all_time: string;
  pending_dues: PendingDues;
  red_listed_customers_count: number;
  low_stock_products: LowStockProduct[];
  low_stock_threshold: number;
  upcoming_loan_installments: UpcomingInstallment[];
  today_expense: string;
  this_week_expense: string;
  this_month_expense: string;
  total_expense_all_time: string;
  net_profit_today: string;
  top_expense_category_this_month: TopExpenseCategory | null;
  this_week_income: string;
  this_month_income: string;
  predicted_month_income: string;
  income_prediction_gap: string;
  is_early_month_estimate: boolean;
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

export type ReportPeriod = "daily" | "weekly" | "monthly" | "yearly" | "total";

export interface ExpenseReportRow {
  period_start: string;
  expense: string;
}

export interface ExpenseBreakdown {
  product_restocks: string;
  asset_purchases: string;
  device_purchases: string;
}

export interface ExpenseReport {
  period: string;
  rows: ExpenseReportRow[];
  total_expenses: string;
  breakdown: ExpenseBreakdown;
}

export interface SalesReportRow {
  type: "service" | "product";
  date: string;
  invoice_no: string;
  customer_name: string;
  item_name: string;
  quantity: number;
  unit_price: string;
  line_total: string;
}

export interface SalesReport {
  rows: SalesReportRow[];
  total_sales: string;
  line_count: number;
}

export interface PurchaseReportRow {
  type: "product_restock" | "asset" | "mileage_correction_device";
  date: string;
  name: string;
  supplier_name: string | null;
  quantity: number;
  amount: string;
}

export interface PurchaseReport {
  rows: PurchaseReportRow[];
  total_purchases: string;
  transaction_count: number;
}

export interface ProfitLossReport {
  total_income: string;
  total_expenses: string;
  expense_breakdown: ExpenseBreakdown;
  profit_loss: string;
  status: "PROFIT" | "LOSS" | "BREAK_EVEN";
}

export interface StockReportRow {
  id: number;
  name: string;
  sku: string;
  current_stock_quantity: number;
  buy_price: string;
  sale_price: string;
  stock_value: string;
  potential_sale_value: string;
}

export interface StockReport {
  rows: StockReportRow[];
  total_products: number;
  total_stock_value: string;
  total_potential_sale_value: string;
}

export interface DueReportRow {
  invoice_no: string;
  customer_name: string;
  status: "UNPAID" | "PARTIAL";
  created_date: string;
  total_amount: string;
  paid_amount: string;
  due_amount: string;
}

export interface DueReport {
  rows: DueReportRow[];
  invoice_count: number;
  total_due: string;
}

export type CashbookCategory =
  | "customer_payment"
  | "loan_disbursement"
  | "product_restock"
  | "asset_purchase"
  | "asset_incident"
  | "device_purchase"
  | "loan_installment";

export interface CashbookEntry {
  date: string;
  direction: "IN" | "OUT";
  category: CashbookCategory;
  description: string;
  amount: string;
  running_balance: string;
}

export interface CashbookReport {
  entries: CashbookEntry[];
  total_in: string;
  total_out: string;
  net: string;
}

export interface ReportDateRange {
  fromDate?: string;
  toDate?: string;
}

export type TopCustomersSortBy = "total_billed_amount" | "invoice_count";

export interface TopCustomerRow {
  customer_id: number;
  customer_name: string;
  invoice_count: number;
  total_billed_amount: string;
  total_paid_amount: string;
  total_due_amount: string;
}

export interface TopCustomersReport {
  rows: TopCustomerRow[];
  customer_count: number;
  sort_by: TopCustomersSortBy;
}

export interface PaymentDelayRow {
  customer_id: number;
  customer_name: string;
  invoice_nos: string[];
  days_delayed: number;
  amount_due: string;
}

export interface PaymentDelayReport {
  rows: PaymentDelayRow[];
  customer_count: number;
}

export interface ServicePerformanceRow {
  service_id: number;
  service_name: string;
  times_performed: number;
  total_revenue: string;
  average_price: string;
}

export interface ServicePerformanceReport {
  rows: ServicePerformanceRow[];
  service_count: number;
}

// --- assets ----------------------------------------------------------------------

export interface Asset {
  id: number;
  name: string;
  purchase_price: string;
  purchase_date: string;
  supplier: number | null;
  has_warranty: boolean;
  warranty_note: string;
  description: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface AssetPayload {
  name: string;
  purchase_price: number;
  purchase_date: string;
  supplier?: number | null;
  has_warranty?: boolean;
  warranty_note?: string;
  description?: string;
}

export type AssetIncidentType = "DAMAGED" | "REPAIRED";

export interface AssetIncident {
  id: number;
  asset: number;
  type: AssetIncidentType;
  cost: string;
  date: string;
  note: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface AssetIncidentPayload {
  asset: number;
  type: AssetIncidentType;
  cost?: number;
  date: string;
  note?: string;
}

export interface CostRecoveryReportItem {
  type: "asset" | "mileage_correction_device";
  id: number;
  name: string;
  purchase_price: string;
  total_incident_cost: string;
  total_cost_incurred: string;
  total_revenue: string;
  total_jobs_count: number;
  has_usage: boolean;
  profit_loss: string;
  status: "NOT_LINKED" | "PROFIT" | "LOSS" | "BREAK_EVEN";
  cost_recovered: boolean;
}

// --- loans -------------------------------------------------------------------------

export type LenderType = "BANK" | "NGO";
export type InstallmentFrequency = "WEEKLY" | "MONTHLY";

export interface Loan {
  id: number;
  lender_name: string;
  lender_type: LenderType;
  loan_amount: string;
  deposit_amount: string;
  interest_amount: string;
  total_payable: string;
  total_installments: number;
  installment_amount: string;
  installment_frequency: InstallmentFrequency;
  start_date: string;
  installments_paid_count: number;
  installments_remaining: number;
  amount_paid_so_far: string;
  amount_remaining: string;
  // The single earliest unpaid installment - all three null once the loan
  // is fully paid off. next_installment_is_overdue distinguishes "due
  // soon" from "already late" for the same underlying installment (see
  // apps.loans.services.compute_next_installment() on the backend).
  next_installment_number: number | null;
  next_installment_due_date: string | null;
  next_installment_is_overdue: boolean | null;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface LoanPayload {
  lender_name: string;
  lender_type: LenderType;
  loan_amount: number;
  deposit_amount?: number;
  interest_amount?: number;
  total_installments: number;
  installment_amount: number;
  installment_frequency: InstallmentFrequency;
  start_date: string;
}

export interface LoanInstallmentPayment {
  id: number;
  loan: number;
  amount_paid: string;
  payment_date: string;
  installment_number: number;
  attachment: string | null;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface AddInstallmentPaymentPayload {
  loan: number;
  amount_paid: number;
  payment_date: string;
  installment_number: number;
  /** Optional receipt photo/PDF - image or pdf, under 300KB (enforced server-side too; images are compressed under 50KB after upload). */
  attachment?: File;
}

// --- shop profile ------------------------------------------------------------------

export interface ShopProfile {
  id: number;
  shop_name: string;
  address: string;
  phone: string;
  invoice_footer_text: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface ShopProfilePayload {
  shop_name?: string;
  address?: string;
  phone?: string;
  invoice_footer_text?: string;
}

// --- expenses ------------------------------------------------------------------

export type ExpenseCategory = "RENT" | "ELECTRICITY" | "TRANSPORT" | "MISC";

export interface Expense {
  id: number;
  category: ExpenseCategory;
  category_display: string;
  amount: string;
  date: string;
  note: string;
  created_at: string;
  updated_at: string;
  created_by: number | null;
}

export interface ExpensePayload {
  category: ExpenseCategory;
  amount: number;
  date: string;
  note?: string;
}

export interface ExpenseListFilters {
  category?: ExpenseCategory;
  dateFrom?: string;
  dateTo?: string;
}

// --- audit log ------------------------------------------------------------------

export interface SystemUser {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  role: UserRole;
  is_active: boolean;
}

export type AuditEntrySource = "AUTO" | "BUSINESS_EVENT";

export interface AuditFeedEntry {
  id: string;
  timestamp: string;
  user: string | null;
  source: AuditEntrySource;
  model: string;
  model_display: string;
  object_id: string;
  record: string;
  action: string;
  action_display: string;
  summary: string;
}

export interface AuditFeedResponse {
  count: number;
  page: number;
  page_size: number;
  total_pages: number;
  results: AuditFeedEntry[];
}

export interface AuditLogFilters {
  fromDate?: string;
  toDate?: string;
  user?: string;
  model?: string;
  action?: string;
  page?: number;
  pageSize?: number;
}
