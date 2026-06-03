// Bosh sahifa (dashboard) API javob tiplari.

export interface DashboardKpi {
  orders_total: number;
  orders_delivered: number;
  revenue_uzs: number;
  revenue_prev_uzs: number;
  revenue_growth_pct: number | null;
  income_uzs: number;
  expense_uzs: number;
  net_uzs: number;
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
