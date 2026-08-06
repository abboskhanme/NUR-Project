import { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Search, Sparkles, Flame, TrendingUp, CalendarPlus, Instagram, MessageCircle, Phone,
} from 'lucide-react';

import EmptyState from '@/components/ui/EmptyState';
import { cn } from '@/lib/cn';
import { formatDate, formatPhone } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import {
  leadsApi, LEAD_STATUS_LABELS, LEAD_STATUS_ORDER,
  type Lead, type LeadStatus,
} from '@/features/leads/api';
import { ScoreBadge } from '@/features/leads/LeadBadges';

// Ustun rang mavzusi — har status sezilarli darajada ajralib tursin
interface ColTheme { header: string; body: string; border: string; dot: string; count: string; ring: string; }
const COL_THEME: Record<LeadStatus, ColTheme> = {
  new: {
    header: 'bg-blue-100 text-blue-800', body: 'bg-blue-50/60', border: 'border-blue-200',
    dot: 'bg-blue-500', count: 'bg-blue-200/70 text-blue-800', ring: 'ring-blue-400',
  },
  contacted: {
    header: 'bg-amber-100 text-amber-800', body: 'bg-amber-50/60', border: 'border-amber-200',
    dot: 'bg-amber-500', count: 'bg-amber-200/70 text-amber-800', ring: 'ring-amber-400',
  },
  qualified: {
    header: 'bg-violet-100 text-violet-800', body: 'bg-violet-50/60', border: 'border-violet-200',
    dot: 'bg-violet-500', count: 'bg-violet-200/70 text-violet-800', ring: 'ring-violet-400',
  },
  won: {
    header: 'bg-emerald-100 text-emerald-800', body: 'bg-emerald-50/60', border: 'border-emerald-200',
    dot: 'bg-emerald-500', count: 'bg-emerald-200/70 text-emerald-800', ring: 'ring-emerald-400',
  },
  lost: {
    header: 'bg-slate-200 text-slate-700', body: 'bg-slate-100/70', border: 'border-slate-300',
    dot: 'bg-slate-400', count: 'bg-slate-300/70 text-slate-700', ring: 'ring-slate-400',
  },
};

