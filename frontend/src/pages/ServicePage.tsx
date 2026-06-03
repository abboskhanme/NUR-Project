import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Plus, Search, Wrench, CalendarClock, ShieldCheck, ClipboardList, Tag } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import BalanceCard from '@/components/ui/BalanceCard';
import { formatDateTime, formatPhone } from '@/lib/format';
import ServiceTicketModal from '@/features/service/ServiceTicketModal';
import TicketDetailModal from '@/features/service/TicketDetailModal';
import ServiceCategoryModal from '@/features/service/ServiceCategoryModal';
import { ServiceStatusBadge } from '@/features/service/status';

interface Ticket {
  id: string; code: string; problem: string; status: string;
  in_warranty: boolean; opened_at: string; scheduled_at?: string | null;
  customer?: { full_name: string; phone: string } | null;
  order?: { code: string } | null;
}
interface Summary {
  total: number; new: number; scheduled: number;
  completed: number; cancelled: number; in_warranty_open: number; scheduled_next7: number;
}

const FILTERS: Array<{ key: string; label: string }> = [
  { key: '', label: 'Hammasi' },
  { key: 'new', label: 'Yangi' },
  { key: 'scheduled', label: 'Rejalashtirilgan' },
  { key: 'completed', label: 'Bajarilgan' },
  { key: 'cancelled', label: 'Bekor qilingan' },
];

export default function ServicePage() {
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const [catOpen, setCatOpen] = useState(false);
  const [detailId, setDetailId] = useState<string | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['service-summary'],
    queryFn: () => api.get('/service/summary').then((r) => r.data),
  });

  const ticketsQ = useQuery<{ items: Ticket[]; total: number }>({
    queryKey: ['service-tickets', status, search],
    queryFn: () => api.get('/service/tickets', {
      params: { status: status || undefined, search: search.trim() || undefined, page_size: 100 },
    }).then((r) => r.data),
  });

  const tickets = ticketsQ.data?.items ?? [];
  const s = summaryQ.data;

  const refetchAll = () => {
    ticketsQ.refetch();
    summaryQ.refetch();
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Servis xizmati</h1>
          <p className="text-sm text-ink-soft">Sotilgan mahsulotlarga kafolat va texnik xizmat</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-ghost" onClick={() => setCatOpen(true)}>
            <Tag size={16} /> Toifalar
          </button>
          <button className="btn-primary" onClick={() => setCreateOpen(true)}>
            <Plus size={16} /> Yangi ariza
          </button>
        </div>
      </div>

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <BalanceCard title="Ochiq arizalar" value={String((s?.new ?? 0) + (s?.scheduled ?? 0))}
                     icon={<ClipboardList size={18} />} accent="primary" />
        <BalanceCard title="Yangi" value={String(s?.new ?? 0)} icon={<Wrench size={18} />} accent="primary" />
        <BalanceCard title="Yaqin 7 kun (rejada)" value={String(s?.scheduled_next7 ?? 0)}
                     icon={<CalendarClock size={18} />} accent="warning" />
        <BalanceCard title="Kafolatdagi ochiq" value={String(s?.in_warranty_open ?? 0)}
                     icon={<ShieldCheck size={18} />} accent="success" />
      </div>

      {/* Filtrlar + qidiruv */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex flex-wrap gap-1.5">
          {FILTERS.map((f) => (
            <button key={f.key} onClick={() => setStatus(f.key)}
              className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                status === f.key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
              {f.label}
            </button>
          ))}
        </div>
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-56" placeholder="Kod yoki muammo…"
                 value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
      </div>

      <Card>
        {ticketsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : tickets.length === 0 ? (
          <EmptyState title="Servis arizalari yo'q"
                      description="“Yangi ariza” tugmasi orqali birinchi arizani qo'shing" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Kod</th>
                  <th className="py-2 pr-3">Mijoz</th>
                  <th className="py-2 pr-3">Muammo</th>
                  <th className="py-2 pr-3">Borish sanasi</th>
                  <th className="py-2 pr-3">Kafolat</th>
                  <th className="py-2 pr-3">Status</th>
                </tr>
              </thead>
              <tbody>
                {tickets.map((t) => (
                  <tr key={t.id} onClick={() => setDetailId(t.id)}
                      className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                    <td className="py-2 pr-3 font-medium whitespace-nowrap">{t.code}</td>
                    <td className="py-2 pr-3">
                      {t.customer ? (
                        <div>
                          <div className="font-medium">{t.customer.full_name}</div>
                          <div className="text-xs text-ink-soft">{formatPhone(t.customer.phone)}</div>
                        </div>
                      ) : <span className="text-ink-soft">—</span>}
                    </td>
                    <td className="py-2 pr-3 max-w-[260px] truncate">{t.problem}</td>
                    <td className="py-2 pr-3 whitespace-nowrap">
                      {t.scheduled_at ? formatDateTime(t.scheduled_at) : <span className="text-ink-soft">—</span>}
                    </td>
                    <td className="py-2 pr-3">
                      {t.in_warranty
                        ? <span className="badge bg-success/10 text-success">Kafolatda</span>
                        : <span className="badge bg-gray-100 text-gray-600">Yo'q</span>}
                    </td>
                    <td className="py-2 pr-3"><ServiceStatusBadge status={t.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {createOpen && (
        <ServiceTicketModal onClose={() => setCreateOpen(false)} onSaved={refetchAll} />
      )}
      {detailId && (
        <TicketDetailModal ticketId={detailId} onClose={() => setDetailId(null)} onChanged={refetchAll} />
      )}
      {catOpen && <ServiceCategoryModal onClose={() => setCatOpen(false)} />}
    </div>
  );
}
