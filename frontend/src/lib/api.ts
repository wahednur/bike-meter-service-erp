import {
  clearSession,
  getAccessToken,
  getRefreshToken,
  setAccessToken,
} from "./token-storage";
import type {
  AddMeterEntryPayload,
  AddProductLinePayload,
  AddServiceLinePayload,
  AdminDashboardSummary,
  Customer,
  CustomerLedger,
  CustomerPayload,
  IncomeReport,
  InvoiceDetail,
  InvoiceMeterEntry,
  InvoiceProductLine,
  InvoiceServiceLine,
  LoginResponse,
  MileageCorrectionDevice,
  Meter,
  ProductItem,
  ServiceItem,
  Supplier,
  SupplierLedger,
  SupplierPayload,
  SupplierProfitAnalysisRow,
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

async function rawRequest(path: string, options: RequestInit, accessToken: string | null): Promise<Response> {
  const headers = new Headers(options.headers);
  headers.set("Content-Type", "application/json");
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

export function getCustomerLedger(id: number): Promise<CustomerLedger> {
  return apiFetch<CustomerLedger>(`/customers/${id}/ledger/`);
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

export function getSupplierLedger(id: number): Promise<SupplierLedger> {
  return apiFetch<SupplierLedger>(`/suppliers/${id}/ledger/`);
}

export function getSupplierProfitAnalysis(): Promise<SupplierProfitAnalysisRow[]> {
  return apiFetch<SupplierProfitAnalysisRow[]>("/products/supplier-profit-analysis/");
}

// --- reference data (for the invoice creation dropdowns) ------------------------

export function listMeters(): Promise<Meter[]> {
  return apiFetch<Meter[]>("/meters/");
}

export function listMileageCorrectionDevices(): Promise<MileageCorrectionDevice[]> {
  return apiFetch<MileageCorrectionDevice[]>("/mileage-correction-devices/");
}

export function listServices(): Promise<ServiceItem[]> {
  return apiFetch<ServiceItem[]>("/services/");
}

export function listProducts(): Promise<ProductItem[]> {
  return apiFetch<ProductItem[]>("/products/");
}

// --- invoice creation -------------------------------------------------------------

export function startInvoice(customerId: number): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>("/invoices/start/", {
    method: "POST",
    body: JSON.stringify({ customer: customerId }),
  });
}

export function getInvoice(invoiceId: number): Promise<InvoiceDetail> {
  return apiFetch<InvoiceDetail>(`/invoices/${invoiceId}/`);
}

export function addMeterEntry(invoiceId: number, payload: AddMeterEntryPayload): Promise<InvoiceMeterEntry> {
  return apiFetch<InvoiceMeterEntry>(`/invoices/${invoiceId}/meter-entries/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function addServiceLine(invoiceId: number, payload: AddServiceLinePayload): Promise<InvoiceServiceLine> {
  return apiFetch<InvoiceServiceLine>(`/invoices/${invoiceId}/service-lines/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export function addProductLine(invoiceId: number, payload: AddProductLinePayload): Promise<InvoiceProductLine> {
  return apiFetch<InvoiceProductLine>(`/invoices/${invoiceId}/product-lines/`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}
