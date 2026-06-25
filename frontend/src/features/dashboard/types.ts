// Bosh sahifa (dashboard) API javob tiplari.

export interface DashboardKpi {
  orders_total: number;
  orders_prev: number;
  orders_growth_pct: number | null;
  orders_delivered: number;
  delivered_prev: number;
  delivered_growth_pct: number | null;
  revenue_uzs: number;
  revenue_prev_uzs: number;
  revenue_growth_pct: number | null;
  income_uzs: number;
  expense_uzs: number;
  expense_prev_uzs: number;
  expense_growth_pct: number | null;
  net_uzs: number;
}

export interface MonthlyGoal {
  period_month: string;
  target_orders: number | null;
  target_revenue_uzs: number | null;
  actual_orders: number;
  actual_revenue_uzs: number;
  orders_pct: number | null;
  revenue_pct: number | null;
  updated_at: string | null;
}

export interface DashboardAlerts {
  warranty_expiring: number;
  service_new: number;
  service_scheduled: number;
  low_stock: number;
  vendor_debt_uzs: number;
  queue_count: number;
}

export interface RecentOrder {
  id: string;
  code: string;
  order_date: string;
  status: string;
  customer: string;
}

export interface SparkPoint {
  date: string;
  total_uzs: number;
  orders: number;
}

export interface DashboardData {
  as_of: string;
  kpi: DashboardKpi;
  alerts: DashboardAlerts;
  status_breakdown: Array<{ status: string; count: number }>;
  recent_orders: RecentOrder[];
  revenue_sparkline: SparkPoint[];
}
