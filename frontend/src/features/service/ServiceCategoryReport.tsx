import { Fragment, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronDown, ChevronRight, Download } from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Cell, ResponsiveContainer,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import StatTile from '@/features/reports/StatTile';
import { formatUZS } from '@/lib/format';
import { exportCSV } from '@/lib/export';
import ServiceRegionReport from '@/features/service/ServiceRegionReport';

interface PartStat { name: string; count: number }
interface Row {
  category: string;
  total: number; new: number; scheduled: number; completed: number; cancelled: number;
  in_warranty: number; out_warranty: number;
  client_cost: string; parts_count: number;
  parts: PartStat[];
}
interface Report {
  total: number; new: number; scheduled: number; completed: number; cancelled: number;
  in_warranty: number; out_warranty: number;
  client_cost: string; parts_count: number;
  rows: Row[];
}

const MONTH_NUMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;
const pad2 = (n: number) => String(n).padStart(2, '0');

const SALES_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentabr', '10': 'Oktabr', '11': 'Noyabr', '12': 'Dekabr',
};

const CAT_COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C', '#8E44AD', '#16A085', '#7F8C8D'];

const VIEWS = [
  { key: 'category', label: "Toifalar bo'yicha" },
  { key: 'region', label: "Viloyatlar bo'yicha" },
] as const;
type View = (typeof VIEWS)[number]['key'];

