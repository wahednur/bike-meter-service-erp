import {
  clearSession,
  getAccessToken,
  getRefreshToken,
  setAccessToken,
} from "./token-storage";
import type {
  AddInstallmentPaymentPayload,
  AddPaymentPayload,
  AddProductLinePayload,
  AddServiceLinePayload,
  AdminDashboardSummary,
  ApplyDiscountPayload,
  Asset,
  AssetIncident,
  AssetIncidentPayload,
  AssetPayload,
  AuditFeedResponse,
  AuditLogFilters,
  CashbookReport,
  CostRecoveryReportItem,
  CreatePurchasePayload,
  Customer,
  CustomerCsvColumnMapping,
  CustomerCsvImportResult,
  CustomerCsvPreview,
  CustomerLedger,
  CustomerPayload,
  DeleteLinePayload,
  DueReport,
  Expense,
  ExpenseListFilters,
  ExpensePayload,
  ExpenseReport,
  ForceCloseInvoicePayload,
  IncomeReport,
  Invoice,
  InvoiceDetail,
  InvoiceListFilters,
  InvoicePayment,
  InvoiceProductLine,
  InvoiceServiceLine,
  Loan,
  LoanInstallmentPayment,
  LoanPayload,
  LoginResponse,
  MeterPayload,
  MeterServiceHistoryEntry,
  MeterServiceStats,
  MileageCorrectionDevice,
  MileageCorrectionDevicePayload,
  Meter,
  PaymentDelayReport,
  PaymentListFilters,
  ProductItem,
  ProductPayload,
  ProfitLossReport,
  PublicInvoiceDetail,
  Purchase,
  PurchaseReport,
  ReportDateRange,
  ReportPeriod,
  RestockPayload,
  SalesReport,
  ServiceCategory,
  ServiceCategoryPayload,
  ServiceItem,
  ServicePayload,
  ServicePerformanceReport,
  ShopProfile,
  ShopProfilePayload,
  StockReport,
  Supplier,
  SupplierLedger,
  SupplierPayload,
  SupplierProfitAnalysisRow,
  TopCustomersReport,
  TopCustomersSortBy,
  SystemUser,
  UpdateInvoiceCreatedDatePayload,
  UpdateProductLinePayload,
  UpdateServiceLinePayload,
} from "./types";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api";

export class ApiError extends Error {
  status: number;
  fieldErrors?: Record<string, string[]>;

  constructor(status: number, message: string, fieldErrors?: Record<string, string[]>) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.fieldErrors = fieldErrors;
  }
}

/** DRF errors show up in a few different shapes depending on where they
 * came from - a raw ValidationError(str(exc)) is a plain string array, a
 * serializer field error is {field: [...]}, and permission/auth failures
 * are {detail: "..."}. Normalize all of them into one message. */
function extractErrorMessage(body: unknown): { message: string; fieldErrors?: Record<string, string[]> } {
  if (Array.isArray(body)) {
    return { message: body.map(String).join(" ") };
  }
  if (body && typeof body === "object") {
    const obj = body as Record<string, unknown>;
    if (typeof obj.detail === "string") {
      return { message: obj.detail };
    }
    const fieldErrors: Record<string, string[]> = {};
    const messages: string[] = [];
    for (const [key, value] of Object.entries(obj)) {
      if (Array.isArray(value)) {
        const strings = value.map(String);
        fieldErrors[key] = strings;
        messages.push(...strings);
      }
    }
    if (messages.length > 0) {
      return { message: messages.join(" "), fieldErrors };
    }
  }
  return { message: "Something went wrong. Please try again." };
}

/** Builds a multipart/form-data body for endpoints that accept an image
 * upload alongside plain fields (Meter/Product/Service create+update).
 * undefined/null values are omitted entirely rather than sent as empty
 * strings - on a PATCH that means "leave this field, including any
 * existing image, unchanged" rather than accidentally clearing it. */
