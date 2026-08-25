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
export interface BySizeRow { size: string; kvm: number | null; count: number; total_uzs: number }
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

export interface ServiceRegionRow {
  region: string;
  count: number;
  completed: number;
  client_cost_uzs: number;
  customers: number;
}

export interface ServiceTrendPoint { date: string; total: number; completed: number }

export interface ServiceSummary {
  total: number;
  new: number;
  scheduled: number;
  completed: number;
  cancelled: number;
  in_warranty: number;
  out_warranty: number;
  /** «0 dan» (diller mijozi) arizalar soni */
  external: number;
  client_revenue_uzs: number;
  /** Ochilishdan yopilishgacha o'rtacha kun */
  avg_close_days: number | null;
  by_category: Array<{ category: string; count: number }>;
  by_region: ServiceRegionRow[];
  parts: Array<{ name: string; count: number }>;
  parts_total: number;
  trips: {
    collected_uzs: number;
    spent_uzs: number;
    net_uzs: number;
    trip_count: number;
  };
  granularity: 'day' | 'month';
  trend: ServiceTrendPoint[];
}

/** Ishlab chiqarish hisoboti — faqat kotyol va olib kelingan kotyol (tana) */
export interface ProductionTrendPoint { date: string; kotyol: number; tana: number }

export interface ProductionSummaryReport {
  date_from: string;
  date_to: string;
  granularity: 'day' | 'month';
  kotyol_total: number;
  tana_total: number;
  kotyol_transferred: number;
  kotyol_pending: number;
  work_days: number;
  kotyol_avg_per_day: number;
  tana_avg_per_day: number;
  trend: ProductionTrendPoint[];
  kotyol_by_model: Array<{ model: string; kvm: number | null; count: number }>;
  kotyol_by_size: Array<{ size: string; kvm: number | null; count: number }>;
  tana_by_size: Array<{ size: string; count: number }>;
  kotyol_by_direction: Array<{ direction: string; count: number }>;
  tana_by_direction: Array<{ direction: string; count: number }>;
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

  structure: {
    materials_uzs: number;
    expenses_uzs: number;
    overhead_uzs: number;
    profit_uzs: number;
  };
  products: ProfitProductRow[];
  trend: ProfitTrendPoint[];
}
