import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Cell,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type { DateRange, PnlData } from './types';

const COLORS = ['#E74C3C', '#F39C12', '#8E44AD', '#2980B9', '#16A085', '#1E3A5F', '#7F8C8D', '#C0392B'];

type CatRow = { category: string; amount: number };

export default function FinanceReport({ range }: { range: DateRange }) {
  const { t } = useTranslation();
  const pnl = useQuery<PnlData>({
    queryKey: ['rep-pnl', range],
    queryFn: () => api.get('/reports/finance/pnl', {
      params: { date_from: range.from, date_to: range.to },
    }).then((r) => r.data),
  });

  const cols: Column<CatRow>[] = [
    { key: 'category', label: t('reports.finance.cols.category') },
    { key: 'amount', label: t('reports.finance.cols.amount'), align: 'right', render: (r) => formatUZS(r.amount) },
  ];

  const cats = pnl.data?.expense_by_category ?? [];
  const totalExp = cats.reduce((s, c) => s + c.amount, 0);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatTile label={t('reports.finance.kpi.income')} value={pnl.data ? formatUZS(pnl.data.income) : '—'} tone="success" />
        <StatTile label={t('reports.finance.kpi.expense')} value={pnl.data ? formatUZS(pnl.data.expense) : '—'} tone="danger" />
        <StatTile label={t('reports.finance.kpi.netProfit')} value={pnl.data ? formatUZS(pnl.data.net) : '—'}
          tone={pnl.data && pnl.data.net >= 0 ? 'primary' : 'warning'} />
        <StatTile label={t('reports.finance.kpi.margin')} value={pnl.data?.margin_pct != null ? `${pnl.data.margin_pct}%` : '—'} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title={t('reports.finance.cards.pnlChart')}>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={[
              { name: t('reports.finance.chart.income'), value: pnl.data?.income ?? 0, fill: '#27AE60' },
              { name: t('reports.finance.chart.expense'), value: pnl.data?.expense ?? 0, fill: '#E74C3C' },
              { name: t('reports.finance.chart.netProfit'), value: pnl.data?.net ?? 0, fill: '#1E3A5F' },
            ]}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="name" fontSize={12} />
              <YAxis fontSize={11} width={60}
                tickFormatter={(n) => n >= 1e9 ? `${(n / 1e9).toFixed(1)}mlrd` : n >= 1e6 ? `${(n / 1e6).toFixed(0)}mln` : String(n)} />
              <Tooltip formatter={(v: number) => formatUZS(v)} />
              <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                {[0, 1, 2].map((i) => <Cell key={i} fill={['#27AE60', '#E74C3C', '#1E3A5F'][i]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card title={t('reports.finance.cards.expenseByCategory')}>
          {cats.length > 0 ? (
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={cats} layout="vertical" margin={{ left: 24 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                <XAxis type="number" fontSize={11}
                  tickFormatter={(n) => n >= 1e6 ? `${(n / 1e6).toFixed(0)}mln` : String(n)} />
                <YAxis type="category" dataKey="category" fontSize={11} width={120} interval={0} />
                <Tooltip formatter={(v: number) => formatUZS(v)} />
                <Bar dataKey="amount" radius={[0, 4, 4, 0]}>
                  {cats.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="text-sm text-ink-soft py-12 text-center">{t('reports.finance.chart.noExpense')}</div>
          )}
        </Card>
      </div>

      <Card title={t('reports.finance.cards.expenseDetail')}>
        <ReportTable
          rows={pnl.data?.expense_by_category}
          columns={cols}
          filename="chiqimlar-kategoriya"
          footer={
            <>
              <td className="py-2 px-2">{t('reports.table.total')}</td>
              <td className="py-2 px-2 text-right">{formatUZS(totalExp)}</td>
            </>
          }
        />
      </Card>
    </div>
  );
}
