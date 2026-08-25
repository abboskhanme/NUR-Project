import { useQuery } from '@tanstack/react-query';
import {
  ResponsiveContainer, Tooltip, Legend, CartesianGrid,
  BarChart, Bar, XAxis, YAxis, Cell,
  PieChart, Pie,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type { DateRange, ProductionSummaryReport } from './types';

const KOTYOL_COLOR = '#1E3A5F';
const TANA_COLOR = '#F39C12';
const SIZE_COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C', '#8E44AD', '#16A085', '#7F8C8D'];
const DIR_COLORS: Record<string, string> = {
  "O'ngga": '#2980B9',
  Chapga: '#27AE60',
  "Ko'rsatilmagan": '#95A5A6',
};

/** Kunlik kesimda "25.08", oylik kesimda "08.26" */
const axisLabel = (iso: string, gran: 'day' | 'month') => {
  const [y, m, d] = String(iso).split('-');
  return gran === 'month' ? `${m}.${y.slice(2)}` : `${d}.${m}`;
};

type ModelRow = { model: string; kvm: number | null; count: number };
type SizeRow = { size: string; count: number };
type DirRow = { direction: string; count: number };

/** Yo'nalish taqsimoti — kotyol va tana uchun bir xil ko'rinish. */
function DirectionPie({ rows }: { rows: DirRow[] | undefined }) {
  const data = (rows ?? []).filter((r) => r.count > 0);
  if (!rows) return <div className="text-sm text-ink-soft py-12 text-center">Yuklanmoqda…</div>;
  if (data.length === 0) return <div className="text-sm text-ink-soft py-12 text-center">Ma'lumot yo'q</div>;
  return (
    <ResponsiveContainer width="100%" height={220}>
      <PieChart>
        <Pie data={data} dataKey="count" nameKey="direction"
          innerRadius={50} outerRadius={78} paddingAngle={2}>
          {data.map((r) => <Cell key={r.direction} fill={DIR_COLORS[r.direction] ?? '#7F8C8D'} />)}
        </Pie>
        <Tooltip formatter={(v: number) => `${v} ta`} />
        <Legend verticalAlign="bottom" iconType="circle" />
      </PieChart>
    </ResponsiveContainer>
  );
}

export default function ProductionReport({ range }: { range: DateRange }) {
  const sum = useQuery<ProductionSummaryReport>({
    queryKey: ['rep-production', range],
    queryFn: () => api.get('/reports/production/summary', {
      params: { date_from: range.from, date_to: range.to },
    }).then((r) => r.data),
  });

  const d = sum.data;
  const gran = d?.granularity ?? 'day';

  const modelCols: Column<ModelRow>[] = [
    { key: 'model', label: 'Model' },
    { key: 'kvm', label: "O'lcham", align: 'right', render: (r) => (r.kvm ? `${r.kvm} kvm` : '—') },
    { key: 'count', label: 'Soni', align: 'right' },
  ];
  const sizeCols: Column<SizeRow>[] = [
    { key: 'size', label: "O'lcham" },
    { key: 'count', label: 'Soni', align: 'right' },
  ];

  const hasTrend = !!d && d.trend.some((p) => p.kotyol > 0 || p.tana > 0);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <StatTile label="Jami kotyol" value={d ? `${d.kotyol_total} ta` : '—'} tone="primary"
          sub={d ? `kuniga o'rtacha ${d.kotyol_avg_per_day}` : undefined} />
        <StatTile label="Olib kelingan kotyol" value={d ? `${d.tana_total} ta` : '—'} tone="warning"
          sub={d ? `kuniga o'rtacha ${d.tana_avg_per_day}` : undefined} />
        <StatTile label="Omborga o'tkazilgan" value={d ? `${d.kotyol_transferred} ta` : '—'} tone="success" />
        <StatTile label="O'tkazilmagan" value={d ? `${d.kotyol_pending} ta` : '—'} tone="danger" />
        <StatTile label="Ish kunlari" value={d ? `${d.work_days} kun` : '—'}
          sub="yozuv bo'lgan kunlar" />
      </div>

      <Card title={`Ishlab chiqarish dinamikasi (${gran === 'month' ? 'oylik' : 'kunlik'})`}>
        {hasTrend ? (
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={d!.trend} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="date" tickFormatter={(v) => axisLabel(v, gran)} fontSize={11} tickMargin={6} />
              <YAxis fontSize={11} allowDecimals={false} width={36} />
              <Tooltip
                labelFormatter={(l) => axisLabel(String(l), gran)}
                formatter={(v: number, n) => [`${v} ta`, n === 'kotyol' ? 'Kotyol' : 'Olib kelingan']}
              />
              <Legend verticalAlign="bottom" iconType="circle"
                formatter={(v) => (v === 'kotyol' ? 'Kotyol' : 'Olib kelingan kotyol')} />
              <Bar dataKey="kotyol" fill={KOTYOL_COLOR} radius={[4, 4, 0, 0]} />
              <Bar dataKey="tana" fill={TANA_COLOR} radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        ) : (
          <div className="text-sm text-ink-soft py-12 text-center">
            {d ? "Bu davrda ishlab chiqarish yozuvi yo'q" : 'Yuklanmoqda…'}
          </div>
        )}
      </Card>

      <Card title="Kotyol — model va o'lcham bo'yicha">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <ResponsiveContainer width="100%" height={Math.max(200, (d?.kotyol_by_model.length ?? 1) * 36)}>
            <BarChart data={d?.kotyol_by_model ?? []} layout="vertical" margin={{ left: 24 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="model" fontSize={11} width={120} interval={0} />
              <Tooltip formatter={(v: number) => `${v} ta`} />
              <Bar dataKey="count" radius={[0, 4, 4, 0]}>
                {(d?.kotyol_by_model ?? []).map((_, i) => (
                  <Cell key={i} fill={SIZE_COLORS[i % SIZE_COLORS.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <ReportTable rows={d?.kotyol_by_model} columns={modelCols} filename="ishlab-chiqarish-kotyol-model"
            emptyText="Bu davrda kotyol chiqmagan" />
        </div>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Kotyol — o'lcham (kvm) kesimi">
          <ReportTable rows={d?.kotyol_by_size} columns={sizeCols} filename="ishlab-chiqarish-kotyol-olcham"
            emptyText="Bu davrda kotyol chiqmagan" />
        </Card>
        <Card title="Olib kelingan kotyol — o'lcham kesimi">
          <ReportTable rows={d?.tana_by_size} columns={sizeCols} filename="ishlab-chiqarish-olib-kelingan-olcham"
            emptyText="Bu davrda olib kelinmagan" />
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Kotyol — yo'nalish bo'yicha">
          <DirectionPie rows={d?.kotyol_by_direction} />
        </Card>
        <Card title="Olib kelingan kotyol — yo'nalish bo'yicha">
          <DirectionPie rows={d?.tana_by_direction} />
        </Card>
      </div>
    </div>
  );
}
