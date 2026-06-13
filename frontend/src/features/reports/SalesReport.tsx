import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Cell,
} from 'recharts';
import { FileSpreadsheet } from 'lucide-react';

import { api } from '@/api/client';
import { downloadFile } from '@/lib/download';
import Card from '@/components/ui/Card';
import { formatUZS, formatPhone } from '@/lib/format';
import { orderStatusLabel, orderStatusColor } from '@/lib/status';
import RevenueArea from '@/features/dashboard/RevenueArea';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type {
  DateRange, KpiData, ByModelRow, ByRegionRow, BySellerRow, ByCustomerRow,
  StatusRow, TrendData, ReceivablesData, ReceivableRow,
} from './types';

const COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C', '#8E44AD', '#16A085'];

export default function SalesReport({ range }: { range: DateRange }) {
  const { t } = useTranslation();
  const [gran, setGran] = useState<'day' | 'month'>('day');
  const params = { date_from: range.from, date_to: range.to };

  const kpi = useQuery<KpiData>({
    queryKey: ['rep-kpi', range],
    queryFn: () => api.get('/reports/sales/kpi', { params }).then((r) => r.data),
  });
  const trend = useQuery<TrendData>({
    queryKey: ['rep-trend', range, gran],
    queryFn: () => api.get('/reports/sales/trend', { params: { ...params, granularity: gran } }).then((r) => r.data),
  });
  const byModel = useQuery<ByModelRow[]>({
    queryKey: ['rep-by-model', range],
    queryFn: () => api.get('/reports/sales/by-model', { params }).then((r) => r.data),
  });
  const byRegion = useQuery<ByRegionRow[]>({
    queryKey: ['rep-by-region', range],
    queryFn: () => api.get('/reports/sales/by-region', { params }).then((r) => r.data),
  });
  const bySeller = useQuery<BySellerRow[]>({
    queryKey: ['rep-by-seller', range],
    queryFn: () => api.get('/reports/sales/by-seller', { params }).then((r) => r.data),
  });
  const byStatus = useQuery<StatusRow[]>({
    queryKey: ['rep-by-status', range],
    queryFn: () => api.get('/reports/sales/status-breakdown', { params }).then((r) => r.data),
  });
  const byCustomer = useQuery<ByCustomerRow[]>({
    queryKey: ['rep-by-customer', range],
    queryFn: () => api.get('/reports/sales/by-customer', { params }).then((r) => r.data),
  });
  // Qarzdorlik sana oralig'iga bog'liq emas — barcha ochiq qarzlar
  const receivables = useQuery<ReceivablesData>({
    queryKey: ['rep-receivables'],
    queryFn: () => api.get('/reports/sales/receivables').then((r) => r.data),
  });

  const modelCols: Column<ByModelRow>[] = [
    { key: 'model', label: t('reports.sales.cols.model'), render: (r) => r.model },
    { key: 'count', label: t('reports.sales.cols.count'), align: 'right' },
    { key: 'total_uzs', label: t('reports.sales.cols.amount'), align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const regionCols: Column<ByRegionRow>[] = [
    { key: 'region', label: t('reports.sales.cols.region') },
    { key: 'count', label: t('reports.sales.cols.order'), align: 'right' },
    { key: 'total_uzs', label: t('reports.sales.cols.amount'), align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const sellerCols: Column<BySellerRow>[] = [
    { key: 'seller', label: t('reports.sales.cols.seller') },
    { key: 'count', label: t('reports.sales.cols.order'), align: 'right' },
    { key: 'total_uzs', label: t('reports.sales.cols.amount'), align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const statusCols: Column<StatusRow>[] = [
    { key: 'status', label: t('reports.sales.cols.status'), value: (r) => orderStatusLabel(r.status),
      render: (r) => (
        <span className="inline-flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: orderStatusColor(r.status) }} />
          {orderStatusLabel(r.status)}
        </span>
      ) },
    { key: 'count', label: t('reports.sales.cols.count'), align: 'right' },
    { key: 'total_uzs', label: t('reports.sales.cols.amount'), align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const customerCols: Column<ByCustomerRow>[] = [
    { key: 'customer', label: t('reports.sales.cols.customer'), render: (r) => r.customer },
    { key: 'phone', label: t('reports.sales.cols.phone'), render: (r) => (r.phone ? formatPhone(r.phone) : '—') },
    { key: 'count', label: t('reports.sales.cols.order'), align: 'right' },
    { key: 'total_uzs', label: t('reports.sales.cols.amount'), align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const receivableCols: Column<ReceivableRow>[] = [
    { key: 'customer', label: t('reports.sales.cols.customer'),
      render: (r) => (
        <span className="inline-flex items-center gap-1.5">
          {r.customer}
          {r.is_dealer && <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-amber-100 text-amber-700">{t('reports.sales.dealerShort')}</span>}
        </span>
      ) },
    { key: 'code', label: t('reports.sales.cols.orderCode'), render: (r) => r.code },
    { key: 'days', label: t('reports.sales.cols.daysOpen'), align: 'right',
      value: (r) => r.days ?? 0,
      render: (r) => (r.days != null ? t('reports.sales.daysValue', { count: r.days }) : '—') },
    { key: 'paid_uzs', label: t('reports.sales.cols.paid'), align: 'right', render: (r) => formatUZS(r.paid_uzs) },
    { key: 'balance_uzs', label: t('reports.sales.cols.balance'), align: 'right',
      render: (r) => <span className="font-semibold text-danger">{formatUZS(r.balance_uzs)}</span> },
  ];

  return (
    <div className="space-y-4">
      {/* KPI tiles */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <StatTile label={t('reports.sales.kpi.orders')} value={kpi.data ? String(kpi.data.orders_total) : '—'} />
        <StatTile label={t('reports.sales.kpi.delivered')} value={kpi.data ? String(kpi.data.orders_delivered) : '—'} tone="success" />
        <StatTile label={t('reports.sales.kpi.rejected')} value={kpi.data ? String(kpi.data.orders_rejected) : '—'} tone="danger" />
        <StatTile label={t('reports.sales.kpi.totalAmount')} value={kpi.data ? formatUZS(kpi.data.total_uzs) : '—'} tone="primary" />
        <StatTile label={t('reports.sales.kpi.avgCheck')} value={kpi.data ? formatUZS(kpi.data.avg_check_uzs) : '—'} />
      </div>

      <Card
        title={t('reports.sales.cards.revenueTrend')}
        action={
          <div className="flex gap-1">
            {(['day', 'month'] as const).map((g) => (
              <button
                key={g}
                onClick={() => setGran(g)}
                className={`px-2.5 py-1 rounded-button text-xs border ${
                  gran === g ? 'bg-primary text-white border-primary' : 'bg-white border-black/10'
                }`}
              >
                {t(`reports.granularity.${g}`)}
              </button>
            ))}
          </div>
        }
      >
        <RevenueArea points={trend.data?.points} height={280} />
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title={t('reports.sales.cards.byModel')}>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={byModel.data ?? []}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="model" fontSize={11} />
              <YAxis fontSize={11} />
              <Tooltip formatter={(v: number, _n, p: any) => p?.dataKey === 'count' ? t('reports.sales.chart.countUnit', { count: v }) : formatUZS(v)} />
              <Bar dataKey="count" name={t('reports.sales.cols.count')} radius={[4, 4, 0, 0]}>
                {(byModel.data ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="mt-3">
            <ReportTable rows={byModel.data} columns={modelCols} filename="sotuv-model" />
          </div>
        </Card>

        <Card title={t('reports.sales.cards.byRegion')}>
          <ResponsiveContainer width="100%" height={Math.max(240, (byRegion.data?.length ?? 1) * 32)}>
            <BarChart data={byRegion.data ?? []} layout="vertical" margin={{ left: 8 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="region" fontSize={11} width={120} interval={0} />
              <Tooltip formatter={(v: number, _n, p: any) => p?.dataKey === 'count' ? t('reports.sales.chart.countUnit', { count: v }) : formatUZS(v)} />
              <Bar dataKey="count" name={t('reports.sales.cols.count')} radius={[0, 4, 4, 0]}>
                {(byRegion.data ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="mt-3">
            <ReportTable rows={byRegion.data} columns={regionCols} filename="sotuv-viloyat" />
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title={t('reports.sales.cards.bySeller')}>
          <ReportTable rows={bySeller.data} columns={sellerCols} filename="sotuv-sotuvchi"
            emptyText={t('reports.sales.empty.noSeller')} />
        </Card>
        <Card title={t('reports.sales.cards.byStatus')}>
          <ReportTable rows={byStatus.data} columns={statusCols} filename="sotuv-holat" />
        </Card>
      </div>

      <Card title={t('reports.sales.cards.topCustomers')}>
        <ReportTable rows={byCustomer.data} columns={customerCols} filename="top-mijozlar"
          emptyText={t('reports.sales.empty.noCustomer')} />
      </Card>

      <Card
        title={t('reports.sales.cards.receivables')}
        action={
          <div className="flex items-center gap-3">
            <span className="text-sm font-semibold text-danger">
              {t('reports.sales.totalDebt')}: {receivables.data ? formatUZS(receivables.data.total_balance_uzs) : '—'}
            </span>
            <button
              onClick={() => downloadFile('/reports/sales/receivables.xlsx', 'qarzdorlik.xlsx').catch(() => {})}
              className="inline-flex items-center gap-1.5 text-sm text-primary hover:text-primary-700"
              title={t('reports.sales.exportExcel')}
            >
              <FileSpreadsheet size={15} /> Excel
            </button>
          </div>
        }
      >
        <ReportTable rows={receivables.data?.items} columns={receivableCols} filename="qarzdorlik"
          emptyText={t('reports.sales.empty.noDebt')} />
      </Card>
    </div>
  );
}
