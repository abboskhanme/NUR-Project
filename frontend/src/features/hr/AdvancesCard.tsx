import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatUZS, formatDate } from '@/lib/format';

interface Advance {
  id: string;
  advance_date: string;
  amount: string;
  currency: string;
  note?: string | null;
  status?: string;
}

export default function AdvancesCard({ employeeId }: { employeeId: string }) {
  const { t } = useTranslation();
  const nowYear = new Date().getFullYear();
  const [filterMonth, setFilterMonth] = useState(0); // 0 = all, 1-12
  const [filterYear, setFilterYear] = useState(nowYear);

  const { data, isLoading } = useQuery<Advance[]>({
    queryKey: ['hr', 'advances', employeeId, filterYear, filterMonth],
    queryFn: () => {
      const params: Record<string, string> = { employee_id: employeeId };
      if (filterMonth > 0) {
        const last = new Date(filterYear, filterMonth, 0).getDate();
        const mm = String(filterMonth).padStart(2, '0');
        params.date_from = `${filterYear}-${mm}-01`;
        params.date_to = `${filterYear}-${mm}-${String(last).padStart(2, '0')}`;
      }
      return api.get('/hr/advances', { params }).then((r) => r.data);
    },
  });
  const items = data ?? [];
  // Bekor qilingan (void) avanslar jamiga kirmaydi
  const total = items.reduce((s, a) => s + (a.status === 'void' ? 0 : (parseFloat(a.amount) || 0)), 0);

  return (
    <Card title={t('hr.advances.title')}>
      {/* Month filter */}
      <div className="flex items-center gap-2 flex-wrap mb-3">
        <span className="text-sm text-ink-soft">{t('hr.advances.filterLabel')}</span>
        <select
          className="input !w-36"
          value={filterMonth}
          onChange={(e) => setFilterMonth(Number(e.target.value))}
        >
          <option value={0}>{t('common.all')}</option>
          {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
            <option key={m} value={m}>{t(`hr.months.${m}`)}</option>
          ))}
        </select>
        {filterMonth > 0 && (
          <select
            className="input !w-28"
            value={filterYear}
            onChange={(e) => setFilterYear(Number(e.target.value))}
          >
            {[nowYear, nowYear - 1, nowYear - 2].map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
        )}
        {items.length > 0 && (
          <span className="ml-auto text-sm text-ink-soft">
            {t('hr.advances.total')} <span className="font-semibold text-ink">{formatUZS(total)}</span>
          </span>
        )}
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <EmptyState title={t('hr.advances.emptyTitle')} description={t('hr.advances.emptyDesc')} />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-4">{t('hr.advances.colDate')}</th>
                <th className="py-2 pl-6 pr-8 text-right">{t('hr.advances.colAmount')}</th>
                <th className="py-2 pl-6 w-full">{t('hr.advances.colNote')}</th>
              </tr>
            </thead>
            <tbody>
              {items.map((a) => {
                const voided = a.status === 'void';
                return (
                  <tr key={a.id} className={`border-b border-black/5 ${voided ? 'text-ink/40' : ''}`}>
                    <td className="py-2 pr-4 whitespace-nowrap">{formatDate(a.advance_date)}</td>
                    <td className={`py-2 pl-6 pr-8 text-right tabular-nums font-medium whitespace-nowrap ${voided ? 'line-through' : ''}`}>{formatUZS(a.amount)}</td>
                    <td className="py-2 pl-6 text-ink/70 w-full">
                      {voided
                        ? <span className="badge bg-danger/10 text-danger">{t('hr.histModal.voidedBadge')}</span>
                        : (a.note || '—')}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
