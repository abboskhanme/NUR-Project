import { useState } from 'react';
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

/**
 * Har bir arizadagi "Servis xarajati" (client_cost) alohida ro'yxat.
 * Davr (oy/yil) filtri yuqoridagi umumiy filtrdan keladi — butun hisobot bo'limi
 * uchun bitta filtr. Yig'indisi "Servis xarajati" kartasiga mos keladi.
 * Qatorni bosish — ariza detali (tahrirlash mumkin).
 */
export default function ServiceExpensesList({ dateFrom, dateTo }: { dateFrom?: string; dateTo?: string }) {
  const [detailId, setDetailId] = useState<string | null>(null);

  const q = useQuery<Expense[]>({
    queryKey: ['service-expenses', dateFrom ?? '', dateTo ?? ''],
    queryFn: () => api.get('/service/expenses', {
      params: { date_from: dateFrom || undefined, date_to: dateTo || undefined },
    }).then((r) => r.data),
  });
  const items = q.data ?? [];
  const total = items.reduce((s, e) => s + Number(e.amount || 0), 0);

  return (
    <Card>
      <div className="flex items-center justify-between gap-2 mb-3 flex-wrap">
        <div className="flex items-center gap-2 font-semibold">
          <Coins size={16} className="text-danger" /> Servis xarajatlari (arizalar bo'yicha)
        </div>
        {items.length > 0 && (
          <div className="text-sm text-ink-soft">
            {items.length} ta · Jami:{' '}
            <span className="font-bold text-danger tabular-nums">{formatUZS(total)}</span>
          </div>
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
          description="Ariza ichida 'Servis xarajati' kiritilganda shu yerda ko'rinadi"
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
