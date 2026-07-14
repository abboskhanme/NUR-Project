import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Search, Sparkles, Flame, TrendingUp, CalendarPlus, Instagram, MessageCircle,
} from 'lucide-react';

import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate } from '@/lib/format';
import {
  leadsApi, LEAD_STATUS_LABELS, LEAD_STATUS_ORDER, LANG_LABELS,
  type Lead, type LeadStatus,
} from '@/features/leads/api';
import { LeadStatusBadge, ScoreBadge } from '@/features/leads/LeadBadges';

type Tab = 'all' | LeadStatus;

export default function LeadsPage() {
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>('all');
  const [search, setSearch] = useState('');

  const analyticsQ = useQuery({
    queryKey: ['leads-analytics'],
    queryFn: leadsApi.analytics,
  });

  const leadsQ = useQuery({
    queryKey: ['leads', tab, search],
    queryFn: () => leadsApi.list({ status: tab, search: search.trim() || undefined }),
  });
  const leads = leadsQ.data ?? [];
  const a = analyticsQ.data;

  // Har status bo'yicha son (tab yorliqlarida ko'rsatish uchun)
  const statusCount: Record<string, number> = {};
  a?.by_status.forEach((s) => { statusCount[s.status] = s.count; });

  return (
    <div className="space-y-4">
      {/* Sarlavha */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <Sparkles size={22} className="text-primary" /> Leadlar
          </h1>
          <p className="text-sm text-ink-soft">Instagram AI agenti topgan potentsial mijozlar</p>
        </div>
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

      {/* Tab + qidiruv */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex gap-1.5 flex-wrap">
          <TabButton active={tab === 'all'} onClick={() => setTab('all')}
                     label="Barchasi" count={a?.total} />
          {LEAD_STATUS_ORDER.map((st) => (
            <TabButton key={st} active={tab === st} onClick={() => setTab(st)}
                       label={LEAD_STATUS_LABELS[st]} count={statusCount[st]} />
          ))}
        </div>
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-60" placeholder="Ism, username, mahsulot..."
                 value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
      </div>

      {/* Jadval */}
      <Card>
        {leadsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : leads.length === 0 ? (
          <EmptyState
            title={search || tab !== 'all' ? 'Lead topilmadi' : "Hali lead yo'q"}
            description={search || tab !== 'all'
              ? "Qidiruv yoki filtrni o'zgartirib ko'ring"
              : 'Instagram agenti ishga tushgach, leadlar shu yerda paydo bo\'ladi'}
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2.5 pr-3 font-medium">Mijoz</th>
                  <th className="py-2.5 px-3 font-medium">Qiziqish</th>
                  <th className="py-2.5 px-3 font-medium">Ball</th>
                  <th className="py-2.5 px-3 font-medium">Status</th>
                  <th className="py-2.5 px-3 font-medium">Mas'ul</th>
                  <th className="py-2.5 pl-3 font-medium text-right">Sana</th>
                </tr>
              </thead>
              <tbody>
                {leads.map((l) => (
                  <LeadRow key={l.id} lead={l} onClick={() => navigate(`/leads/${l.id}`)} />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}

// ---------------------------------------------------------------------------
function LeadRow({ lead, onClick }: { lead: Lead; onClick: () => void }) {
  const displayName = lead.name || lead.ig_username || 'Noma\'lum';
  return (
    <tr onClick={onClick}
        className="border-b border-black/5 last:border-0 hover:bg-black/[0.02] cursor-pointer transition">
      <td className="py-3 pr-3">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
            <Instagram size={15} />
          </div>
          <div className="min-w-0">
            <div className="font-medium truncate">{displayName}</div>
            <div className="text-xs text-ink-soft truncate flex items-center gap-1">
              {lead.ig_username ? `@${lead.ig_username}` : (lead.contact || '—')}
              {lead.event_count > 0 && (
                <span className="inline-flex items-center gap-0.5 ml-1">
                  <MessageCircle size={11} /> {lead.event_count}
                </span>
              )}
            </div>
          </div>
        </div>
      </td>
      <td className="py-3 px-3">
        <div className="truncate max-w-[180px]">{lead.product_interest || '—'}</div>
        {lead.language && (
          <div className="text-xs text-ink-soft">{LANG_LABELS[lead.language] ?? lead.language}</div>
        )}
      </td>
      <td className="py-3 px-3"><ScoreBadge score={lead.lead_score} /></td>
      <td className="py-3 px-3"><LeadStatusBadge status={lead.status} /></td>
      <td className="py-3 px-3 text-ink-soft">{lead.assigned_to_name || '—'}</td>
      <td className="py-3 pl-3 text-right text-ink-soft whitespace-nowrap">
        {formatDate(lead.created_at)}
      </td>
    </tr>
  );
}

// ---------------------------------------------------------------------------
function TabButton({ active, onClick, label, count }: {
  active: boolean; onClick: () => void; label: string; count?: number;
}) {
  return (
    <button onClick={onClick}
      className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
        active ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
      {label}
      {count != null && count > 0 && (
        <span className={`ml-1.5 text-xs ${active ? 'opacity-80' : 'opacity-60'}`}>{count}</span>
      )}
    </button>
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
