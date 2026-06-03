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
export interface StatusRow { status: string; count: number; total_uzs: number }

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