export default function LeadsPage() {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('leads:write');

  const [search, setSearch] = useState('');
  const [overCol, setOverCol] = useState<LeadStatus | null>(null);
  const dragging = useRef<{ id: string; status: LeadStatus } | null>(null);

  const analyticsQ = useQuery({
    queryKey: ['leads-analytics'],
    queryFn: leadsApi.analytics,
  });

  const leadsQ = useQuery({
    queryKey: ['leads', 'board', search],
    queryFn: () => leadsApi.list({ status: 'all', search: search.trim() || undefined }),
  });
  const leads = leadsQ.data ?? [];
  const a = analyticsQ.data;

  // Statusni o'zgartirish — optimistik (karta darrov ustunni almashtiradi)
  const move = useMutation({
    mutationFn: ({ id, status }: { id: string; status: LeadStatus }) =>
      leadsApi.update(id, { status }),
    onMutate: async ({ id, status }) => {
      await qc.cancelQueries({ queryKey: ['leads'] });
      const prev = qc.getQueriesData<Lead[]>({ queryKey: ['leads'] });
      qc.setQueriesData<Lead[]>({ queryKey: ['leads'] }, (old) =>
        old?.map((l) => (l.id === id ? { ...l, status } : l)));
      return { prev };
    },
    onError: (_e, _v, ctx) => {
      ctx?.prev?.forEach(([key, data]) => qc.setQueryData(key, data));
      toast.error("Statusni o'zgartirib bo'lmadi");
    },
    onSettled: () => {
      qc.invalidateQueries({ queryKey: ['leads'] });
      qc.invalidateQueries({ queryKey: ['leads-analytics'] });
    },
  });

  // Statusga ko'ra guruhlash
  const byStatus: Record<LeadStatus, Lead[]> = {
    new: [], contacted: [], qualified: [], won: [], lost: [],
  };
  for (const l of leads) (byStatus[l.status] ?? byStatus.new).push(l);

  function handleDrop(status: LeadStatus) {
    const d = dragging.current;
    dragging.current = null;
    setOverCol(null);
    if (d && d.status !== status) move.mutate({ id: d.id, status });
  }

  return (
    <div className="space-y-4">
      {/* Sarlavha */}
      <div>
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Sparkles size={22} className="text-primary" /> Leadlar
        </h1>
        <p className="text-sm text-ink-soft">Instagram AI agenti topgan potentsial mijozlar</p>
      </div>

      {/* KPI kartalari */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <KpiCard tone="primary" label="Jami leadlar" value={a?.total ?? 0}
                 icon={<Sparkles size={18} />} />
        <KpiCard tone="info" label="Bugun yangi" value={a?.new_today ?? 0}
                 icon={<CalendarPlus size={18} />} />
        <KpiCard tone="danger" label="Issiq leadlar" value={a?.hot_leads ?? 0}
                 hint="Ball ≥ 70" icon={<Flame size={18} />} />
        <KpiCard tone="success" label="Konversiya" value={`${a?.conversion_rate ?? 0}%`}
                 hint={`O'rtacha ball: ${a?.avg_score ?? 0}`} icon={<TrendingUp size={18} />} />
      </div>

      {/* Qidiruv */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-60" placeholder="Ism, username, mahsulot..."
                 value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        {canWrite && (
          <span className="text-xs text-ink-soft">
            Kartani ustundan ustunga sudrab statusini o'zgartiring
          </span>
        )}
      </div>

      {/* Kanban doska */}
      {leadsQ.isLoading ? (
        <div className="flex gap-3 overflow-x-auto pb-2">
          {LEAD_STATUS_ORDER.map((st) => (
            <div key={st} className="min-w-[240px] flex-1 space-y-2">
              <div className="h-9 rounded-button bg-black/5 animate-pulse" />
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-20 rounded-card bg-black/5 animate-pulse" />
              ))}
            </div>
          ))}
        </div>
      ) : leads.length === 0 ? (
        <EmptyState
          title={search ? 'Lead topilmadi' : "Hali lead yo'q"}
          description={search
            ? "Qidiruvni o'zgartirib ko'ring"
            : "Instagram agenti ishga tushgach, leadlar shu yerda paydo bo'ladi"}
        />
      ) : (
        <div className="flex gap-3 overflow-x-auto pb-2">
          {LEAD_STATUS_ORDER.map((st) => (
            <KanbanColumn
              key={st}
              status={st}
              leads={byStatus[st]}
              isOver={overCol === st}
              canWrite={canWrite}
              onCardClick={(id) => navigate(`/leads/${id}`)}
              onCardDragStart={(lead) => { dragging.current = { id: lead.id, status: lead.status }; }}
              onColDragOver={() => canWrite && setOverCol(st)}
              onColDragLeave={() => setOverCol((c) => (c === st ? null : c))}
              onColDrop={() => handleDrop(st)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
function KanbanColumn({
  status, leads, isOver, canWrite,
  onCardClick, onCardDragStart, onColDragOver, onColDragLeave, onColDrop,
}: {
  status: LeadStatus;
  leads: Lead[];
  isOver: boolean;
  canWrite: boolean;
  onCardClick: (id: string) => void;
  onCardDragStart: (lead: Lead) => void;
  onColDragOver: () => void;
  onColDragLeave: () => void;
  onColDrop: () => void;
}) {
  const t = COL_THEME[status];
  return (
    <div
      className={cn('min-w-[240px] flex-1 flex flex-col rounded-card border overflow-hidden shadow-sm transition',
                    t.border, isOver && cn('ring-2 ring-inset', t.ring))}
      onDragOver={canWrite ? (e) => { e.preventDefault(); onColDragOver(); } : undefined}
      onDragLeave={canWrite ? onColDragLeave : undefined}
      onDrop={canWrite ? (e) => { e.preventDefault(); onColDrop(); } : undefined}
    >
      {/* Ustun sarlavhasi — rangli */}
      <div className={cn('px-3 py-2.5 flex items-center justify-between', t.header)}>
        <span className="font-bold text-sm flex items-center gap-2">
          <span className={cn('w-2.5 h-2.5 rounded-full ring-2 ring-white/60', t.dot)} />
          {LEAD_STATUS_LABELS[status]}
        </span>
        <span className={cn('text-xs font-bold rounded-full px-2 py-0.5 min-w-[22px] text-center', t.count)}>
          {leads.length}
        </span>
      </div>

      {/* Kartalar ro'yxati — ustunning yengil rangli foni */}
      <div className={cn(
        'flex-1 p-2 space-y-2 min-h-[120px] max-h-[70vh] overflow-y-auto transition',
        isOver ? 'bg-primary/5' : t.body,
      )}>
        {leads.length === 0 ? (
          <div className="text-xs text-ink-soft/70 text-center py-6">Bo'sh</div>
        ) : (
          leads.map((l) => (
            <LeadCard
              key={l.id}
              lead={l}
              canWrite={canWrite}
              onClick={() => onCardClick(l.id)}
              onDragStart={() => onCardDragStart(l)}
            />
          ))
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
function LeadCard({
  lead, canWrite, onClick, onDragStart,
}: {
  lead: Lead;
  canWrite: boolean;
  onClick: () => void;
  onDragStart: () => void;
}) {
  const displayName = lead.name || lead.ig_username || "Noma'lum";
  return (
    <div
      draggable={canWrite}
      onDragStart={canWrite ? (e) => { e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('text/plain', lead.id); onDragStart(); } : undefined}
      onClick={onClick}
      className={cn(
        'rounded-card border border-black/5 bg-card p-2.5 shadow-sm hover:shadow transition select-none',
        canWrite ? 'cursor-grab active:cursor-grabbing' : 'cursor-pointer',
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <div className="w-7 h-7 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
            <Instagram size={13} />
          </div>
          <div className="min-w-0">
            <div className="font-medium text-sm truncate">{displayName}</div>
            {lead.ig_username && (
              <div className="text-xs text-ink-soft truncate">@{lead.ig_username}</div>
            )}
          </div>
        </div>
        <ScoreBadge score={lead.lead_score} className="shrink-0" />
      </div>

      {/* Telefon raqami — asosiy ma'lumot */}
      {lead.contact ? (
        <div className="mt-2 flex items-center gap-1.5 text-sm font-semibold text-ink tabular-nums">
          <Phone size={13} className="text-primary shrink-0" />
          <span className="truncate">{formatPhone(lead.contact)}</span>
        </div>
      ) : (
        <div className="mt-2 text-xs text-ink-soft/60">Raqam kiritilmagan</div>
      )}

      <div className="mt-2 flex items-center justify-between text-xs text-ink-soft">
        {lead.event_count > 0 ? (
          <span className="inline-flex items-center gap-0.5">
            <MessageCircle size={11} /> {lead.event_count}
          </span>
        ) : <span />}
        <span className="whitespace-nowrap">{formatDate(lead.created_at)}</span>
      </div>

      {lead.assigned_to_name && (
        <div className="mt-1.5 text-xs text-ink-soft truncate">👤 {lead.assigned_to_name}</div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
const KPI_TONES = {
  primary: { card: 'border-primary/20 bg-primary/5', text: 'text-primary', icon: 'bg-primary/15 text-primary' },
  info: { card: 'border-blue-500/20 bg-blue-500/5', text: 'text-blue-600', icon: 'bg-blue-500/15 text-blue-600' },
  danger: { card: 'border-red-500/20 bg-red-500/5', text: 'text-red-600', icon: 'bg-red-500/15 text-red-600' },
  success: { card: 'border-success/25 bg-success/10', text: 'text-success', icon: 'bg-success/20 text-success' },
} as const;

function KpiCard({ tone, label, value, hint, icon }: {
  tone: keyof typeof KPI_TONES;
  label: string;
  value: string | number;
  hint?: string;
  icon: React.ReactNode;
}) {
  const tn = KPI_TONES[tone];
  return (
    <div className={`rounded-card border p-4 flex items-start justify-between ${tn.card}`}>
      <div className="min-w-0">
        <div className={`text-xs font-medium ${tn.text}`}>{label}</div>
        <div className={`text-2xl font-bold mt-1.5 ${tn.text}`}>{value}</div>
        {hint && <div className="text-xs text-ink-soft mt-1">{hint}</div>}
      </div>
      <div className={`w-9 h-9 rounded-button flex items-center justify-center shrink-0 ${tn.icon}`}>
        {icon}
      </div>
    </div>
  );
}
