import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Plus, Search, Wrench, CalendarClock, ShieldCheck, ClipboardList, Tag, List, CalendarDays } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import BalanceCard from '@/components/ui/BalanceCard';
import { formatDateTime, formatPhone } from '@/lib/format';
import ServiceTicketModal from '@/features/service/ServiceTicketModal';
import TicketDetailModal from '@/features/service/TicketDetailModal';
import ServiceCategoryModal from '@/features/service/ServiceCategoryModal';
import ServiceCalendar from '@/features/service/ServiceCalendar';
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

const FILTER_KEYS = ['', 'new', 'scheduled', 'completed', 'cancelled'] as const;

export default function ServicePage() {
  const { t } = useTranslation();
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const [catOpen, setCatOpen] = useState(false);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [view, setView] = useState<'list' | 'calendar'>('list');

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
          <h1 className="text-2xl font-bold">{t('service.title')}</h1>
          <p className="text-sm text-ink-soft">{t('service.subtitle')}</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-ghost" onClick={() => setCatOpen(true)}>
            <Tag size={16} /> {t('service.categories')}
          </button>
          <button className="btn-primary" onClick={() => setCreateOpen(true)}>
            <Plus size={16} /> {t('service.newTicket')}
          </button>
        </div>
      </div>

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <BalanceCard title={t('service.kpi.open')} value={String((s?.new ?? 0) + (s?.scheduled ?? 0))}
                     icon={<ClipboardList size={18} />} accent="primary" />
        <BalanceCard title={t('service.kpi.new')} value={String(s?.new ?? 0)} icon={<Wrench size={18} />} accent="primary" />
        <BalanceCard title={t('service.kpi.scheduledNext7')} value={String(s?.scheduled_next7 ?? 0)}
                     icon={<CalendarClock size={18} />} accent="warning" />
        <BalanceCard title={t('service.kpi.warrantyOpen')} value={String(s?.in_warranty_open ?? 0)}
                     icon={<ShieldCheck size={18} />} accent="success" />
      </div>

      {/* Filtrlar + qidiruv */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex flex-wrap gap-1.5">
          {FILTER_KEYS.map((key) => (
            <button key={key} onClick={() => setStatus(key)}
              className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                status === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
              {key === '' ? t('service.filter.all') : t(`service.filter.${key}`)}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          {/* Ko'rinish almashtirgich — standart "ro'yxat" (mavjud ko'rinish o'zgarmaydi) */}
          <div className="flex rounded-button border border-black/10 overflow-hidden">
            <button onClick={() => setView('list')} title={t('service.view.list')}
                    className={`p-2 ${view === 'list' ? 'bg-primary text-white' : 'text-ink-soft hover:bg-black/5'}`}>
              <List size={16} />
            </button>
            <button onClick={() => setView('calendar')} title={t('service.view.calendar')}
                    className={`p-2 ${view === 'calendar' ? 'bg-primary text-white' : 'text-ink-soft hover:bg-black/5'}`}>
              <CalendarDays size={16} />
            </button>
          </div>
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 w-56" placeholder={t('service.search.placeholder')}
                   value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>
      </div>

      {view === 'calendar' ? (
        <ServiceCalendar onSelect={setDetailId} />
      ) : (
      <Card>
        {ticketsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : tickets.length === 0 ? (
          <EmptyState title={t('service.empty.title')}
                      description={t('service.empty.description')} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">{t('service.table.code')}</th>
                  <th className="py-2 pr-3">{t('service.table.customer')}</th>
                  <th className="py-2 pr-3">{t('service.table.problem')}</th>
                  <th className="py-2 pr-3">{t('service.table.visitDate')}</th>
                  <th className="py-2 pr-3">{t('service.table.warranty')}</th>
                  <th className="py-2 pr-3">{t('service.table.status')}</th>
                </tr>
              </thead>
              <tbody>
                {tickets.map((tk) => (
                  <tr key={tk.id} onClick={() => setDetailId(tk.id)}
                      className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                    <td className="py-2 pr-3 font-medium whitespace-nowrap">{tk.code}</td>
                    <td className="py-2 pr-3">
                      {tk.customer ? (
                        <div>
                          <div className="font-medium">{tk.customer.full_name}</div>
                          <div className="text-xs text-ink-soft">{formatPhone(tk.customer.phone)}</div>
                        </div>
                      ) : <span className="text-ink-soft">—</span>}
                    </td>
                    <td className="py-2 pr-3 max-w-[260px] truncate">{tk.problem}</td>
                    <td className="py-2 pr-3 whitespace-nowrap">
                      {tk.scheduled_at ? formatDateTime(tk.scheduled_at) : <span className="text-ink-soft">—</span>}
                    </td>
                    <td className="py-2 pr-3">
                      {tk.in_warranty
                        ? <span className="badge bg-success/10 text-success">{t('service.warranty.inWarranty')}</span>
                        : <span className="badge bg-gray-100 text-gray-600">{t('service.warranty.noWarranty')}</span>}
                    </td>
                    <td className="py-2 pr-3"><ServiceStatusBadge status={tk.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      )}

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
