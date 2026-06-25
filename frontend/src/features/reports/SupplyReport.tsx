import { useQuery } from '@tanstack/react-query';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Cell,
} from 'recharts';
import { AlertTriangle } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type { DateRange, SupplySummary } from './types';

type LowStock = { name: string; unit: string; stock_qty: number; min_qty: number };
type Debt = { vendor: string; debt_uzs: number };

export default function SupplyReport({ range }: { range: DateRange }) {
  const sum = useQuery<SupplySummary>({
    queryKey: ['rep-supply', range],
    queryFn: () => api.get('/reports/supply/summary', {
      params: { date_from: range.from, date_to: range.to },
    }).then((r) => r.data),
  });

  const d = sum.data;

  const lowCols: Column<LowStock>[] = [
    { key: 'name', label: 'Tovar' },
    { key: 'stock_qty', label: 'Qoldiq', align: 'right', render: (r) => `${r.stock_qty} ${r.unit}` },
    { key: 'min_qty', label: 'Minimal', align: 'right', render: (r) => `${r.min_qty} ${r.unit}` },
  ];
  const debtCols: Column<Debt>[] = [
    { key: 'vendor', label: "Ta'minotchi" },
    { key: 'debt_uzs', label: 'Qarz', align: 'right', render: (r) => formatUZS(r.debt_uzs) },
  ];

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatTile label="Kirim (davr)" value={d ? formatUZS(d.receipts_total_uzs) : '—'} tone="primary" />
        <StatTile label="To'langan" value={d ? formatUZS(d.receipts_paid_uzs) : '—'} tone="success" />
        <StatTile label="Umumiy qarz" value={d ? formatUZS(d.debt_total_uzs) : '—'} tone="danger" />
        <StatTile label="Kam qolgan" value={d ? `${d.low_stock_count} ta` : '—'} tone="warning" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Eng katta qarzlar">
          {d && d.top_debts.length > 0 ? (
            <>
              <ResponsiveContainer width="100%" height={Math.max(180, d.top_debts.length * 34)}>
                <BarChart data={d.top_debts} layout="vertical" margin={{ left: 24 }}>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                  <XAxis type="number" fontSize={11}
                    tickFormatter={(n) => n >= 1e6 ? `${(n / 1e6).toFixed(0)}mln` : String(n)} />
                  <YAxis type="category" dataKey="vendor" fontSize={11} width={120} interval={0} />
                  <Tooltip formatter={(v: number) => formatUZS(v)} />
                  <Bar dataKey="debt_uzs" radius={[0, 4, 4, 0]}>
                    {d.top_debts.map((_, i) => <Cell key={i} fill={i === 0 ? '#E74C3C' : '#F39C12'} />)}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
              <div className="mt-3">
                <ReportTable rows={d.top_debts} columns={debtCols} filename="taminotchi-qarz" />
              </div>
            </>
          ) : (
            <div className="text-sm text-ink-soft py-12 text-center">Qarz yo'q ✓</div>
          )}
        </Card>

        <Card title="Kam qolgan tovarlar">
          {d && d.low_stock.length > 0 ? (
            <ReportTable rows={d.low_stock} columns={lowCols} filename="kam-qoldiq" />
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-center text-ink-soft text-sm">
              <AlertTriangle size={24} className="mb-2 opacity-40" />
              Barcha tovarlar yetarli ✓
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}
