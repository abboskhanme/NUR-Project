import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatUZS } from '@/lib/format';

interface Trip {
  id: string; name?: string | null; status: string;
  collected: string; spent: string; ticket_count: number;
  opened_at: string; closed_at?: string | null;
}

/** Yakunlangan (yopilgan) servis safarlari ro'yxati. */
export default function ServiceTripsList() {
  const { t } = useTranslation();
  const q = useQuery<Trip[]>({
    queryKey: ['service-trips-history'],
    queryFn: () => api.get('/service/trips').then((r) => r.data),
  });
  const trips = q.data ?? [];

  return (
    <Card>
      {q.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
        </div>
      ) : trips.length === 0 ? (
        <EmptyState title={t('service.trip.empty')} description={t('service.trip.emptyDesc')} />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">{t('service.trip.colName')}</th>
                <th className="py-2 pr-3">{t('service.trip.colDate')}</th>
                <th className="py-2 pr-3 text-right">{t('service.trip.colTickets')}</th>
                <th className="py-2 pr-3 text-right">{t('service.trip.collected')}</th>
                <th className="py-2 pr-3 text-right">{t('service.trip.spent')}</th>
                <th className="py-2 pr-3 text-right">{t('service.trip.net')}</th>
              </tr>
            </thead>
            <tbody>
              {trips.map((tr) => {
                const net = Number(tr.collected) - Number(tr.spent);
                return (
                  <tr key={tr.id} className="border-b border-black/5 hover:bg-black/5">
                    <td className="py-2 pr-3 font-medium">{tr.name || '—'}</td>
                    <td className="py-2 pr-3 whitespace-nowrap">{formatDate(tr.closed_at || tr.opened_at)}</td>
                    <td className="py-2 pr-3 text-right">{tr.ticket_count}</td>
                    <td className="py-2 pr-3 text-right text-success">{formatUZS(tr.collected)}</td>
                    <td className="py-2 pr-3 text-right text-danger">{formatUZS(tr.spent)}</td>
                    <td className={'py-2 pr-3 text-right font-semibold ' + (net >= 0 ? 'text-success' : 'text-danger')}>
                      {formatUZS(net)}
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