function toFormData(payload: object): FormData {
  const formData = new FormData();
  for (const [key, value] of Object.entries(payload as Record<string, unknown>)) {
    if (value === undefined || value === null) continue;
    if (value instanceof File) {
      formData.append(key, value);
    } else if (typeof value === "boolean") {
      formData.append(key, value ? "true" : "false");
    } else {
      formData.append(key, String(value));
    }
  }
  return formData;
}

async function rawRequest(path: string, options: RequestInit, accessToken: string | null): Promise<Response> {
  const headers = new Headers(options.headers);
  // A FormData body (image uploads) must NOT get an explicit Content-Type -
  // the browser sets multipart/form-data with the right boundary itself.
  // Manually setting it here would strip that boundary and the server
  // would fail to parse the request at all.
  if (!(options.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }
  if (accessToken) headers.set("Authorization", `Bearer ${accessToken}`);
  return fetch(`${API_BASE_URL}${path}`, { ...options, headers });
}

async function tryRefreshAccessToken(): Promise<string | null> {
  const refresh = getRefreshToken();
  if (!refresh) return null;

  const response = await fetch(`${API_BASE_URL}/auth/refresh/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh }),
  });
  if (!response.ok) return null;

  const data = (await response.json()) as { access: string };
  setAccessToken(data.access);
  return data.access;
}

/** Core request helper: attaches the JWT, and on a 401 tries exactly one
 * silent refresh + retry before giving up and clearing the session. */
export async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const accessToken = getAccessToken();
  let response = await rawRequest(path, options, accessToken);

  if (response.status === 401 && accessToken) {
    const refreshed = await tryRefreshAccessToken();
    if (refreshed) {
      response = await rawRequest(path, options, refreshed);
    } else {
      clearSession();
      if (typeof window !== "undefined") {
        window.location.href = "/login";
      }
    }
  }

  const contentType = response.headers.get("content-type") ?? "";
  const body = contentType.includes("application/json") ? await response.json().catch(() => null) : null;

  if (!response.ok) {
    const { message, fieldErrors } = extractErrorMessage(body);
    throw new ApiError(response.status, message, fieldErrors);
  }

  return body as T;
}

// --- auth ---------------------------------------------------------------------

export function login(identifier: string, password: string): Promise<LoginResponse> {
  return apiFetch<LoginResponse>("/auth/login/", {
    method: "POST",
    body: JSON.stringify({ identifier, password }),
  });
}

export function logout(refresh: string): Promise<void> {
  return apiFetch<void>("/auth/logout/", {
    method: "POST",
    body: JSON.stringify({ refresh }),
  });
}

// --- dashboard ------------------------------------------------------------------

export function getAdminDashboard(): Promise<AdminDashboardSummary> {
  return apiFetch<AdminDashboardSummary>("/reports/admin-dashboard/");
}

export function getIncomeReport(params: { period: "daily" | "weekly" | "monthly" | "yearly" | "total"; fromDate?: string; toDate?: string }): Promise<IncomeReport> {
  const query = new URLSearchParams({ period: params.period });
  if (params.fromDate) query.set("from_date", params.fromDate);
  if (params.toDate) query.set("to_date", params.toDate);
  return apiFetch<IncomeReport>(`/reports/income/?${query.toString()}`);
}

// --- reports (Phase 11) -----------------------------------------------------------

function dateRangeQuery(range: ReportDateRange = {}): string {
  const query = new URLSearchParams();
  if (range.fromDate) query.set("from_date", range.fromDate);
  if (range.toDate) query.set("to_date", range.toDate);
  const queryString = query.toString();
  return queryString ? `?${queryString}` : "";
}

export function getExpenseReport(period: ReportPeriod, range: ReportDateRange = {}): Promise<ExpenseReport> {
  const query = new URLSearchParams({ period });
  if (range.fromDate) query.set("from_date", range.fromDate);
  if (range.toDate) query.set("to_date", range.toDate);
  return apiFetch<ExpenseReport>(`/reports/expenses/?${query.toString()}`);
}

export function getSalesReport(range: ReportDateRange = {}): Promise<SalesReport> {
  return apiFetch<SalesReport>(`/reports/sales/${dateRangeQuery(range)}`);
}

export function getPurchaseReport(range: ReportDateRange = {}): Promise<PurchaseReport> {
  return apiFetch<PurchaseReport>(`/reports/purchases/${dateRangeQuery(range)}`);
}

export function getProfitLossReport(range: ReportDateRange = {}): Promise<ProfitLossReport> {
  return apiFetch<ProfitLossReport>(`/reports/profit-loss/${dateRangeQuery(range)}`);
}

export function getStockReport(): Promise<StockReport> {
  return apiFetch<StockReport>("/reports/stock/");
}

export function getDueReport(range: ReportDateRange = {}): Promise<DueReport> {
  return apiFetch<DueReport>(`/reports/due/${dateRangeQuery(range)}`);
}

export function getTopCustomersReport(
  range: ReportDateRange = {},
  sortBy: TopCustomersSortBy = "total_billed_amount",
): Promise<TopCustomersReport> {
  const query = new URLSearchParams();
  if (range.fromDate) query.set("from_date", range.fromDate);
  if (range.toDate) query.set("to_date", range.toDate);
  query.set("sort_by", sortBy);
  return apiFetch<TopCustomersReport>(`/reports/top-customers/?${query.toString()}`);
}

export function getPaymentDelayReport(range: ReportDateRange = {}): Promise<PaymentDelayReport> {
  return apiFetch<PaymentDelayReport>(`/reports/payment-delay/${dateRangeQuery(range)}`);
}

export function getServicePerformanceReport(range: ReportDateRange = {}): Promise<ServicePerformanceReport> {
  return apiFetch<ServicePerformanceReport>(`/reports/service-performance/${dateRangeQuery(range)}`);
}

export function getCashbookReport(range: ReportDateRange = {}): Promise<CashbookReport> {
  return apiFetch<CashbookReport>(`/reports/cashbook/${dateRangeQuery(range)}`);
}

// --- customers --------------------------------------------------------------------

export function listCustomers(): Promise<Customer[]> {
  return apiFetch<Customer[]>("/customers/");
}

export function getCustomer(id: number): Promise<Customer> {
  return apiFetch<Customer>(`/customers/${id}/`);
}

export function createCustomer(payload: CustomerPayload): Promise<Customer> {
  return apiFetch<Customer>("/customers/", { method: "POST", body: JSON.stringify(payload) });
}

export function updateCustomer(id: number, payload: CustomerPayload): Promise<Customer> {
  return apiFetch<Customer>(`/customers/${id}/`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteCustomer(id: number): Promise<void> {
  return apiFetch<void>(`/customers/${id}/`, { method: "DELETE" });
}

export function getCustomerLedger(id: number, range: ReportDateRange = {}): Promise<CustomerLedger> {
  return apiFetch<CustomerLedger>(`/customers/${id}/ledger/${dateRangeQuery(range)}`);
}

export function previewCustomerCsv(file: File): Promise<CustomerCsvPreview> {
  const formData = new FormData();
  formData.append("file", file);
  return apiFetch<CustomerCsvPreview>("/customers/import/preview/", { method: "POST", body: formData });
}

export function importCustomersCsv(
  file: File,
  columnMapping: CustomerCsvColumnMapping,
): Promise<CustomerCsvImportResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("column_mapping", JSON.stringify(columnMapping));
  return apiFetch<CustomerCsvImportResult>("/customers/import/", { method: "POST", body: formData });
}

// --- suppliers --------------------------------------------------------------------

export function listSuppliers(): Promise<Supplier[]> {
  return apiFetch<Supplier[]>("/suppliers/");
}

export function getSupplier(id: number): Promise<Supplier> {
  return apiFetch<Supplier>(`/suppliers/${id}/`);
}

export function createSupplier(payload: SupplierPayload): Promise<Supplier> {
  return apiFetch<Supplier>("/suppliers/", { method: "POST", body: JSON.stringify(payload) });
}

export function updateSupplier(id: number, payload: SupplierPayload): Promise<Supplier> {
  return apiFetch<Supplier>(`/suppliers/${id}/`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteSupplier(id: number): Promise<void> {
  return apiFetch<void>(`/suppliers/${id}/`, { method: "DELETE" });
}

export function getSupplierLedger(id: number, range: ReportDateRange = {}): Promise<SupplierLedger> {
  return apiFetch<SupplierLedger>(`/suppliers/${id}/ledger/${dateRangeQuery(range)}`);
}

export function getSupplierProfitAnalysis(): Promise<SupplierProfitAnalysisRow[]> {
  return apiFetch<SupplierProfitAnalysisRow[]>("/products/supplier-profit-analysis/");
}

// --- meters -------------------------------------------------------------------

export function listMeters(): Promise<Meter[]> {
  return apiFetch<Meter[]>("/meters/");
}

export function getMeter(id: number): Promise<Meter> {
  return apiFetch<Meter>(`/meters/${id}/`);
}

export function createMeter(payload: MeterPayload): Promise<Meter> {
  return apiFetch<Meter>("/meters/", { method: "POST", body: toFormData(payload) });
}

export function updateMeter(id: number, payload: MeterPayload): Promise<Meter> {
  return apiFetch<Meter>(`/meters/${id}/`, { method: "PATCH", body: toFormData(payload) });
}

export function deleteMeter(id: number): Promise<void> {
  return apiFetch<void>(`/meters/${id}/`, { method: "DELETE" });
}

export function getMeterStats(id: number): Promise<MeterServiceStats> {
  return apiFetch<MeterServiceStats>(`/meters/${id}/stats/`);
}

export function getMeterServiceHistory(id: number): Promise<MeterServiceHistoryEntry[]> {
  return apiFetch<MeterServiceHistoryEntry[]>(`/meters/${id}/service-history/`);
}

// --- mileage correction devices -------------------------------------------------

export function listMileageCorrectionDevices(): Promise<MileageCorrectionDevice[]> {
  return apiFetch<MileageCorrectionDevice[]>("/mileage-correction-devices/");
}

export function getMileageCorrectionDevice(id: number): Promise<MileageCorrectionDevice> {
  return apiFetch<MileageCorrectionDevice>(`/mileage-correction-devices/${id}/`);
}

export function createMileageCorrectionDevice(payload: MileageCorrectionDevicePayload): Promise<MileageCorrectionDevice> {
  return apiFetch<MileageCorrectionDevice>("/mileage-correction-devices/", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateMileageCorrectionDevice(
  id: number,
  payload: MileageCorrectionDevicePayload,
): Promise<MileageCorrectionDevice> {
  return apiFetch<MileageCorrectionDevice>(`/mileage-correction-devices/${id}/`, {
    method: "PATCH",
    body: JSON.stringify(payload),
  });
}

export function deleteMileageCorrectionDevice(id: number): Promise<void> {
  return apiFetch<void>(`/mileage-correction-devices/${id}/`, { method: "DELETE" });
}

// --- service categories ----------------------------------------------------------

export function listServiceCategories(): Promise<ServiceCategory[]> {
  return apiFetch<ServiceCategory[]>("/service-categories/");
}

export function getServiceCategory(id: number): Promise<ServiceCategory> {
  return apiFetch<ServiceCategory>(`/service-categories/${id}/`);
}

export function createServiceCategory(payload: ServiceCategoryPayload): Promise<ServiceCategory> {
  return apiFetch<ServiceCategory>("/service-categories/", { method: "POST", body: JSON.stringify(payload) });
}

export function updateServiceCategory(id: number, payload: ServiceCategoryPayload): Promise<ServiceCategory> {
  return apiFetch<ServiceCategory>(`/service-categories/${id}/`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteServiceCategory(id: number): Promise<void> {
  return apiFetch<void>(`/service-categories/${id}/`, { method: "DELETE" });
}

// --- services ----------------------------------------------------------------

export function listServices(): Promise<ServiceItem[]> {
  return apiFetch<ServiceItem[]>("/services/");
}

export function getService(id: number): Promise<ServiceItem> {
  return apiFetch<ServiceItem>(`/services/${id}/`);
}

export function createService(payload: ServicePayload): Promise<ServiceItem> {
  return apiFetch<ServiceItem>("/services/", { method: "POST", body: toFormData(payload) });
}

export function updateService(id: number, payload: ServicePayload): Promise<ServiceItem> {
  return apiFetch<ServiceItem>(`/services/${id}/`, { method: "PATCH", body: toFormData(payload) });
}

export function deleteService(id: number): Promise<void> {
  return apiFetch<void>(`/services/${id}/`, { method: "DELETE" });
}

// --- products ------------------------------------------------------------------

export function listProducts(): Promise<ProductItem[]> {
  return apiFetch<ProductItem[]>("/products/");
}

export function getProduct(id: number): Promise<ProductItem> {
  return apiFetch<ProductItem>(`/products/${id}/`);
}

export function createProduct(payload: ProductPayload): Promise<ProductItem> {
  return apiFetch<ProductItem>("/products/", { method: "POST", body: toFormData(payload) });
}

export function updateProduct(id: number, payload: ProductPayload): Promise<ProductItem> {
  return apiFetch<ProductItem>(`/products/${id}/`, { method: "PATCH", body: toFormData(payload) });
}

export function deleteProduct(id: number): Promise<void> {
  return apiFetch<void>(`/products/${id}/`, { method: "DELETE" });
}

export function restockProduct(id: number, payload: RestockPayload): Promise<ProductItem> {
  return apiFetch<ProductItem>(`/products/${id}/restock/`, { method: "POST", body: JSON.stringify(payload) });
}

// Read-only live preview - see apps.products.services.generate_sku(). Not
// reserved: the actual create call generates its own SKU if none is given.
export function previewProductSku(supplierId: number, name: string): Promise<{ sku: string }> {
  const query = new URLSearchParams({ supplier: String(supplierId), name });
  return apiFetch<{ sku: string }>(`/products/preview-sku/?${query.toString()}`);
}

// --- purchases (multi-product restock, shared delivery/packaging cost) --------

export function createPurchase(payload: CreatePurchasePayload): Promise<Purchase> {
  return apiFetch<Purchase>("/purchases/", { method: "POST", body: JSON.stringify(payload) });
}

// --- invoices ------------------------------------------------------------------

export function listInvoices(filters: InvoiceListFilters = {}): Promise<Invoice[]> {
  const query = new URLSearchParams();
  if (filters.status) query.set("status", filters.status);
  if (filters.customer) query.set("customer", String(filters.customer));
  if (filters.dateFrom) query.set("date_from", filters.dateFrom);
  if (filters.dateTo) query.set("date_to", filters.dateTo);
  const queryString = query.toString();
  return apiFetch<Invoice[]>(`/invoices/${queryString ? `?${queryString}` : ""}`);
}

export function startInvoice(customerId: number): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>("/invoices/start/", {
    method: "POST",
    body: JSON.stringify({ customer: customerId }),
  });
}

export function getInvoice(invoiceId: number): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>(`/invoices/${invoiceId}/`);
}

export function getPublicInvoice(token: string): Promise<PublicInvoiceDetail> {
  return apiFetch<PublicInvoiceDetail>(`/public/invoices/${token}/`);
}

// addMeterEntry() (POST /invoices/{id}/meter-entries/) is deliberately not
// exposed here - the merged addServiceLine() below creates the meter entry
// and the service line together for a Mileage Correction service, so the
// frontend never needs a standalone "add meter" call.

export function addServiceLine(invoiceId: number, payload: AddServiceLinePayload): Promise<InvoiceServiceLine> {
  return apiFetch<InvoiceServiceLine>(`/invoices/${invoiceId}/service-lines/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateServiceLine(
  invoiceId: number,
  lineId: number,
  payload: UpdateServiceLinePayload,
): Promise<InvoiceServiceLine> {
  return apiFetch<InvoiceServiceLine>(`/invoices/${invoiceId}/service-lines/${lineId}/`, {
    method: "PATCH",
    body: JSON.stringify(payload),
  });
}

export function deleteServiceLine(invoiceId: number, lineId: number, payload: DeleteLinePayload = {}): Promise<void> {
  return apiFetch<void>(`/invoices/${invoiceId}/service-lines/${lineId}/`, {
    method: "DELETE",
    body: JSON.stringify(payload),
  });
}

export function addProductLine(invoiceId: number, payload: AddProductLinePayload): Promise<InvoiceProductLine> {
  return apiFetch<InvoiceProductLine>(`/invoices/${invoiceId}/product-lines/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function updateProductLine(
  invoiceId: number,
  lineId: number,
  payload: UpdateProductLinePayload,
): Promise<InvoiceProductLine> {
  return apiFetch<InvoiceProductLine>(`/invoices/${invoiceId}/product-lines/${lineId}/`, {
    method: "PATCH",
    body: JSON.stringify(payload),
  });
}

export function deleteProductLine(invoiceId: number, lineId: number, payload: DeleteLinePayload = {}): Promise<void> {
  return apiFetch<void>(`/invoices/${invoiceId}/product-lines/${lineId}/`, {
    method: "DELETE",
    body: JSON.stringify(payload),
  });
}

export function addPayment(invoiceId: number, payload: AddPaymentPayload): Promise<InvoicePayment> {
  return apiFetch<InvoicePayment>(`/invoices/${invoiceId}/payments/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function cancelInvoice(invoiceId: number): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>(`/invoices/${invoiceId}/cancel/`, {
    method: "POST",
  });
}

export function applyDiscount(invoiceId: number, payload: ApplyDiscountPayload): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>(`/invoices/${invoiceId}/discount/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

/** Admin-only "accept the remaining balance as final" write-off - records
 * it as invoice.waived_amount (kept separate from a discount) and marks
 * the invoice Paid. See apps.invoices.services.force_close_invoice(). */
export function forceCloseInvoice(invoiceId: number, payload: ForceCloseInvoicePayload): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>(`/invoices/${invoiceId}/force-close/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

/** Admin-only edit of created_date - `reason` is required only if the
 * invoice is Paid/force-closed. */
export function updateInvoiceCreatedDate(
  invoiceId: number,
  payload: UpdateInvoiceCreatedDatePayload,
): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>(`/invoices/${invoiceId}/created-date/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function deleteInvoice(invoiceId: number): Promise<void> {
  return apiFetch<void>(`/invoices/${invoiceId}/`, { method: "DELETE" });
}

// --- assets --------------------------------------------------------------------

export function listAssets(): Promise<Asset[]> {
  return apiFetch<Asset[]>("/assets/");
}

export function getAsset(id: number): Promise<Asset> {
  return apiFetch<Asset>(`/assets/${id}/`);
}

export function createAsset(payload: AssetPayload): Promise<Asset> {
  return apiFetch<Asset>("/assets/", { method: "POST", body: JSON.stringify(payload) });
}

export function updateAsset(id: number, payload: AssetPayload): Promise<Asset> {
  return apiFetch<Asset>(`/assets/${id}/`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteAsset(id: number): Promise<void> {
  return apiFetch<void>(`/assets/${id}/`, { method: "DELETE" });
}

export function getCostRecoveryReport(): Promise<CostRecoveryReportItem[]> {
  return apiFetch<CostRecoveryReportItem[]>("/assets/cost-recovery-report/");
}

export function listAssetIncidents(assetId?: number): Promise<AssetIncident[]> {
  return apiFetch<AssetIncident[]>(`/asset-incidents/${assetId ? `?asset=${assetId}` : ""}`);
}

export function createAssetIncident(payload: AssetIncidentPayload): Promise<AssetIncident> {
  return apiFetch<AssetIncident>("/asset-incidents/", { method: "POST", body: JSON.stringify(payload) });
}

// --- loans -------------------------------------------------------------------------

export function listLoans(): Promise<Loan[]> {
  return apiFetch<Loan[]>("/loans/");
}

export function getLoan(id: number): Promise<Loan> {
  return apiFetch<Loan>(`/loans/${id}/`);
}

export function createLoan(payload: LoanPayload): Promise<Loan> {
  return apiFetch<Loan>("/loans/", { method: "POST", body: JSON.stringify(payload) });
}

export function updateLoan(id: number, payload: LoanPayload): Promise<Loan> {
  return apiFetch<Loan>(`/loans/${id}/`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteLoan(id: number): Promise<void> {
  return apiFetch<void>(`/loans/${id}/`, { method: "DELETE" });
}

export function listLoanInstallmentPayments(loanId?: number): Promise<LoanInstallmentPayment[]> {
  return apiFetch<LoanInstallmentPayment[]>(`/loan-installment-payments/${loanId ? `?loan=${loanId}` : ""}`);
}

export function addInstallmentPayment(payload: AddInstallmentPaymentPayload): Promise<LoanInstallmentPayment> {
  return apiFetch<LoanInstallmentPayment>("/loan-installment-payments/", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

// --- expenses ------------------------------------------------------------------

export function listExpenses(filters: ExpenseListFilters = {}): Promise<Expense[]> {
  const query = new URLSearchParams();
  if (filters.category) query.set("category", filters.category);
  if (filters.dateFrom) query.set("date_from", filters.dateFrom);
  if (filters.dateTo) query.set("date_to", filters.dateTo);
  const queryString = query.toString();
  return apiFetch<Expense[]>(`/expenses/${queryString ? `?${queryString}` : ""}`);
}

export function getExpense(id: number): Promise<Expense> {
  return apiFetch<Expense>(`/expenses/${id}/`);
}

export function createExpense(payload: ExpensePayload): Promise<Expense> {
  return apiFetch<Expense>("/expenses/", { method: "POST", body: JSON.stringify(payload) });
}

export function updateExpense(id: number, payload: ExpensePayload): Promise<Expense> {
  return apiFetch<Expense>(`/expenses/${id}/`, { method: "PATCH", body: JSON.stringify(payload) });
}

export function deleteExpense(id: number): Promise<void> {
  return apiFetch<void>(`/expenses/${id}/`, { method: "DELETE" });
}

// --- payments (cross-invoice) ---------------------------------------------------

export function listPayments(filters: PaymentListFilters = {}): Promise<InvoicePayment[]> {
  const query = new URLSearchParams();
  if (filters.customer) query.set("customer", String(filters.customer));
  if (filters.dateFrom) query.set("date_from", filters.dateFrom);
  if (filters.dateTo) query.set("date_to", filters.dateTo);
  const queryString = query.toString();
  return apiFetch<InvoicePayment[]>(`/payments/${queryString ? `?${queryString}` : ""}`);
}

// --- shop profile ------------------------------------------------------------------

export function getShopProfile(): Promise<ShopProfile> {
  return apiFetch<ShopProfile>("/shop-profile/");
}

export function updateShopProfile(payload: ShopProfilePayload): Promise<ShopProfile> {
  return apiFetch<ShopProfile>("/shop-profile/", { method: "PATCH", body: JSON.stringify(payload) });
}

// --- system users (Admin only) --------------------------------------------------

export function listUsers(): Promise<SystemUser[]> {
  return apiFetch<SystemUser[]>("/users/");
}

// --- audit log (Admin only) ------------------------------------------------------

export function getAuditLog(filters: AuditLogFilters = {}): Promise<AuditFeedResponse> {
  const query = new URLSearchParams();
  if (filters.fromDate) query.set("from_date", filters.fromDate);
  if (filters.toDate) query.set("to_date", filters.toDate);
  if (filters.user) query.set("user", filters.user);
  if (filters.model) query.set("model", filters.model);
  if (filters.action) query.set("action", filters.action);
  if (filters.page) query.set("page", String(filters.page));
  if (filters.pageSize) query.set("page_size", String(filters.pageSize));
  const queryString = query.toString();
  return apiFetch<AuditFeedResponse>(`/audit/log/${queryString ? `?${queryString}` : ""}`);
}
