import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';

interface Stat { name: string; count: number }

const MONTH_NUMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;
const pad2 = (n: number) => String(n).padStart(2, '0');

/** Ehtiyot qismlar statistikasi — oy/yil dropdown filtri bilan. */
export default function ServicePartsStats() {
  const { t } = useTranslation();
  const now = new Date();
  const [month, setMonth] = useState<number>(now.getMonth() + 1); // 0 = butun yil
  const [year, setYear] = useState<number>(now.getFullYear());

  const { dateFrom, dateTo } = useMemo(() => {
    if (month === 0) return { dateFrom: `${year}-01-01`, dateTo: `${year}-12-31` };
    const lastDay = new Date(year, month, 0).getDate();
    return { dateFrom: `${year}-${pad2(month)}-01`, dateTo: `${year}-${pad2(month)}-${pad2(lastDay)}` };
  }, [month, year]);

  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  const q = useQuery<Stat[]>({
    queryKey: ['service-parts-stats', dateFrom, dateTo],
    queryFn: () => api.get('/service/parts/stats', {
      params: { date_from: dateFrom, date_to: dateTo },
    }).then((r) => r.data),
  });
  const stats = q.data ?? [];
  const max = stats.reduce((m, s) => Math.max(m, s.count), 0) || 1;
  const total = stats.reduce((sum, s) => sum + s.count, 0);

  return (
    <Card title={t('service.partsStats.title')}>
      {/* Oy / yil filtri */}
      <div className="flex items-center gap-2 flex-wrap mb-4">
        <select className="input w-40" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
          <option value={0}>{t('service.partsStats.allYear')}</option>
          {MONTH_NUMS.map((m) => <option key={m} value={m}>{t(`sales.months.${m}`)}</option>)}
        </select>
        <select className="input w-28" value={year} onChange={(e) => setYear(Number(e.target.value))}>
          {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
        </select>
      </div>

      {q.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-7 rounded-button bg-black/5 animate-pulse" />)}
        </div>
      ) : stats.length === 0 ? (
        <EmptyState title={t('service.partsStats.empty')} />
      ) : (
        <div className="space-y-2.5">
          <div className="text-xs text-ink-soft">{t('service.partsStats.total', { n: total })}</div>
          {stats.map((s) => (
            <div key={s.name} className="flex items-center gap-3">
              <div className="w-32 shrink-0 text-sm font-medium truncate" title={s.name}>{s.name}</div>
              <div className="flex-1 h-5 rounded-full bg-black/5 overflow-hidden">
                <div className="h-full bg-primary/70 rounded-full transition-all"
                     style={{ width: `${Math.max(6, (s.count / max) * 100)}%` }} />
              </div>
              <div className="w-10 text-right text-sm font-bold text-primary">{s.count}</div>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}
