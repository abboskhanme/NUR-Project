// Hisobotlar API javob tiplari.

export interface DateRange {
  from: string; // ISO yyyy-mm-dd
  to: string;
}

export interface KpiData {
  date_from: string;
  date_to: string;
  orders_total: number;
  orders_new: number;
  orders_ready: number;
  orders_delivered: number;
  orders_rejected: number;
  total_uzs: number;
  avg_check_uzs: number;
}

export interface ByModelRow { model: string; count: number; total_uzs: number }
export interface ByRegionRow { region: string; count: number; total_uzs: number }
export interface BySellerRow { seller: string; count: number; total_uzs: number }
export interface ByCustomerRow { customer: string; phone: string | null; count: number; total_uzs: number }
export interface StatusRow { status: string; count: number; total_uzs: number }

export interface ReceivableRow {
  id: string;
  code: string;
  order_date: string;
  status: string;
  customer: string;
  phone: string | null;
  is_dealer: boolean;
  total_uzs: number;
  paid_uzs: number;
  balance_uzs: number;
  days: number | null;
}
export interface ReceivablesData {
  total_balance_uzs: number;
  count: number;
  items: ReceivableRow[];
}

export interface TrendPoint { date: string; total_uzs: number; orders: number }
export interface TrendData {
  granularity: 'day' | 'month';
  points: TrendPoint[];
}

export interface PnlData {
  income: number;
  expense: number;
  net: number;
  margin_pct: number | null;
  expense_by_category: Array<{ category: string; amount: number }>;
}

export interface ServiceSummary {
  total: number;
  new: number;
  scheduled: number;
  completed: number;
  cancelled: number;
  in_warranty: number;
  out_warranty: number;
  client_revenue_uzs: number;
  by_category: Array<{ category: string; count: number }>;
}

export interface SupplySummary {
  receipts_total_uzs: number;
  receipts_paid_uzs: number;
  debt_total_uzs: number;
  low_stock_count: number;
  low_stock: Array<{ name: string; unit: string; stock_qty: number; min_qty: number }>;
  top_debts: Array<{ vendor: string; debt_uzs: number }>;
}

/** Tannarx (kalkulyatsiya) asosidagi foyda hisoboti — GET /costing/profit-report */
export interface ProfitProductRow {
  product_id: string;
  display_name: string;
  has_recipe: boolean;
  units: number;
  revenue_uzs: number;
  avg_price_uzs: number;
  unit_cost_uzs: number | null;
  cogs_uzs: number | null;
  profit_uzs: number | null;
  margin_percent: number | null;
}

export interface ProfitTrendPoint {
  date: string;
  revenue_uzs: number;
  cogs_uzs: number;
  profit_uzs: number;
}

export interface ProfitReport {
  date_from: string;
  date_to: string;
  granularity: 'day' | 'month';
  usd_rate: number;

  units_sold: number;
  revenue_uzs: number;
  /** Sotuv bo'limidagi «Savdo» KPI bilan bir xil baza (rad etilgan + qo'shimcha bilan) */
  sales_total_uzs: number;
  excluded_rejected_uzs: number;
  excluded_additional_uzs: number;
  covered_revenue_uzs: number;
  uncovered_revenue_uzs: number;
  uncovered_units: number;
  uncovered_count: number;
  coverage_percent: number;

  cogs_uzs: number;
  gross_profit_uzs: number;
  gross_margin_percent: number | null;
  opex_uzs: number;
  opex_count: number;
  opex_by_category: Array<{ category: string; amount_uzs: number; count: number }>;
  net_profit_uzs: number;
  net_margin_percent: number | null;

  structure: {
    materials_uzs: number;
    expenses_uzs: number;
    overhead_uzs: number;
    profit_uzs: number;
  };
  products: ProfitProductRow[];
  trend: ProfitTrendPoint[];
}
