import { useQuery } from '@tanstack/react-query';
import { Plus } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import StatusBadge from '@/components/ui/StatusBadge';
import { formatDateTime } from '@/lib/format';

interface Ticket {
  id: string; code: string; problem: string; status: string;
  in_warranty: boolean; opened_at: string; scheduled_at?: string | null;
}

export default function ServicePage() {
  const { data, isLoading } = useQuery({
    queryKey: ['service-tickets'],
    queryFn: () => api.get('/service/tickets').then((r) => r.data),
  });

  const tickets: Ticket[] = data?.items ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Servis xizmati</h1>
          <p className="text-sm text-ink-soft">Kafolat va texnik tashriflar</p>
        </div>
        <button className="btn-primary"><Plus size={16} /> Yangi ariza</button>
      </div>

      <Card>
        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : tickets.length === 0 ? (
          <EmptyState title="Servis arizalari yo'q" />
        ) : (
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Kod</th>
                <th className="py-2 pr-3">Muammo</th>
                <th className="py-2 pr-3">Ochilgan</th>
                <th className="py-2 pr-3">Rejalashtirilgan</th>
                <th className="py-2 pr-3">Kafolat</th>
                <th className="py-2 pr-3">Status</th>
              </tr>
            </thead>
            <tbody>
              {tickets.map((t) => (
                <tr key={t.id} className="border-b border-black/5 hover:bg-black/5">
                  <td className="py-2 pr-3 font-medium">{t.code}</td>
                  <td className="py-2 pr-3 max-w-[300px] truncate">{t.problem}</td>
                  <td className="py-2 pr-3">{formatDateTime(t.opened_at)}</td>
                  <td className="py-2 pr-3">{formatDateTime(t.scheduled_at)}</td>
                  <td className="py-2 pr-3">
                    {t.in_warranty
                      ? <span className="badge bg-success/10 text-success">Ha</span>
                      : <span className="badge bg-gray-100 text-gray-700">Yo'q</span>}
                  </td>
                  <td className="py-2 pr-3"><StatusBadge status={t.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  );
}
