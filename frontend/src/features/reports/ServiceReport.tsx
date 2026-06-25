import { useQuery } from '@tanstack/react-query';
import {
  PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend,
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type { DateRange, ServiceSummary } from './types';

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

type CatRow = { category: string; count: number };

export default function ServiceReport({ range }: { range: DateRange }) {
  const sum = useQuery<ServiceSummary>({
    queryKey: ['rep-service', range],
    queryFn: () => api.get('/reports/service/summary', {
      params: { date_from: range.from, date_to: range.to },
    }).then((r) => r.data),
  });

  const d = sum.data;
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

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <StatTile label="Jami arizalar" value={d ? String(d.total) : '—'} />
        <StatTile label="Yangi" value={d ? String(d.new) : '—'} tone="primary" />
        <StatTile label="Bajarilgan" value={d ? String(d.completed) : '—'} tone="success" />
        <StatTile label="Kafolatda" value={d ? `${d.in_warranty} / ${d.total}` : '—'} />
        <StatTile label="Mijoz to'lovi" value={d ? formatUZS(d.client_revenue_uzs) : '—'} tone="primary" />
      </div>

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
    </div>
  );
}
