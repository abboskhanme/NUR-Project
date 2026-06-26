import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronLeft, ChevronRight, TrendingUp, TrendingDown } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatUSD, formatUZS } from '@/lib/format';

interface AccountRow {
  account_id: string; account_name: string; currency: string;
  opening_balance: string; income: string; expense: string; closing_balance: string;
}
interface DayRow {
  date: string; accounts: AccountRow[];
  income_uzs: string; expense_uzs: string; income_usd: string; expense_usd: string;
}
interface Daily { year: number; month: number; days: DayRow[] }

const MONTH_LABELS = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
];

const n = (v: string) => Number(v) || 0;
const money = (v: string | number, c: string) =>
  c === 'USD' ? formatUSD(typeof v === 'number' ? v : Number(v)) : formatUZS(typeof v === 'number' ? v : Number(v));

export default function DailyReport() {
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);

  const q = useQuery<Daily>({
    queryKey: ['finance-daily', year, month],
    queryFn: () => api.get('/finance/daily', { params: { year, month } }).then((r) => r.data),
  });

  const days = q.data?.days ?? [];
  // Eng yangi kun yuqorida
  const ordered = [...days].reverse();

  const prevMonth = () => {
    if (month === 1) { setMonth(12); setYear((y) => y - 1); } else setMonth((m) => m - 1);
  };
  const nextMonth = () => {
    if (month === 12) { setMonth(1); setYear((y) => y + 1); } else setMonth((m) => m + 1);
  };

  return (
    <div className="space-y-4">
      {/* Davr tanlash */}
      <div className="flex items-center gap-2">
        <button onClick={prevMonth} className="p-1.5 rounded-button border border-black/10 hover:bg-black/5">
          <ChevronLeft size={16} />
        </button>
        <span className="text-sm font-medium min-w-[120px] text-center">{MONTH_LABELS[month - 1]} {year}</span>
        <button onClick={nextMonth} className="p-1.5 rounded-button border border-black/10 hover:bg-black/5">
          <ChevronRight size={16} />
        </button>
      </div>

      {q.isLoading ? (
        <div className="text-sm text-ink-soft py-12 text-center">Yuklanmoqda…</div>
      ) : ordered.length === 0 ? (
        <EmptyState title="Bu oyda harakat yo'q" description="Tanlangan oyda kirim/chiqim qayd etilmagan" />
      ) : (
        ordered.map((day) => (
          <Card key={day.date} title={formatDate(day.date)}>
            {/* Kunlik jami */}
            <div className="flex flex-wrap gap-x-6 gap-y-1 mb-3 text-sm">
              {(n(day.income_uzs) > 0 || n(day.expense_uzs) > 0) && (
                <>
                  <span className="flex items-center gap-1 text-success">
                    <TrendingUp size={14} /> {formatUZS(n(day.income_uzs))}
                  </span>
                  <span className="flex items-center gap-1 text-danger">
                    <TrendingDown size={14} /> {formatUZS(n(day.expense_uzs))}
                  </span>
                </>
              )}
              {(n(day.income_usd) > 0 || n(day.expense_usd) > 0) && (
                <>
                  <span className="flex items-center gap-1 text-success">
                    <TrendingUp size={14} /> {formatUSD(n(day.income_usd))}
                  </span>
                  <span className="flex items-center gap-1 text-danger">
                    <TrendingDown size={14} /> {formatUSD(n(day.expense_usd))}
                  </span>
                </>
              )}
            </div>

            {/* Kassalar bo'yicha */}
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-1.5 pr-3">Kassa</th>
                    <th className="py-1.5 pr-3 text-right">Kun boshi</th>
                    <th className="py-1.5 pr-3 text-right">Kirim</th>
                    <th className="py-1.5 pr-3 text-right">Chiqim</th>
                    <th className="py-1.5 text-right">Kun oxiri</th>
                  </tr>
                </thead>
                <tbody>
                  {day.accounts
                    .map((a) => (
                      <tr key={a.account_id} className="border-b border-black/5 last:border-0">
                        <td className="py-1.5 pr-3 font-medium">{a.account_name}</td>
                        <td className="py-1.5 pr-3 text-right text-ink-soft">{money(a.opening_balance, a.currency)}</td>
                        <td className="py-1.5 pr-3 text-right text-success">
                          {n(a.income) > 0 ? `+${money(a.income, a.currency)}` : '—'}
                        </td>
                        <td className="py-1.5 pr-3 text-right text-danger">
                          {n(a.expense) > 0 ? `−${money(a.expense, a.currency)}` : '—'}
                        </td>
                        <td className="py-1.5 text-right font-semibold">{money(a.closing_balance, a.currency)}</td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </Card>
        ))
      )}
    </div>
  );
}
