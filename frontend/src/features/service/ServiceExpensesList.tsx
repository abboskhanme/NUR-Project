import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Coins } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatPhone, formatUZS } from '@/lib/format';
import TicketDetailModal from '@/features/service/TicketDetailModal';

interface Expense {
  id: string;
  code: string;
  customer_name?: string | null;
  customer_phone?: string | null;
  expense_date?: string | null;
  amount: string;
  problem?: string | null;
  category?: string | null;
  in_warranty: boolean;
}

const MONTH_NUMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;
const pad2 = (n: number) => String(n).padStart(2, '0');
const SVC_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentabr', '10': 'Oktabr', '11': 'Noyabr', '12': 'Dekabr',
};

/**
 * Har bir arizadagi "Servis xarajati" (client_cost) alohida ro'yxat — o'zining
 * oy/yil filtri bilan (mustaqil). Qatorni bosish — ariza detali (tahrirlash mumkin).
 */
export default function ServiceExpensesList() {
  const now = new Date();
  const [month, setMonth] = useState<number>(now.getMonth() + 1); // 0 = butun yil
  const [year, setYear] = useState<number>(now.getFullYear());
  const [detailId, setDetailId] = useState<string | null>(null);

  const { dateFrom, dateTo } = useMemo(() => {
    if (month === 0) return { dateFrom: `${year}-01-01`, dateTo: `${year}-12-31` };
    const lastDay = new Date(year, month, 0).getDate();
    return { dateFrom: `${year}-${pad2(month)}-01`, dateTo: `${year}-${pad2(month)}-${pad2(lastDay)}` };
  }, [month, year]);

  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  const q = useQuery<Expense[]>({
    queryKey: ['service-expenses', dateFrom, dateTo],
    queryFn: () => api.get('/service/expenses', {
      params: { date_from: dateFrom, date_to: dateTo },
    }).then((r) => r.data),
  });
  const items = q.data ?? [];
  const total = items.reduce((s, e) => s + Number(e.amount || 0), 0);
  const periodLabel = month === 0 ? `${year}` : `${SVC_MONTHS[String(month)]} ${year}`;

  return (
    <Card>
      <div className="flex items-center justify-between gap-2 mb-3 flex-wrap">
        <div className="flex items-center gap-2 font-semibold">
          <Coins size={16} className="text-danger" /> Servis xarajatlari (arizalar bo'yicha)
        </div>
        <div className="flex items-center gap-2">
          <select className="input h-9 py-0 w-32" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
            <option value={0}>Butun yil</option>
            {MONTH_NUMS.map((mo) => <option key={mo} value={mo}>{SVC_MONTHS[String(mo)]}</option>)}
          </select>
          <select className="input h-9 py-0 w-24" value={year} onChange={(e) => setYear(Number(e.target.value))}>
            {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>
      </div>

      <div className="flex items-center justify-between gap-2 mb-3 text-sm text-ink-soft">
        <span>{periodLabel}</span>
        {items.length > 0 && (
          <span>
            {items.length} ta · Jami:{' '}
            <span className="font-bold text-danger tabular-nums">{formatUZS(total)}</span>
          </span>
        )}
      </div>

      {q.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-11 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <EmptyState
          title="Servis xarajati yo'q"
          description={`${periodLabel} uchun ariza xarajati kiritilmagan`}
        />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3 whitespace-nowrap">Sana</th>
                <th className="py-2 pr-3">Mijoz</th>
                <th className="py-2 pr-3">Ariza</th>
                <th className="py-2 pr-3">Muammo / Toifa</th>
                <th className="py-2 pr-3 text-right whitespace-nowrap">Xarajat</th>
              </tr>
            </thead>
            <tbody>
              {items.map((e) => (
                <tr key={e.id} onClick={() => setDetailId(e.id)}
                    className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                  <td className="py-2 pr-3 whitespace-nowrap text-ink-soft">
                    {e.expense_date ? formatDate(e.expense_date) : '—'}
                  </td>
                  <td className="py-2 pr-3">
                    <div className="font-medium">{e.customer_name || '—'}</div>
                    {e.customer_phone && (
                      <div className="text-xs text-ink-soft">{formatPhone(e.customer_phone)}</div>
                    )}
                  </td>
                  <td className="py-2 pr-3 whitespace-nowrap">
                    <span className="font-mono text-xs text-ink-soft">{e.code}</span>
                    {e.in_warranty && (
                      <span className="ml-1.5 badge bg-success/10 text-success">Kafolat</span>
                    )}
                  </td>
                  <td className="py-2 pr-3 max-w-[260px] truncate">
                    {e.category || e.problem || '—'}
                  </td>
                  <td className="py-2 pr-3 text-right font-semibold text-danger tabular-nums whitespace-nowrap">
                    {formatUZS(e.amount)}
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="border-t border-black/10">
                <td className="py-2 pr-3 font-semibold" colSpan={4}>Jami</td>
                <td className="py-2 pr-3 text-right font-bold text-danger tabular-nums whitespace-nowrap">
                  {formatUZS(total)}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}

      {detailId && (
        <TicketDetailModal
          ticketId={detailId}
          onClose={() => setDetailId(null)}
          onChanged={() => q.refetch()}
        />
      )}
    </Card>
  );
}
