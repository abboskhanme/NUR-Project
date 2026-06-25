import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatPhone, formatUZS } from '@/lib/format';
import { ServiceStatusBadge } from '@/features/service/status';

interface Trip {
  id: string; name?: string | null; status: string;
  collected: string; spent: string; ticket_count: number;
  opened_at: string; closed_at?: string | null;
}

/** Yakunlangan (yopilgan) servis safarlari ro'yxati. Qatorni bosish — arizalar modali. */
export default function ServiceTripsList({ dateFrom, dateTo }: { dateFrom?: string; dateTo?: string } = {}) {
  const [openTrip, setOpenTrip] = useState<Trip | null>(null);
  const q = useQuery<Trip[]>({
    queryKey: ['service-trips-history', dateFrom ?? '', dateTo ?? ''],
    queryFn: () => api.get('/service/trips', {
      params: { date_from: dateFrom || undefined, date_to: dateTo || undefined },
    }).then((r) => r.data),
  });
  const trips = q.data ?? [];

  return (
    <Card>
      {q.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
        </div>
      ) : trips.length === 0 ? (
        <EmptyState title="Yakunlangan safarlar yo'q" description="Safarni yakunlaganingizda shu yerda ko'rinadi" />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Safar nomi</th>
                <th className="py-2 pr-3">Sana</th>
                <th className="py-2 pr-3 text-right">Arizalar</th>
                <th className="py-2 pr-3 text-right">Olingan</th>
                <th className="py-2 pr-3 text-right">Sarflangan</th>
                <th className="py-2 pr-3 text-right">Sof</th>
              </tr>
            </thead>
            <tbody>
              {trips.map((tr) => {
                const net = Number(tr.collected) - Number(tr.spent);
                return (
                  <tr key={tr.id} onClick={() => setOpenTrip(tr)}
                      className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
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

      {openTrip && <TripTicketsModal trip={openTrip} onClose={() => setOpenTrip(null)} />}
    </Card>
  );
}

interface TripTicket {
  id: string; code: string; problem: string; status: string;
  address?: string | null; opened_at: string; parts_used?: string[];
  customer?: { full_name: string; phone: string } | null;
}

function TripTicketsModal({ trip, onClose }: { trip: Trip; onClose: () => void }) {
  const q = useQuery<TripTicket[]>({
    queryKey: ['trip-tickets', trip.id],
    queryFn: () => api.get(`/service/trips/${trip.id}/tickets`).then((r) => r.data),
  });
  const tickets = q.data ?? [];

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[88vh] overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <div>
            <h3 className="font-semibold">{trip.name || 'Servis safari'}</h3>
            <p className="text-xs text-ink-soft">
              {formatDate(trip.closed_at || trip.opened_at)} · Safardagi arizalar ({trip.ticket_count})
            </p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="p-4 overflow-y-auto space-y-2">
          {q.isLoading ? (
            Array.from({ length: 4 }).map((_, i) => <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />)
          ) : tickets.length === 0 ? (
            <EmptyState title="Yakunlangan safarlar yo'q" />
          ) : (
            tickets.map((tk) => (
              <div key={tk.id} className="rounded-button border border-black/5 bg-black/[0.02] p-3 text-sm">
                <div className="flex items-center justify-between gap-2">
                  <span className="font-medium">{tk.customer?.full_name ?? '—'}</span>
                  <ServiceStatusBadge status={tk.status} />
                </div>
                {tk.customer?.phone && <div className="text-xs text-ink-soft">{formatPhone(tk.customer.phone)}</div>}
                <div className="mt-1">{tk.problem}</div>
                {tk.address && <div className="text-xs text-ink-soft mt-0.5">{tk.address}</div>}
                {tk.parts_used && tk.parts_used.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-1.5">
                    {tk.parts_used.map((p) => (
                      <span key={p} className="px-2 py-0.5 rounded-full bg-primary/10 text-primary text-[11px]">{p}</span>
                    ))}
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
