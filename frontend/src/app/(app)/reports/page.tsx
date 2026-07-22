"use client";

import { useState } from "react";

import { CashbookTab } from "@/components/reports/cashbook-tab";
import { CustomerLedgerTab } from "@/components/reports/customer-ledger-tab";
import { DueTab } from "@/components/reports/due-tab";
import { ExpenseTab } from "@/components/reports/expense-tab";
import { IncomeTab } from "@/components/reports/income-tab";
import { PaymentDelayTab } from "@/components/reports/payment-delay-tab";
import { ProfitLossTab } from "@/components/reports/profit-loss-tab";
import { PurchaseTab } from "@/components/reports/purchase-tab";
import { SalesTab } from "@/components/reports/sales-tab";
import { ServiceReportTab } from "@/components/reports/service-report-tab";
import { StockTab } from "@/components/reports/stock-tab";
import { SupplierLedgerTab } from "@/components/reports/supplier-ledger-tab";
import { TopCustomersTab } from "@/components/reports/top-customers-tab";
import { DatePickerButton } from "@/components/date-picker-button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const TABS = [
  { value: "income", label: "Income" },
  { value: "expense", label: "Expense" },
  { value: "sales", label: "Sales" },
  { value: "purchase", label: "Purchase" },
  { value: "profit-loss", label: "Profit/Loss" },
  { value: "stock", label: "Stock" },
  { value: "due", label: "Due" },
  { value: "cashbook", label: "Cashbook" },
  { value: "customer-ledger", label: "Customer Ledger" },
  { value: "supplier-ledger", label: "Supplier Ledger" },
  { value: "top-customers", label: "Top Customers" },
  { value: "payment-delays", label: "Payment Delays" },
  { value: "service-report", label: "Service Report" },
];

export default function ReportsPage() {
  const [fromDate, setFromDate] = useState<string | undefined>(undefined);
  const [toDate, setToDate] = useState<string | undefined>(undefined);

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold">Reports</h1>
        <p className="text-sm text-muted-foreground">Financial and operational reports across the shop.</p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">From</label>
          <DatePickerButton value={fromDate} onChange={setFromDate} placeholder="All time" />
        </div>
        <div className="space-y-1.5">
          <label className="text-xs font-medium text-muted-foreground">To</label>
          <DatePickerButton value={toDate} onChange={setToDate} placeholder="All time" />
        </div>
        {(fromDate || toDate) && (
          <button
            type="button"
            className="pb-1.5 text-xs text-muted-foreground underline-offset-4 hover:underline"
            onClick={() => {
              setFromDate(undefined);
              setToDate(undefined);
            }}
          >
            Clear range
          </button>
        )}
      </div>

      <Tabs defaultValue="income">
        <TabsList className="w-full justify-start overflow-x-auto">
          {TABS.map((tab) => (
            <TabsTrigger key={tab.value} value={tab.value} className="shrink-0">
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        <TabsContent value="income" className="mt-4">
          <IncomeTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="expense" className="mt-4">
          <ExpenseTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="sales" className="mt-4">
          <SalesTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="purchase" className="mt-4">
          <PurchaseTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="profit-loss" className="mt-4">
          <ProfitLossTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="stock" className="mt-4">
          <StockTab />
        </TabsContent>
        <TabsContent value="due" className="mt-4">
          <DueTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="cashbook" className="mt-4">
          <CashbookTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="customer-ledger" className="mt-4">
          <CustomerLedgerTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="supplier-ledger" className="mt-4">
          <SupplierLedgerTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="top-customers" className="mt-4">
          <TopCustomersTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="payment-delays" className="mt-4">
          <PaymentDelayTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
        <TabsContent value="service-report" className="mt-4">
          <ServiceReportTab fromDate={fromDate} toDate={toDate} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
