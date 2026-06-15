import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';

interface Stat { name: string; count: number }

/** Ehtiyot qismlar statistikasi — qaysi qismdan jami nechta sarflangan (bar). */
export default function ServicePartsStats() {
  const { t } = useTranslation();
  const q = useQuery<Stat[]>({
    queryKey: ['service-parts-stats'],
    queryFn: () => api.get('/service/parts/stats').then((r) => r.data),
  });
  const stats = q.data ?? [];
  const max = stats.reduce((m, s) => Math.max(m, s.count), 0) || 1;
  const total = stats.reduce((sum, s) => sum + s.count, 0);

  return (
    <Card title={t('service.partsStats.title')}>
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
