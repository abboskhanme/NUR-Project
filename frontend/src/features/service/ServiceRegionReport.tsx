import { useQuery } from '@tanstack/react-query';
import { Download, MapPin } from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Cell, ResponsiveContainer,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import StatTile from '@/features/reports/StatTile';
import { formatUZS } from '@/lib/format';
import { exportCSV } from '@/lib/export';

interface RegionRow {
  region: string;
  total: number; new: number; scheduled: number; completed: number; cancelled: number;
  in_warranty: number; out_warranty: number;
  client_cost: string; parts_count: number;
  customers: number; top_category?: string | null;
}
interface RegionReport {
  total: number; completed: number;
  in_warranty: number; out_warranty: number;
  client_cost: string; parts_count: number; customers: number;
  rows: RegionRow[];
}

const REGION_COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C',
                       '#8E44AD', '#16A085', '#D35400', '#7F8C8D', '#2C3E50'];

/**
 * Servis hisoboti — viloyatlar kesimida: qayerga ko'p chiqilyapti, qancha
 * xarajat va ehtiyot qism ketyapti, o'sha yerda qaysi muammo ustun.
 * Viloyat mijoz kartochkasidan olinadi.
 */
export default function ServiceRegionReport({ dateFrom, dateTo }: {
  dateFrom: string; dateTo: string;
}) {
  const q = useQuery<RegionReport>({
    queryKey: ['service-region-report', dateFrom, dateTo],
    queryFn: () => api.get('/service/report/regions', {
      params: { date_from: dateFrom, date_to: dateTo },
    }).then((r) => r.data),
  });

  const d = q.data;
  const rows = d?.rows ?? [];
  const chartRows = rows.slice(0, 12);
  const avgCost = d && d.total > 0 ? Number(d.client_cost) / d.total : 0;

  function handleExport() {
    exportCSV(
      rows.map((r) => ({
        region: r.region, total: r.total, customers: r.customers,
        completed: r.completed, open: r.new + r.scheduled,
        in_warranty: r.in_warranty, out_warranty: r.out_warranty,
        parts_count: r.parts_count, client_cost: r.client_cost,
        top_category: r.top_category ?? '',
      })),
      [
        { key: 'region', label: 'Viloyat' },
        { key: 'total', label: 'Arizalar' },
        { key: 'customers', label: 'Mijozlar' },
        { key: 'completed', label: 'Bajarilgan' },
        { key: 'open', label: 'Ochiq' },
        { key: 'in_warranty', label: 'Kafolatda' },
        { key: 'out_warranty', label: 'Kafolatsiz' },
        { key: 'parts_count', label: 'Qismlar (dona)' },
        { key: 'client_cost', label: 'Servis xarajati' },
        { key: 'top_category', label: 'Ko\'p uchragan muammo' },
      ],
      `servis-viloyatlar-${dateFrom}_${dateTo}`,
    );
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatTile label="Viloyatlar" value={d ? String(rows.length) : '—'}
                  sub={d ? `${d.customers} ta mijoz` : undefined} />
        <StatTile label="Jami arizalar" value={d ? String(d.total) : '—'}
                  sub={d ? `Bajarilgan: ${d.completed}` : undefined} tone="primary" />
        <StatTile label="Servis xarajati" value={d ? formatUZS(d.client_cost) : '—'} tone="danger"
                  sub={d ? `${d.parts_count} dona qism` : undefined} />
        <StatTile label="O'rtacha ariza narxi" value={d ? formatUZS(avgCost) : '—'}
                  sub="Bitta arizaga" />
      </div>

      <Card title="Viloyatlar bo'yicha arizalar">
        {q.isLoading ? (
          <div className="h-56 rounded-button bg-black/5 animate-pulse" />
        ) : chartRows.length === 0 ? (
          <EmptyState title="Tanlangan davrda ariza yo'q" />
        ) : (
          <ResponsiveContainer width="100%" height={Math.max(200, chartRows.length * 34)}>
            <BarChart data={chartRows} layout="vertical" margin={{ left: 24, right: 16 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="region" fontSize={11} width={130} interval={0} />
              <Tooltip formatter={(v: number) => [`${v} ta`, 'Arizalar']} />
              <Bar dataKey="total" radius={[0, 4, 4, 0]}>
                {chartRows.map((_, i) => (
                  <Cell key={i} fill={REGION_COLORS[i % REGION_COLORS.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        )}
      </Card>

      <Card
        title="Batafsil — viloyatlar kesimi"
        action={rows.length > 0 && (
          <button onClick={handleExport} className="btn-ghost text-sm">
            <Download size={15} /> Excel (CSV)
          </button>
        )}
      >
        {q.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : rows.length === 0 ? (
          <EmptyState title="Ma'lumot yo'q"
                      description="Tanlangan davrda ariza topilmadi" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm min-w-[560px] sm:min-w-0">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Viloyat</th>
                  <th className="py-2 pr-3 text-right">Arizalar</th>
                  <th className="py-2 pr-3 text-right">Mijozlar</th>
                  <th className="py-2 pr-3 text-right">Bajarilgan</th>
                  <th className="py-2 pr-3 text-right">Ochiq</th>
                  <th className="py-2 pr-3 text-right">Kafolatda</th>
                  <th className="py-2 pr-3 text-right">Qismlar</th>
                  <th className="py-2 pr-3 text-right">Xarajat</th>
                  <th className="py-2 pr-3">Ko'p uchragan muammo</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.region} className="border-b border-black/5">
                    <td className="py-2 pr-3 font-medium">
                      <span className="inline-flex items-center gap-1.5">
                        <MapPin size={13} className="text-ink-soft" /> {r.region}
                      </span>
                    </td>
                    <td className="py-2 pr-3 text-right font-semibold tabular-nums">{r.total}</td>
                    <td className="py-2 pr-3 text-right tabular-nums">{r.customers}</td>
                    <td className="py-2 pr-3 text-right tabular-nums text-success">{r.completed}</td>
                    <td className="py-2 pr-3 text-right tabular-nums">{r.new + r.scheduled}</td>
                    <td className="py-2 pr-3 text-right tabular-nums">
                      {r.in_warranty}
                      <span className="text-ink-soft"> / {r.total}</span>
                    </td>
                    <td className="py-2 pr-3 text-right tabular-nums">{r.parts_count}</td>
                    <td className="py-2 pr-3 text-right tabular-nums">{formatUZS(r.client_cost)}</td>
                    <td className="py-2 pr-3 text-ink-soft">{r.top_category || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
