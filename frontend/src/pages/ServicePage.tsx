import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Search, Wrench, CalendarClock, Tag, CheckCircle2 } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatPhone } from '@/lib/format';
import ServiceTicketModal from '@/features/service/ServiceTicketModal';
import TicketDetailModal from '@/features/service/TicketDetailModal';
import ServiceCategoryModal from '@/features/service/ServiceCategoryModal';
import ServicePartsModal from '@/features/service/ServicePartsModal';
import ServiceTripPanel from '@/features/service/ServiceTripPanel';
import ServiceTripsList from '@/features/service/ServiceTripsList';
import ServicePartsStats from '@/features/service/ServicePartsStats';
import ServiceMoneyStats from '@/features/service/ServiceMoneyStats';
import { ServiceStatusBadge } from '@/features/service/status';

interface Ticket {
  id: string; code: string; problem: string; status: string;
  in_warranty: boolean; opened_at: string;
  customer?: { full_name: string; phone: string } | null;
  order?: { code: string } | null;
}
interface Summary {
  total: number; new: number; scheduled: number;
  completed: number; cancelled: number; in_warranty_open: number;
  with_visit: number;
}

const FILTER_KEYS = ['', 'new', 'scheduled', 'completed', 'cancelled'] as const;

const SERVICE_FILTER_LABELS: Record<string, string> = {
  new: 'Yangi',
  scheduled: 'Rejalashtirilgan',
  completed: 'Bajarilgan',
  cancelled: 'Bekor qilingan',
};

// Ariza muddati — tushgan sanadan +7 kun (avtomatik)
function deadlineOf(openedAt: string): Date {
  const d = new Date(openedAt);
  d.setDate(d.getDate() + 7);
  return d;
}

