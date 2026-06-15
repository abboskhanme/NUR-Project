import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';

interface Stat { name: string; count: number }

/** Ehtiyot qismlar statistikasi — qaysi qismdan jami nechta sarflangan (bar) + sana filtri. */
export default function ServicePartsStats() {
  const { t } = useTranslation();
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  const q = useQuery<Stat[]>({
    queryKey: ['service-parts-stats', from, to],
    queryFn: () => api.get('/service/parts/stats', {
      params: { date_from: from || undefined, date_to: to || undefined },
    }).then((r) => r.data),
  });
  const stats = q.data ?? [];
  const max = stats.reduce((m, s) => Math.max(m, s.count), 0) || 1;
  const total = stats.reduce((sum, s) => sum + s.count, 0);
  const filtered = !!(from || to);

  return (
    <Card title={t('service.partsStats.title')}>
      {/* Sana filtri */}
      <div className="flex items-end gap-3 flex-wrap mb-4">
        <div>
          <label className="text-xs text-ink-soft">{t('service.partsStats.from')}</label>
          <input type="date" className="input mt-1" value={from} onChange={(e) => setFrom(e.target.value)} />
        </div>
        <div>
          <label className="text-xs text-ink-soft">{t('service.partsStats.to')}</label>
          <input type="date" className="input mt-1" value={to} onChange={(e) => setTo(e.target.value)} />
        </div>
        {filtered && (
          <button onClick={() => { setFrom(''); setTo(''); }}
                  className="px-3 py-1.5 text-sm rounded-button border border-black/10 text-ink-soft hover:bg-black/5 inline-flex items-center gap-1">
            <X size={14} /> {t('service.partsStats.all')}
          </button>
        )}
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
