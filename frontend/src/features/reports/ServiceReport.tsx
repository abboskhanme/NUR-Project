import { useQuery } from '@tanstack/react-query';
import {
  PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend,
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  AreaChart, Area,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type { DateRange, ServiceRegionRow, ServiceSummary } from './types';

const STATUS_COLORS: Record<string, string> = {
  new: '#2980B9', scheduled: '#F39C12', completed: '#27AE60', cancelled: '#E74C3C',
};
const CAT_COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C', '#8E44AD', '#16A085', '#7F8C8D'];

const SERVICE_STATUS_LABELS: Record<string, string> = {
  new: 'Yangi',
  scheduled: 'Rejalashtirilgan',
  completed: 'Bajarilgan',
  cancelled: 'Bekor qilingan',
};

/** Kunlik kesimda "25.08", oylik kesimda "08.26" */
const axisLabel = (iso: string, gran: 'day' | 'month') => {
  const [y, m, d] = String(iso).split('-');
  return gran === 'month' ? `${m}.${y.slice(2)}` : `${d}.${m}`;
};

type CatRow = { category: string; count: number };
type PartRow = { name: string; count: number };

export default function ServiceReport({ range }: { range: DateRange }) {
  const sum = useQuery<ServiceSummary>({
    queryKey: ['rep-service', range],
    queryFn: () => api.get('/reports/service/summary', {
      params: { date_from: range.from, date_to: range.to },
    }).then((r) => r.data),
  });

  const d = sum.data;
  const gran = d?.granularity ?? 'day';
  const statusData = d ? [
    { key: 'new', value: d.new },
    { key: 'scheduled', value: d.scheduled },
    { key: 'completed', value: d.completed },
    { key: 'cancelled', value: d.cancelled },
  ].filter((s) => s.value > 0) : [];

  const catCols: Column<CatRow>[] = [
    { key: 'category', label: 'Kategoriya' },
    { key: 'count', label: 'Soni', align: 'right' },
  ];
  const regionCols: Column<ServiceRegionRow>[] = [
    { key: 'region', label: 'Viloyat' },
    { key: 'count', label: 'Arizalar', align: 'right' },
    { key: 'completed', label: 'Bajarilgan', align: 'right' },
    { key: 'customers', label: 'Mijozlar', align: 'right' },
    {
      key: 'client_cost_uzs', label: "Mijoz to'lovi", align: 'right',
      render: (r) => formatUZS(r.client_cost_uzs),
    },
  ];
  const partCols: Column<PartRow>[] = [
    { key: 'name', label: 'Ehtiyot qism' },
    { key: 'count', label: 'Ishlatilgan', align: 'right' },
  ];

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
        <StatTile label="Jami arizalar" value={d ? String(d.total) : '—'} />
        <StatTile label="Yangi" value={d ? String(d.new) : '—'} tone="primary" />
        <StatTile label="Bajarilgan" value={d ? String(d.completed) : '—'} tone="success" />
        <StatTile label="Kafolatda" value={d ? `${d.in_warranty} / ${d.total}` : '—'} />
        <StatTile label="Mijoz to'lovi" value={d ? formatUZS(d.client_revenue_uzs) : '—'} tone="primary" />
        <StatTile
          label="O'rtacha yopish"
          value={d ? (d.avg_close_days !== null ? `${d.avg_close_days} kun` : '—') : '—'}
          sub={d ? `${d.external} ta «0 dan» ariza` : undefined}
        />
      </div>

      <Card title={`Arizalar dinamikasi (${gran === 'month' ? 'oylik' : 'kunlik'})`}>
        {d && d.trend.length > 0 ? (
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={d.trend} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="srvFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#1E3A5F" stopOpacity={0.35} />
                  <stop offset="100%" stopColor="#1E3A5F" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="date" tickFormatter={(v) => axisLabel(v, gran)} fontSize={11} tickMargin={6} />
              <YAxis fontSize={11} allowDecimals={false} width={36} />
              <Tooltip
                labelFormatter={(l) => axisLabel(String(l), gran)}
                formatter={(v: number, n) => [`${v} ta`, n === 'total' ? 'Jami' : 'Bajarilgan']}
              />
              <Legend verticalAlign="bottom" iconType="circle"
                formatter={(v) => (v === 'total' ? 'Jami' : 'Bajarilgan')} />
              <Area type="monotone" dataKey="total" stroke="#1E3A5F" strokeWidth={2} fill="url(#srvFill)" />
              <Area type="monotone" dataKey="completed" stroke="#27AE60" strokeWidth={2} fillOpacity={0} />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <div className="text-sm text-ink-soft py-12 text-center">
            {d ? 'Bu davrda ariza yo\'q' : 'Yuklanmoqda…'}
          </div>
        )}
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Holat bo'yicha">
          {statusData.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie data={statusData} dataKey="value"
                  nameKey="key" innerRadius={55} outerRadius={85} paddingAngle={2}>
                  {statusData.map((s) => <Cell key={s.key} fill={STATUS_COLORS[s.key]} />)}
                </Pie>
                <Tooltip formatter={(v: number, _n, p: any) =>
                  [`${v} ta`, SERVICE_STATUS_LABELS[p.payload.key] ?? p.payload.key]} />
                <Legend verticalAlign="bottom" iconType="circle"
                  formatter={(val) => SERVICE_STATUS_LABELS[val as string] ?? val} />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="text-sm text-ink-soft py-12 text-center">Ariza yo'q</div>
          )}
        </Card>

        <Card title="Kafolat ichida / tashqarisida">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={[
              { name: 'Kafolatda', value: d?.in_warranty ?? 0 },
              { name: 'Kafolatdan tashqari', value: d?.out_warranty ?? 0 },
            ]}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="name" fontSize={12} />
              <YAxis fontSize={11} allowDecimals={false} />
              <Tooltip formatter={(v: number) => `${v} ta`} />
              <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                <Cell fill="#27AE60" />
                <Cell fill="#F39C12" />
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>

      <Card title="Kategoriya bo'yicha arizalar">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <ResponsiveContainer width="100%" height={Math.max(200, (d?.by_category.length ?? 1) * 36)}>
            <BarChart data={d?.by_category ?? []} layout="vertical" margin={{ left: 24 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="category" fontSize={11} width={120} interval={0} />
              <Tooltip formatter={(v: number) => `${v} ta`} />
              <Bar dataKey="count" radius={[0, 4, 4, 0]}>
                {(d?.by_category ?? []).map((_, i) => <Cell key={i} fill={CAT_COLORS[i % CAT_COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <ReportTable rows={d?.by_category} columns={catCols} filename="servis-kategoriya" />
        </div>
      </Card>

      <Card title="Viloyat bo'yicha arizalar">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <ResponsiveContainer width="100%" height={Math.max(200, (d?.by_region.length ?? 1) * 36)}>
            <BarChart data={d?.by_region ?? []} layout="vertical" margin={{ left: 24 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="region" fontSize={11} width={120} interval={0} />
              <Tooltip formatter={(v: number) => `${v} ta`} />
              <Bar dataKey="count" radius={[0, 4, 4, 0]}>
                {(d?.by_region ?? []).map((_, i) => <Cell key={i} fill={CAT_COLORS[i % CAT_COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <ReportTable rows={d?.by_region} columns={regionCols} filename="servis-viloyat"
            emptyText="Bu davrda ariza yo'q" />
        </div>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title={`Ishlatilgan ehtiyot qismlar${d ? ` — ${d.parts_total} ta` : ''}`}>
          <ReportTable rows={d?.parts} columns={partCols} filename="servis-ehtiyot-qismlar"
            emptyText="Bu davrda qism ishlatilmagan" />
        </Card>

        <Card title="Servis safarlari (yakunlangan)">
          <div className="grid grid-cols-2 gap-3">
            <StatTile label="Safarlar" value={d ? `${d.trips.trip_count} ta` : '—'} />
            <StatTile label="Olingan pul" value={d ? formatUZS(d.trips.collected_uzs) : '—'} tone="success" />
            <StatTile label="Sarflangan" value={d ? formatUZS(d.trips.spent_uzs) : '—'} tone="danger" />
            <StatTile label="Farq" value={d ? formatUZS(d.trips.net_uzs) : '—'}
              tone={d && d.trips.net_uzs < 0 ? 'danger' : 'primary'} />
          </div>
          <p className="text-xs text-ink-soft mt-3">
            Safar puli safar YAKUNLANGAN sana bo'yicha hisoblanadi; arizalar esa ochilgan sana bo'yicha.
          </p>
        </Card>
      </div>
    </div>
  );
}
