import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  ArrowLeft, Instagram, Phone, Languages, Trash2, UserPlus,
  ExternalLink, Bot, MessageSquare, CheckCircle2, Flame,
  XCircle, MessageCircle, Check, StickyNote, Plus, User,
} from 'lucide-react';

import Card from '@/components/ui/Card';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { cn } from '@/lib/cn';
import { formatDateTime, formatPhone } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import {
  leadsApi, LEAD_STATUS_LABELS, LANG_LABELS,
  type LeadDetail, type LeadStatus,
} from '@/features/leads/api';
import ConvertModal from '@/features/leads/ConvertModal';

// Quvur bosqichlari (yakuniy "lost" alohida ishlanadi)
const PIPELINE: LeadStatus[] = ['new', 'contacted', 'qualified', 'won'];

export default function LeadDetailPage() {
  const { leadId } = useParams<{ leadId: string }>();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('leads:write');
  const canDelete = can('leads:delete');

  const [newNote, setNewNote] = useState('');
  const [addingNote, setAddingNote] = useState(false);
  const [showConvert, setShowConvert] = useState(false);
  const [showDelete, setShowDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const leadQ = useQuery<LeadDetail>({
    queryKey: ['lead', leadId],
    queryFn: () => leadsApi.get(leadId!),
    enabled: !!leadId,
  });

  const lead = leadQ.data;

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

  async function addNote() {
    const text = newNote.trim();
    if (!text || !leadId) return;
    setAddingNote(true);
    try {
      await leadsApi.addNote(leadId, text);
      setNewNote('');
      toast.success('Izoh qo\'shildi');
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setAddingNote(false);
    }
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
        <div className="grid lg:grid-cols-3 gap-4">
          <div className="lg:col-span-2 h-80 rounded-card bg-black/5 animate-pulse" />
          <div className="h-80 rounded-card bg-black/5 animate-pulse" />
        </div>
      </div>
    );
  }

  const displayName = lead.name || lead.ig_username || "Noma'lum lead";
  const igLink = lead.ig_username ? `https://instagram.com/${lead.ig_username}` : null;
  const digits = (lead.contact || '').replace(/\D/g, '');
  const phone = digits.length >= 7 ? lead.contact! : null;

  // Suhbat (AI) vs izohlar (xodim) — ajratamiz
  const convEvents = lead.events.filter((e) => e.kind !== 'note');
  const notes = lead.events.filter((e) => e.kind === 'note').slice().reverse(); // yangi tepada
  const msgCount = convEvents.filter((e) => e.message_text || e.agent_reply).length;
  const lastEvent = lead.events[lead.events.length - 1];

  return (
    <div className="space-y-4">
      <button onClick={() => navigate('/leads')}
              className="flex items-center gap-1.5 text-sm text-ink-soft hover:text-ink">
        <ArrowLeft size={16} /> Leadlarga qaytish
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 items-start">
        {/* ================= CHAP: profil + suhbat ================= */}
        <div className="lg:col-span-2 space-y-4">
          {/* Profil */}
          <Card className="overflow-hidden !p-0">
            <div className="p-5">
              <div className="flex items-start gap-4">
                <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-fuchsia-500 to-orange-400 text-white flex items-center justify-center shrink-0 shadow-sm">
                  <Instagram size={26} />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <h1 className="text-xl font-bold truncate">{displayName}</h1>
                    {lead.customer_id && (
                      <span className="inline-flex items-center gap-1 text-xs font-medium rounded-full px-2 py-0.5 bg-emerald-100 text-emerald-700">
                        <CheckCircle2 size={12} /> Mijoz
                      </span>
                    )}
                  </div>
                  <div className="text-sm text-ink-soft mt-1 flex items-center gap-2 flex-wrap">
                    {igLink ? (
                      <a href={igLink} target="_blank" rel="noreferrer"
                         className="inline-flex items-center gap-1 text-primary hover:underline font-medium">
                        @{lead.ig_username} <ExternalLink size={12} />
                      </a>
                    ) : <span>@—</span>}
                    <span className="inline-flex items-center gap-1 text-xs rounded-full px-2 py-0.5 bg-black/[0.05]">
                      <Instagram size={11} /> Instagram
                    </span>
                    <span>·</span>
                    <span>{formatDateTime(lead.created_at)}</span>
                  </div>
                </div>
                <ScoreMeter score={lead.lead_score} />
              </div>

              {/* Quvur bosqichi */}
              <Pipeline
                status={lead.status}
                canWrite={canWrite}
                onSet={(st) => patch({ status: st }, 'Holat yangilandi')}
              />

              {/* Tezkor aloqa */}
              <div className="flex flex-wrap gap-2 mt-4">
                {phone && (
                  <>
                    <ActionBtn href={`tel:${digits}`} icon={<Phone size={15} />} label="Qo'ng'iroq" />
                    <ActionBtn href={`https://wa.me/${digits}`} icon={<MessageCircle size={15} />}
                               label="WhatsApp" tone="success" external />
                  </>
                )}
                {igLink && (
                  <ActionBtn href={igLink} icon={<Instagram size={15} />} label="Instagram" external />
                )}
                {!phone && !igLink && (
                  <span className="text-xs text-ink-soft">Aloqa ma'lumoti yo'q</span>
                )}
              </div>
            </div>

            {/* Asosiy faktlar — telefon raqami asosiy */}
            <div className="grid grid-cols-2 border-t border-black/5 divide-x divide-black/5">
              <Fact icon={<Phone size={14} />} label="Telefon raqami"
                    value={lead.contact ? formatPhone(lead.contact) : '—'} />
              <Fact icon={<Languages size={14} />} label="Til"
                    value={lead.language ? (LANG_LABELS[lead.language] ?? lead.language) : '—'} />
            </div>

            {lead.summary && (
              <div className="mx-5 mb-5 rounded-card bg-primary/[0.04] border border-primary/10 p-3.5">
                <div className="text-xs font-semibold text-primary mb-1 flex items-center gap-1.5">
                  <Bot size={13} /> AI xulosasi
                </div>
                <p className="text-sm leading-relaxed">{lead.summary}</p>
              </div>
            )}
          </Card>

          {/* Suhbat tarixi */}
          <Card>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold flex items-center gap-2">
                <MessageSquare size={16} className="text-primary" /> Suhbat tarixi
              </h3>
              {msgCount > 0 && (
                <span className="text-xs text-ink-soft">{msgCount} ta xabar</span>
              )}
            </div>
            {convEvents.length === 0 ? (
              <div className="text-sm text-ink-soft py-8 text-center">
                <MessageSquare size={28} className="mx-auto mb-2 opacity-30" />
                Hozircha suhbat yo'q
              </div>
            ) : (
              <div className="space-y-3">
                {convEvents.map((ev) => {
                  if (ev.kind === 'status') {
                    return (
                      <div key={ev.id} className="flex items-center gap-2 justify-center">
                        <span className="inline-flex items-center gap-1.5 text-xs text-ink-soft bg-black/[0.04] rounded-full px-2.5 py-1">
                          <CheckCircle2 size={12} /> Holat o'zgardi · {formatDateTime(ev.created_at)}
                        </span>
                      </div>
                    );
                  }
                  const chanTag = ev.kind === 'comment' ? 'Izoh' : 'DM';
                  return (
                    <div key={ev.id} className="space-y-2">
                      {ev.message_text && (
                        <Bubble side="left" name={lead.ig_username ? `@${lead.ig_username}` : 'Mijoz'}
                                tag={chanTag} text={ev.message_text} at={ev.created_at} />
                      )}
                      {ev.agent_reply && (
                        <Bubble side="right" name="AI agent" text={ev.agent_reply} at={ev.created_at} />
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </Card>

          {/* Izohlar tarixi — sotuvchi bog'lanish jurnali */}
          <Card>
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-semibold flex items-center gap-2">
                <StickyNote size={16} className="text-primary" /> Izohlar tarixi
              </h3>
              {notes.length > 0 && <span className="text-xs text-ink-soft">{notes.length} ta</span>}
            </div>

            {canWrite && (
              <div className="mb-4">
                <textarea
                  className="input w-full min-h-[70px] resize-y"
                  value={newNote}
                  onChange={(e) => setNewNote(e.target.value)}
                  placeholder="Bog'lanish natijasi, kelishuv, keyingi qadam..."
                />
                <div className="flex justify-end mt-2">
                  <button onClick={addNote} disabled={addingNote || !newNote.trim()}
                          className="btn-primary inline-flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed">
                    <Plus size={15} /> {addingNote ? 'Qo\'shilmoqda...' : 'Izoh qo\'shish'}
                  </button>
                </div>
              </div>
            )}

            {notes.length === 0 ? (
              <div className="text-sm text-ink-soft py-6 text-center">
                <StickyNote size={26} className="mx-auto mb-2 opacity-30" />
                Hali izoh yo'q. Har bog'lanishdan so'ng natijani yozib boring.
              </div>
            ) : (
              <div className="space-y-2.5">
                {notes.map((n) => (
                  <div key={n.id} className="rounded-card border border-black/5 bg-black/[0.015] p-3">
                    <div className="flex items-center justify-between text-xs text-ink-soft mb-1.5">
                      <span className="inline-flex items-center gap-1 font-medium text-ink">
                        <User size={12} /> {n.meta?.by_name || 'Xodim'}
                      </span>
                      <span>{formatDateTime(n.created_at)}</span>
                    </div>
                    <p className="text-sm whitespace-pre-wrap break-words">{n.message_text}</p>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>

        {/* ================= O'NG: amallar ================= */}
        <div className="space-y-4">
          {/* Amallar */}
          <Card>
            <div className="space-y-2">
              {lead.customer_id ? (
                <button onClick={() => navigate(`/customers/${lead.customer_id}`)}
                        className="w-full inline-flex items-center justify-center gap-2 px-3 py-2.5 rounded-button text-sm font-medium bg-success/10 text-success hover:bg-success/20 transition">
                  <CheckCircle2 size={16} /> Mijoz kartasini ochish
                </button>
              ) : (
                <button onClick={() => setShowConvert(true)} disabled={!canWrite}
                        className="w-full inline-flex items-center justify-center gap-2 px-3 py-2.5 rounded-button text-sm font-semibold bg-primary text-white hover:opacity-90 transition disabled:opacity-50">
                  <UserPlus size={16} /> Mijozga aylantirish
                </button>
              )}
              {canWrite && lead.status !== 'lost' && !lead.customer_id && (
                <button onClick={() => patch({ status: 'lost' }, 'Yo\'qotilgan deb belgilandi')}
                        className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-button text-sm font-medium text-ink-soft hover:bg-black/[0.04] transition">
                  <XCircle size={15} /> Yo'qotilgan deb belgilash
                </button>
              )}
              {canDelete && (
                <button onClick={() => setShowDelete(true)}
                        className="w-full inline-flex items-center justify-center gap-2 px-3 py-2 rounded-button text-sm font-medium text-danger hover:bg-danger/10 transition">
                  <Trash2 size={15} /> Lead'ni o'chirish
                </button>
              )}
            </div>
            {lastEvent && (
              <p className="text-xs text-ink-soft text-center mt-3">
                So'nggi faollik: {formatDateTime(lastEvent.created_at)}
              </p>
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

// ===========================================================================
// Lead ball o'lchagichi (issiq/iliq/sovuq)
// ===========================================================================
function ScoreMeter({ score }: { score: number }) {
  const hot = score >= 70, warm = score >= 40 && score < 70;
  const color = hot ? 'text-red-600' : warm ? 'text-amber-600' : 'text-slate-500';
  const bar = hot ? 'bg-red-500' : warm ? 'bg-amber-500' : 'bg-slate-400';
  const label = hot ? 'Issiq' : warm ? 'Iliq' : 'Sovuq';
  return (
    <div className="text-right shrink-0 w-28">
      <div className={cn('text-2xl font-bold tabular-nums flex items-center justify-end gap-1', color)}>
        {hot && <Flame size={18} />}{score}
      </div>
      <div className={cn('text-xs font-medium', color)}>{label} lead</div>
      <div className="h-1.5 rounded-full bg-black/10 mt-1.5 overflow-hidden">
        <div className={cn('h-full rounded-full transition-all', bar)}
             style={{ width: `${Math.max(4, Math.min(100, score))}%` }} />
      </div>
    </div>
  );
}

// ===========================================================================
// Quvur (pipeline) bosqichlari
// ===========================================================================
function Pipeline({ status, canWrite, onSet }: {
  status: LeadStatus; canWrite: boolean; onSet: (st: LeadStatus) => void;
}) {
  const isLost = status === 'lost';
  const currentIdx = isLost ? -1 : PIPELINE.indexOf(status);

  return (
    <div className="mt-4">
      <div className="flex items-center">
        {PIPELINE.map((st, i) => {
          const done = !isLost && i < currentIdx;
          const current = !isLost && i === currentIdx;
          const isWon = st === 'won';
          const solid = current
            ? (isWon ? 'bg-emerald-500 text-white' : 'bg-primary text-white')
            : done ? 'bg-primary/15 text-primary' : 'bg-black/[0.05] text-ink-soft';
          return (
            <div key={st} className="flex items-center flex-1 last:flex-none">
              <button
                type="button"
                disabled={!canWrite}
                onClick={() => canWrite && onSet(st)}
                className={cn(
                  'flex items-center gap-1.5 rounded-full pl-1.5 pr-2.5 py-1 text-xs font-medium transition shrink-0',
                  solid,
                  canWrite && 'hover:ring-2 hover:ring-primary/20 cursor-pointer',
                )}
                title={canWrite ? `"${LEAD_STATUS_LABELS[st]}" ga o'tkazish` : undefined}
              >
                <span className={cn(
                  'w-4 h-4 rounded-full flex items-center justify-center text-[10px]',
                  current ? 'bg-white/25' : done ? 'bg-primary/25' : 'bg-black/10',
                )}>
                  {done || (current && isWon) ? <Check size={11} /> : i + 1}
                </span>
                {LEAD_STATUS_LABELS[st]}
              </button>
              {i < PIPELINE.length - 1 && (
                <div className={cn('h-0.5 flex-1 mx-1 rounded', i < currentIdx ? 'bg-primary/40' : 'bg-black/10')} />
              )}
            </div>
          );
        })}
      </div>
      {isLost && (
        <div className="mt-2 inline-flex items-center gap-1.5 text-xs font-medium text-gray-600 bg-gray-200 rounded-full px-2.5 py-1">
          <XCircle size={12} /> Yo'qotilgan
          {canWrite && (
            <button onClick={() => onSet('new')} className="ml-1 underline hover:no-underline">
              qayta ochish
            </button>
          )}
        </div>
      )}
    </div>
  );
}

// ===========================================================================
// Tezkor amal tugmasi
// ===========================================================================
function ActionBtn({ href, icon, label, tone, external }: {
  href: string; icon: React.ReactNode; label: string;
  tone?: 'success'; external?: boolean;
}) {
  return (
    <a href={href} target={external ? '_blank' : undefined} rel={external ? 'noreferrer' : undefined}
       className={cn(
         'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-button text-sm font-medium border transition',
         tone === 'success'
           ? 'border-emerald-200 text-emerald-700 bg-emerald-50 hover:bg-emerald-100'
           : 'border-black/10 text-ink hover:bg-black/[0.04]',
       )}>
      {icon} {label}
    </a>
  );
}

// ===========================================================================
// Asosiy fakt katakchasi
// ===========================================================================
function Fact({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="p-3.5">
      <div className="text-xs text-ink-soft flex items-center gap-1.5">{icon} {label}</div>
      <div className="text-sm font-semibold mt-1 truncate" title={value}>{value}</div>
    </div>
  );
}

// ===========================================================================
// Suhbat "pufakchasi"
// ===========================================================================
function Bubble({ side, name, tag, text, at }: {
  side: 'left' | 'right'; name: string; tag?: string; text: string; at: string;
}) {
  const right = side === 'right';
  return (
    <div className={cn('flex gap-2', right ? 'justify-end' : 'justify-start')}>
      {!right && (
        <div className="w-7 h-7 rounded-full bg-black/[0.06] text-ink-soft flex items-center justify-center shrink-0 mt-0.5">
          <Instagram size={13} />
        </div>
      )}
      <div className={cn(
        'max-w-[80%] rounded-2xl px-3.5 py-2',
        right ? 'bg-primary text-white rounded-br-sm' : 'bg-black/[0.04] border border-black/5 rounded-bl-sm',
      )}>
        <div className={cn('flex items-center gap-1.5 text-xs font-medium mb-0.5',
                           right ? 'text-white/80' : 'text-ink-soft')}>
          {name}
          {tag && (
            <span className={cn('text-[10px] rounded px-1 py-px',
                                right ? 'bg-white/20' : 'bg-black/[0.06]')}>{tag}</span>
          )}
        </div>
        <p className="text-sm whitespace-pre-wrap break-words">{text}</p>
        <div className={cn('text-[10px] mt-1 text-right', right ? 'text-white/70' : 'text-ink-soft')}>
          {formatDateTime(at)}
        </div>
      </div>
      {right && (
        <div className="w-7 h-7 rounded-full bg-primary/15 text-primary flex items-center justify-center shrink-0 mt-0.5">
          <Bot size={13} />
        </div>
      )}
    </div>
  );
}