/** Servis hisoboti — toifalar va viloyatlar kesimida (oy/yil filtri bilan). */
export default function ServiceCategoryReport() {
  const now = new Date();
  const [month, setMonth] = useState<number>(now.getMonth() + 1); // 0 = butun yil
  const [year, setYear] = useState<number>(now.getFullYear());
  const [hideEmpty, setHideEmpty] = useState(false);
  const [open, setOpen] = useState<string | null>(null);
  const [view, setView] = useState<View>('category');

  const { dateFrom, dateTo } = useMemo(() => {
    if (month === 0) return { dateFrom: `${year}-01-01`, dateTo: `${year}-12-31` };
    const lastDay = new Date(year, month, 0).getDate();
    return { dateFrom: `${year}-${pad2(month)}-01`, dateTo: `${year}-${pad2(month)}-${pad2(lastDay)}` };
  }, [month, year]);

  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  const q = useQuery<Report>({
    queryKey: ['service-category-report', dateFrom, dateTo],
    queryFn: () => api.get('/service/report', {
      params: { date_from: dateFrom, date_to: dateTo },
    }).then((r) => r.data),
    enabled: view === 'category',
  });

  const d = q.data;
  const allRows = d?.rows ?? [];
  const rows = hideEmpty ? allRows.filter((r) => r.total > 0) : allRows;
  const chartRows = allRows.filter((r) => r.total > 0);
  const emptyCount = allRows.length - chartRows.length;

  function handleExport() {
    exportCSV(
      rows.map((r) => ({
        category: r.category, total: r.total, new: r.new, scheduled: r.scheduled,
        completed: r.completed, cancelled: r.cancelled,
        in_warranty: r.in_warranty, out_warranty: r.out_warranty,
        parts_count: r.parts_count, client_cost: r.client_cost,
      })),
      [
        { key: 'category', label: 'Toifa' },
        { key: 'total', label: 'Jami' },
        { key: 'new', label: 'Yangi' },
        { key: 'scheduled', label: 'Rejalashtirilgan' },
        { key: 'completed', label: 'Bajarilgan' },
        { key: 'cancelled', label: 'Bekor qilingan' },
        { key: 'in_warranty', label: 'Kafolatda' },
        { key: 'out_warranty', label: 'Kafolatsiz' },
        { key: 'parts_count', label: 'Qismlar (dona)' },
        { key: 'client_cost', label: 'Servis xarajati' },
      ],
      `servis-hisobot-${dateFrom}_${dateTo}`,
    );
  }

  return (
    <div className="space-y-4">
      {/* Oy / yil filtri */}
      <div className="flex items-center gap-2 flex-wrap">
        <select className="input w-40" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
          <option value={0}>Butun yil</option>
          {MONTH_NUMS.map((mo) => <option key={mo} value={mo}>{SALES_MONTHS[String(mo)]}</option>)}
        </select>
        <select className="input w-28" value={year} onChange={(e) => setYear(Number(e.target.value))}>
          {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
        </select>
        <span className="text-xs text-ink-soft">Ish bajarilgan sana bo'yicha</span>

        <div className="flex gap-1 ml-auto">
          {VIEWS.map((v) => (
            <button key={v.key} onClick={() => setView(v.key)}
              className={'px-3 py-1.5 rounded-button text-sm font-medium transition ' +
                (view === v.key ? 'bg-primary text-white'
                                : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
              {v.label}
            </button>
          ))}
        </div>
      </div>

      {view === 'region' ? (
        <ServiceRegionReport dateFrom={dateFrom} dateTo={dateTo} />
      ) : (
      <>

      {/* Umumiy ko'rsatkichlar */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <StatTile label="Jami arizalar" value={d ? String(d.total) : '—'} />
        <StatTile label="Bajarilgan" value={d ? String(d.completed) : '—'} tone="success" />
        <StatTile label="Ochiq (yangi + reja)" value={d ? String(d.new + d.scheduled) : '—'} tone="primary" />
        <StatTile label="Kafolatda" value={d ? `${d.in_warranty} / ${d.total}` : '—'}
              sub={d ? `Kafolatsiz: ${d.out_warranty}` : undefined} />
        <StatTile label="Servis xarajati" value={d ? formatUZS(d.client_cost) : '—'} tone="danger"
              sub={d ? `${d.parts_count} dona qism` : undefined} />
      </div>

      {/* Toifalar bo'yicha diagramma */}
      <Card title="Toifalar bo'yicha arizalar">
        {q.isLoading ? (
          <div className="h-56 rounded-button bg-black/5 animate-pulse" />
        ) : chartRows.length === 0 ? (
          <EmptyState title="Tanlangan davrda ariza yo'q" />
        ) : (
          <ResponsiveContainer width="100%" height={Math.max(200, chartRows.length * 34)}>
            <BarChart data={chartRows} layout="vertical" margin={{ left: 24, right: 16 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} allowDecimals={false} />
              <YAxis type="category" dataKey="category" fontSize={11} width={130} interval={0} />
              <Tooltip formatter={(v: number) => [`${v} ta`, 'Arizalar']} />
              <Bar dataKey="total" radius={[0, 4, 4, 0]}>
                {chartRows.map((_, i) => <Cell key={i} fill={CAT_COLORS[i % CAT_COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        )}
      </Card>

      {/* Batafsil jadval — barcha toifalar */}
      <Card
        title="Toifalar kesimida batafsil"
        action={
          <div className="flex items-center gap-3">
            {emptyCount > 0 && (
              <label className="flex items-center gap-1.5 text-xs text-ink-soft cursor-pointer">
                <input type="checkbox" checked={hideEmpty}
                       onChange={(e) => setHideEmpty(e.target.checked)} />
                {`Arizasiz toifalarni yashirish (${emptyCount})`}
              </label>
            )}
            <button onClick={handleExport} disabled={rows.length === 0}
                    className="inline-flex items-center gap-1.5 text-sm text-primary hover:text-primary-700 disabled:opacity-40">
              <Download size={15} /> CSV
            </button>
          </div>
        }
      >
        {q.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-9 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : rows.length === 0 ? (
          <EmptyState title="Toifa yo'q"
                      description="Toifalar «Toifalar» tugmasi orqali qo'shiladi" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/10">
                <tr>
                  <th className="py-2 pr-2 font-medium">Toifa</th>
                  <th className="py-2 px-2 font-medium text-right">Jami</th>
                  <th className="py-2 px-2 font-medium text-right">Yangi</th>
                  <th className="py-2 px-2 font-medium text-right">Reja</th>
                  <th className="py-2 px-2 font-medium text-right">Bajarilgan</th>
                  <th className="py-2 px-2 font-medium text-right">Bekor</th>
                  <th className="py-2 px-2 font-medium text-right">Kafolatda</th>
                  <th className="py-2 px-2 font-medium text-right">Kafolatsiz</th>
                  <th className="py-2 px-2 font-medium text-right">Qismlar</th>
                  <th className="py-2 pl-2 font-medium text-right">Servis xarajati</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => {
                  const expandable = r.parts.length > 0;
                  const isOpen = open === r.category;
                  return (
                    <Fragment key={r.category}>
                      <tr
                          onClick={() => expandable && setOpen(isOpen ? null : r.category)}
                          className={'border-b border-black/5 ' +
                            (expandable ? 'cursor-pointer hover:bg-primary/5' : '') +
                            (r.total === 0 ? ' text-ink-soft' : '')}>
                        <td className="py-2 pr-2 font-medium">
                          <span className="inline-flex items-center gap-1">
                            {expandable
                              ? (isOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />)
                              : <span className="w-3.5" />}
                            {r.category}
                          </span>
                        </td>
                        <td className="py-2 px-2 text-right font-bold tabular-nums">{r.total}</td>
                        <td className="py-2 px-2 text-right tabular-nums">{r.new || '—'}</td>
                        <td className="py-2 px-2 text-right tabular-nums">{r.scheduled || '—'}</td>
                        <td className="py-2 px-2 text-right tabular-nums text-success">{r.completed || '—'}</td>
                        <td className="py-2 px-2 text-right tabular-nums">{r.cancelled || '—'}</td>
                        <td className="py-2 px-2 text-right tabular-nums">{r.in_warranty || '—'}</td>
                        <td className="py-2 px-2 text-right tabular-nums">{r.out_warranty || '—'}</td>
                        <td className="py-2 px-2 text-right tabular-nums">{r.parts_count || '—'}</td>
                        <td className="py-2 pl-2 text-right tabular-nums font-medium">
                          {Number(r.client_cost) > 0 ? formatUZS(r.client_cost) : '—'}
                        </td>
                      </tr>
                      {isOpen && (
                        <tr className="border-b border-black/5 bg-black/[0.02]">
                          <td colSpan={10} className="py-2 px-6">
                            <div className="text-xs text-ink-soft mb-1.5">Sarflangan ehtiyot qismlar</div>
                            <div className="flex flex-wrap gap-1.5">
                              {r.parts.map((p) => (
                                <span key={p.name} className="badge bg-primary/10 text-primary">
                                  {`${p.name} — ${p.count} dona`}
                                </span>
                              ))}
                            </div>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  );
                })}
              </tbody>
              {d && (
                <tfoot>
                  <tr className="border-t-2 border-black/10 font-semibold">
                    <td className="py-2 pr-2">Jami</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.total}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.new}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.scheduled}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.completed}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.cancelled}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.in_warranty}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.out_warranty}</td>
                    <td className="py-2 px-2 text-right tabular-nums">{d.parts_count}</td>
                    <td className="py-2 pl-2 text-right tabular-nums">{formatUZS(d.client_cost)}</td>
                  </tr>
                </tfoot>
              )}
            </table>
          </div>
        )}
      </Card>
      </>
      )}
    </div>
  );
}
