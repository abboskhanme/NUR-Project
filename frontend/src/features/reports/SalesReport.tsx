import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Cell,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import { orderStatusLabel, orderStatusColor } from '@/lib/status';
import RevenueArea from '@/features/dashboard/RevenueArea';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type {
  DateRange, KpiData, ByModelRow, ByRegionRow, BySellerRow, StatusRow, TrendData,
} from './types';

const COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C', '#8E44AD', '#16A085'];

export default function SalesReport({ range }: { range: DateRange }) {
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

  const modelCols: Column<ByModelRow>[] = [
    { key: 'model', label: 'Model', render: (r) => r.model },
    { key: 'count', label: 'Soni', align: 'right' },
    { key: 'total_uzs', label: 'Summa', align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const regionCols: Column<ByRegionRow>[] = [
    { key: 'region', label: 'Viloyat' },
    { key: 'count', label: 'Buyurtma', align: 'right' },
    { key: 'total_uzs', label: 'Summa', align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const sellerCols: Column<BySellerRow>[] = [
    { key: 'seller', label: 'Sotuvchi' },
    { key: 'count', label: 'Buyurtma', align: 'right' },
    { key: 'total_uzs', label: 'Summa', align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];
  const statusCols: Column<StatusRow>[] = [
    { key: 'status', label: 'Holat', value: (r) => orderStatusLabel(r.status),
      render: (r) => (
        <span className="inline-flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: orderStatusColor(r.status) }} />
          {orderStatusLabel(r.status)}
        </span>
      ) },
    { key: 'count', label: 'Soni', align: 'right' },
    { key: 'total_uzs', label: 'Summa', align: 'right', render: (r) => formatUZS(r.total_uzs) },
  ];

  return (
    <div className="space-y-4">
      {/* KPI tiles */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <StatTile label="Buyurtmalar" value={kpi.data ? String(kpi.data.orders_total) : '—'} />
        <StatTile label="Yetkazilgan" value={kpi.data ? String(kpi.data.orders_delivered) : '—'} tone="success" />
        <StatTile label="Rad etilgan" value={kpi.data ? String(kpi.data.orders_rejected) : '—'} tone="danger" />
        <StatTile label="Umumiy summa" value={kpi.data ? formatUZS(kpi.data.total_uzs) : '—'} tone="primary" />
        <StatTile label="O'rtacha chek" value={kpi.data ? formatUZS(kpi.data.avg_check_uzs) : '—'} />
      </div>

      <Card
        title="Tushum dinamikasi"
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
                {g === 'day' ? 'Kunlik' : 'Oylik'}
              </button>
            ))}
          </div>
        }
      >
        <RevenueArea points={trend.data?.points} height={280} />
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Model bo'yicha sotuv">
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={byModel.data ?? []}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="model" fontSize={11} />
              <YAxis fontSize={11} />
              <Tooltip formatter={(v: number, n) => n === 'count' ? `${v} ta` : formatUZS(v)} />
              <Bar dataKey="count" name="Soni" radius={[4, 4, 0, 0]}>
                {(byModel.data ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="mt-3">
            <ReportTable rows={byModel.data} columns={modelCols} filename="sotuv-model" />
          </div>
        </Card>

        <Card title="Viloyat bo'yicha sotuv">
          <ResponsiveContainer width="100%" height={Math.max(240, (byRegion.data?.length ?? 1) * 32)}>
            <BarChart data={byRegion.data ?? []} layout="vertical" margin={{ left: 8 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="region" fontSize={11} width={120} interval={0} />
              <Tooltip formatter={(v: number, n) => n === 'count' ? `${v} ta` : formatUZS(v)} />
              <Bar dataKey="count" name="Soni" radius={[0, 4, 4, 0]}>
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
        <Card title="Sotuvchi bo'yicha">
          <ReportTable rows={bySeller.data} columns={sellerCols} filename="sotuv-sotuvchi"
            emptyText="Sotuvchi biriktirilmagan" />
        </Card>
        <Card title="Holat bo'yicha taqsimot">
          <ReportTable rows={byStatus.data} columns={statusCols} filename="sotuv-holat" />
        </Card>
      </div>
    </div>
  );
}
