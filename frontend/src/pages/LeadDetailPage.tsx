import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  ArrowLeft, Instagram, Phone, Package, Languages, Trash2, UserPlus,
  ExternalLink, Bot, MessageSquare, Save, CheckCircle2,
} from 'lucide-react';

import Card from '@/components/ui/Card';
import Select from '@/components/ui/Select';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatDateTime } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import {
  leadsApi, LEAD_STATUS_LABELS, LEAD_STATUS_ORDER, LANG_LABELS, INTENT_LABELS,
  type LeadDetail, type LeadStatus,
} from '@/features/leads/api';
import { LeadStatusBadge, ScoreBadge } from '@/features/leads/LeadBadges';
import ConvertModal from '@/features/leads/ConvertModal';

export default function LeadDetailPage() {
  const { leadId } = useParams<{ leadId: string }>();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('leads:write');
  const canDelete = can('leads:delete');

  const [note, setNote] = useState('');
  const [savingNote, setSavingNote] = useState(false);
  const [showConvert, setShowConvert] = useState(false);
  const [showDelete, setShowDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const leadQ = useQuery<LeadDetail>({
    queryKey: ['lead', leadId],
    queryFn: () => leadsApi.get(leadId!),
    enabled: !!leadId,
  });
  const assigneesQ = useQuery({
    queryKey: ['leads-assignees'],
    queryFn: leadsApi.assignees,
    enabled: canWrite,
  });

  const lead = leadQ.data;
  useEffect(() => { if (lead) setNote(lead.note || ''); }, [lead?.id]); // eslint-disable-line

  function refresh() {
    qc.invalidateQueries({ queryKey: ['lead', leadId] });
    qc.invalidateQueries({ queryKey: ['leads'] });
    qc.invalidateQueries({ queryKey: ['leads-analytics'] });
  }

  async function patch(body: Parameters<typeof leadsApi.update>[1], msg = 'Saqlandi') {
    if (!leadId) return;
    try {
      await leadsApi.update(leadId, body);
      toast.success(msg);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    }
  }

  async function saveNote() {
    setSavingNote(true);
    await patch({ note }, 'Izoh saqlandi');
    setSavingNote(false);
  }

  async function confirmDelete() {
    if (!leadId) return;
    setDeleting(true);
    try {
      await leadsApi.remove(leadId);
      toast.success("O'chirildi");
      qc.invalidateQueries({ queryKey: ['leads'] });
      navigate('/leads');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
      setDeleting(false);
    }
  }

  if (leadQ.isLoading || !lead) {
    return (
      <div className="space-y-4">
        <div className="h-6 w-32 rounded bg-black/5 animate-pulse" />
        <div className="h-40 rounded-lg bg-black/5 animate-pulse" />
      </div>
    );
  }

  const displayName = lead.name || lead.ig_username || 'Noma\'lum lead';
  const igLink = lead.ig_username ? `https://instagram.com/${lead.ig_username}` : null;

  return (
    <div className="space-y-4">
      <button onClick={() => navigate('/leads')}
              className="flex items-center gap-1.5 text-sm text-ink-soft hover:text-ink">
        <ArrowLeft size={16} /> Leadlarga qaytish
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Chap: lead ma'lumoti + suhbat */}
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <div className="flex items-start gap-3">
              <div className="w-12 h-12 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
                <Instagram size={22} />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 flex-wrap">
                  <h1 className="text-xl font-bold truncate">{displayName}</h1>
                  <ScoreBadge score={lead.lead_score} />
                  <LeadStatusBadge status={lead.status} />
                </div>
                <div className="text-sm text-ink-soft mt-0.5 flex items-center gap-2 flex-wrap">
                  {igLink ? (
                    <a href={igLink} target="_blank" rel="noreferrer"
                       className="inline-flex items-center gap-1 text-primary hover:underline">
                      @{lead.ig_username} <ExternalLink size={12} />
                    </a>
                  ) : <span>@—</span>}
                  <span>·</span>
                  <span>{formatDateTime(lead.created_at)}</span>
                </div>
              </div>
            </div>

            {/* Xususiyatlar */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mt-4">
              <InfoTile icon={<Phone size={15} />} label="Kontakt" value={lead.contact || '—'} />
              <InfoTile icon={<Package size={15} />} label="Qiziqish" value={lead.product_interest || '—'} />
              <InfoTile icon={<Languages size={15} />} label="Til"
                        value={lead.language ? (LANG_LABELS[lead.language] ?? lead.language) : '—'} />
              <InfoTile icon={<MessageSquare size={15} />} label="Maqsad"
                        value={lead.intent ? (INTENT_LABELS[lead.intent] ?? lead.intent) : '—'} />
            </div>

            {lead.summary && (
              <div className="mt-4 rounded-button bg-black/[0.03] border border-black/5 p-3">
                <div className="text-xs font-medium text-ink-soft mb-1 flex items-center gap-1.5">
                  <Bot size={13} /> AI xulosasi
                </div>
                <p className="text-sm">{lead.summary}</p>
              </div>
            )}
          </Card>

          {/* Suhbat tarixi */}
          <Card>
            <h3 className="font-semibold mb-3 flex items-center gap-2">
              <MessageSquare size={16} className="text-primary" /> Suhbat tarixi
            </h3>
            {lead.events.length === 0 ? (
              <p className="text-sm text-ink-soft py-4 text-center">Hozircha hodisa yo'q</p>
            ) : (
              <div className="space-y-3">
                {lead.events.map((ev) => {
                  if (ev.kind === 'status') {
                    return (
                      <div key={ev.id} className="flex items-center gap-2 justify-center text-xs text-ink-soft">
                        <CheckCircle2 size={13} />
                        <span>Status o'zgardi · {formatDateTime(ev.created_at)}</span>
                      </div>
                    );
                  }
                  return (
                    <div key={ev.id} className="space-y-2">
                      {ev.message_text && (
                        <Bubble side="left" title={lead.ig_username ? `@${lead.ig_username}` : 'Mijoz'}
                                text={ev.message_text} at={ev.created_at} />
                      )}
                      {ev.agent_reply && (
                        <Bubble side="right" title="AI agent" text={ev.agent_reply} at={ev.created_at} />
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </Card>
        </div>

        {/* O'ng: amallar */}
        <div className="space-y-4">
          <Card>
            <h3 className="font-semibold mb-3">Boshqaruv</h3>
            <div className="space-y-3">
              <div>
                <label className="label">Holat</label>
                <Select
                  value={lead.status}
                  onChange={(v) => canWrite && patch({ status: v as LeadStatus }, 'Holat yangilandi')}
                  disabled={!canWrite}
                  options={LEAD_STATUS_ORDER.map((st) => ({ value: st, label: LEAD_STATUS_LABELS[st] }))}
                />
              </div>
              <div>
                <label className="label">Mas'ul xodim</label>
                <Select
                  value={lead.assigned_to_id || ''}
                  onChange={(v) => patch({ assigned_to_id: (v || null) as any }, 'Mas\'ul yangilandi')}
                  disabled={!canWrite}
                  allowEmpty
                  emptyLabel="Biriktirilmagan"
                  placeholder="Biriktirilmagan"
                  options={(assigneesQ.data ?? []).map((u) => ({ value: u.id, label: u.full_name }))}
                />
              </div>
              <div>
                <label className="label">Izoh</label>
                <textarea className="input min-h-[80px] resize-y" value={note}
                          disabled={!canWrite}
                          onChange={(e) => setNote(e.target.value)}
                          placeholder="Ichki eslatma..." />
                {canWrite && (
                  <button onClick={saveNote} disabled={savingNote || note === (lead.note || '')}
                          className="btn-ghost w-full mt-2 border border-black/10 disabled:opacity-50">
                    <Save size={15} /> {savingNote ? '...' : 'Izohni saqlash'}
                  </button>
                )}
              </div>
            </div>
          </Card>

          {/* Konversiya */}
          <Card>
            {lead.customer_id ? (
              <button onClick={() => navigate(`/customers/${lead.customer_id}`)}
                      className="w-full inline-flex items-center justify-center gap-2 px-3 py-2.5 rounded-button text-sm font-medium bg-success/10 text-success hover:bg-success/20 transition">
                <CheckCircle2 size={16} /> Mijoz kartasini ochish
              </button>
            ) : (
              <button onClick={() => setShowConvert(true)} disabled={!canWrite}
                      className="w-full inline-flex items-center justify-center gap-2 px-3 py-2.5 rounded-button text-sm font-medium bg-primary/10 text-primary hover:bg-primary/20 transition disabled:opacity-50">
                <UserPlus size={16} /> Mijozga aylantirish
              </button>
            )}
            {canDelete && (
              <button onClick={() => setShowDelete(true)}
                      className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-button text-sm font-medium text-danger hover:bg-danger/10 transition mt-2">
                <Trash2 size={15} /> Lead'ni o'chirish
              </button>
            )}
          </Card>
        </div>
      </div>

      {showConvert && (
        <ConvertModal lead={lead} onClose={() => setShowConvert(false)} onDone={() => refresh()} />
      )}
      <ConfirmModal
        open={showDelete}
        title={displayName}
        message="Ushbu lead va uning suhbat tarixi butunlay o'chiriladi. Davom etamizmi?"
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setShowDelete(false)}
      />
    </div>
  );
}

// ---------------------------------------------------------------------------
function InfoTile({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="rounded-button bg-black/[0.03] border border-black/5 p-2.5">
      <div className="text-xs text-ink-soft flex items-center gap-1.5">{icon} {label}</div>
      <div className="text-sm font-medium mt-1 truncate" title={value}>{value}</div>
    </div>
  );
}

function Bubble({ side, title, text, at }: {
  side: 'left' | 'right'; title: string; text: string; at: string;
}) {
  const right = side === 'right';
  return (
    <div className={`flex ${right ? 'justify-end' : 'justify-start'}`}>
      <div className={`max-w-[85%] rounded-card px-3 py-2 ${
        right ? 'bg-primary/10 border border-primary/15' : 'bg-black/[0.04] border border-black/5'}`}>
        <div className={`text-xs font-medium mb-0.5 ${right ? 'text-primary' : 'text-ink-soft'}`}>
          {title}
        </div>
        <p className="text-sm whitespace-pre-wrap break-words">{text}</p>
        <div className="text-[10px] text-ink-soft mt-1 text-right">{formatDateTime(at)}</div>
      </div>
    </div>
  );
}