export default function ServicePage() {
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const [catOpen, setCatOpen] = useState(false);
  const [partsOpen, setPartsOpen] = useState(false);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [tab, setTab] = useState<'tickets' | 'trips' | 'partsStats' | 'money'>('tickets');

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

  // Znachok bosilganda: rejalashtirilgan (scheduled) ↔ yangi (new) o'rtasida almashtiradi
  async function toggleScheduled(tk: Ticket) {
    const next = tk.status === 'scheduled' ? 'new' : 'scheduled';
    try {
      await api.patch(`/service/tickets/${tk.id}`, { status: next });
      refetchAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    }
  }

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
          <button className="btn-ghost" onClick={() => setPartsOpen(true)}>
            <Wrench size={16} /> Ehtiyot qismlar
          </button>
          <button className="btn-primary" onClick={() => setCreateOpen(true)}>
            <Plus size={16} /> Yangi ariza
          </button>
        </div>
      </div>

      {/* Ichki bo'limlar: Arizalar / Servis safarlari */}
      <div className="flex gap-1 border-b border-black/5">
        {([['tickets', 'Arizalar'], ['trips', 'Servis safarlari'], ['partsStats', 'Sarflangan qismlar'], ['money', 'Sarflangan mablag']] as const).map(([key, label]) => (
          <button key={key} onClick={() => setTab(key)}
            className={'px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors ' +
              (tab === key ? 'border-primary text-primary' : 'border-transparent text-ink-soft hover:text-ink')}>
            {label}
          </button>
        ))}
      </div>

      {tab === 'trips' ? (
        <ServiceTripsList />
      ) : tab === 'partsStats' ? (
        <ServicePartsStats />
      ) : tab === 'money' ? (
        <ServiceMoneyStats />
      ) : (
      <>
      {/* KPI — 3 ta karta */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {/* Servis muammolari (ochiq) — qizil */}
        <div className="rounded-card border border-danger/25 bg-danger/10 p-4 flex items-start justify-between">
          <div>
            <div className="text-sm font-medium text-danger/90">Servis muammolari</div>
            <div className="text-2xl font-bold mt-2 text-danger">{(s?.new ?? 0) + (s?.scheduled ?? 0)}</div>
          </div>
          <div className="w-10 h-10 rounded-button bg-danger/20 text-danger flex items-center justify-center shrink-0"><Wrench size={18} /></div>
        </div>
        {/* Bartaraf etilgan — yashil */}
        <div className="rounded-card border border-success/25 bg-success/10 p-4 flex items-start justify-between">
          <div>
            <div className="text-sm font-medium text-success/90">Bartaraf etilgan</div>
            <div className="text-2xl font-bold mt-2 text-success">{s?.completed ?? 0}</div>
          </div>
          <div className="w-10 h-10 rounded-button bg-success/20 text-success flex items-center justify-center shrink-0"><CheckCircle2 size={18} /></div>
        </div>
        {/* Rejalashtirilgan (✅ znachok soni) — primary */}
        <div className="rounded-card border border-primary/25 bg-primary/10 p-4 flex items-start justify-between">
          <div>
            <div className="text-sm font-medium text-primary/90">Rejalashtirilgan</div>
            <div className="text-2xl font-bold mt-2 text-primary">{s?.with_visit ?? 0}</div>
          </div>
          <div className="w-10 h-10 rounded-button bg-primary/20 text-primary flex items-center justify-center shrink-0"><CalendarClock size={18} /></div>
        </div>
      </div>

      {/* Filtrlar + qidiruv */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex flex-wrap gap-1.5">
          {FILTER_KEYS.map((key) => (
            <button key={key} onClick={() => setStatus(key)}
              className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                status === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
              {key === '' ? 'Hammasi' : SERVICE_FILTER_LABELS[key]}
            </button>
          ))}
        </div>
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-56" placeholder="Kod yoki muammo…"
                 value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
      </div>

      {/* Servis safari — faqat "Rejalashtirilgan" filtrida */}
      {status === 'scheduled' && <ServiceTripPanel onChanged={refetchAll} />}

      <Card>
        {ticketsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : tickets.length === 0 ? (
          <EmptyState title="Servis arizalari yo'q"
                      description={`"Yangi ariza" tugmasi orqali birinchi arizani qo'shing`} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3 w-10"></th>
                  <th className="py-2 pr-3">Mijoz</th>
                  <th className="py-2 pr-3">Muammo</th>
                  <th className="py-2 pr-3">Tushgan sana</th>
                  <th className="py-2 pr-3">Muddat</th>
                  <th className="py-2 pr-3">Kafolat</th>
                  <th className="py-2 pr-3">Status</th>
                </tr>
              </thead>
              <tbody>
                {tickets.map((tk) => (
                  <tr key={tk.id} onClick={() => setDetailId(tk.id)}
                      className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                    <td className="py-2 pr-3 text-center" onClick={(e) => e.stopPropagation()}>
                      {tk.status === 'new' || tk.status === 'scheduled' ? (
                        <button onClick={() => toggleScheduled(tk)}
                                title="Rejalashtirilgan"
                                className={'inline-flex transition-colors ' + (tk.status === 'scheduled'
                                  ? 'text-success'
                                  : 'text-danger/70 hover:text-danger')}>
                          <CheckCircle2 size={22} strokeWidth={2.5} />
                        </button>
                      ) : null}
                    </td>
                    <td className="py-2 pr-3">
                      {tk.customer ? (
                        <div>
                          <div className="font-medium">{tk.customer.full_name}</div>
                          <div className="text-xs text-ink-soft">{formatPhone(tk.customer.phone)}</div>
                        </div>
                      ) : <span className="text-ink-soft">—</span>}
                    </td>
                    <td className="py-2 pr-3 max-w-[260px] truncate">{tk.problem}</td>
                    <td className="py-2 pr-3 whitespace-nowrap">{formatDate(tk.opened_at)}</td>
                    <td className="py-2 pr-3 whitespace-nowrap">{formatDate(deadlineOf(tk.opened_at))}</td>
                    <td className="py-2 pr-3">
                      {tk.in_warranty
                        ? <span className="badge bg-success/10 text-success">Kafolatda</span>
                        : <span className="badge bg-gray-100 text-gray-600">Yo'q</span>}
                    </td>
                    <td className="py-2 pr-3"><ServiceStatusBadge status={tk.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      </>
      )}

      {createOpen && (
        <ServiceTicketModal onClose={() => setCreateOpen(false)} onSaved={refetchAll} />
      )}
      {detailId && (
        <TicketDetailModal ticketId={detailId} onClose={() => setDetailId(null)} onChanged={refetchAll} />
      )}
      {catOpen && <ServiceCategoryModal onClose={() => setCatOpen(false)} />}
      {partsOpen && <ServicePartsModal onClose={() => setPartsOpen(false)} />}
    </div>
  );
}
