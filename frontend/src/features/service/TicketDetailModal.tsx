import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  X, Phone, Package, ShieldCheck, ShieldAlert, ShieldX, Truck,
  CalendarClock, Check, Ban, Plus,
} from 'lucide-react';

import { api } from '@/api/client';
import DateInput from '@/components/ui/DateInput';
import { formatDate, formatDateTime, formatPhone, formatUZS } from '@/lib/format';
import { ServiceStatusBadge } from './status';

interface Visit { id: string; planned_at?: string | null; note?: string | null; created_at: string }
interface Ticket {
  id: string; code: string; status: string; problem: string; category?: string | null;
  in_warranty: boolean; opened_at: string; scheduled_at?: string | null; closed_at?: string | null;
  resolution?: string | null; client_cost: string; address?: string | null; order_id?: string | null;
  customer?: { full_name: string; phone: string } | null;
  order?: { code: string; delivered_at?: string | null } | null;
  visits: Visit[];
}
interface Warranty {
  current_status: 'active_full' | 'active_service_only' | 'expired' | 'not_delivered';
  year1_end?: string | null; year3_end?: string | null;
  days_remaining_year1?: number | null; days_remaining_year3?: number | null;
}

const WMETA: Record<string, { label: string; cls: string; Icon: any }> = {
  active_full: { label: '1-yil — to\'liq bepul (ish + ehtiyot qism)', cls: 'bg-success/10 text-success', Icon: ShieldCheck },
  active_service_only: { label: '2–3-yil — faqat ish bepul, ehtiyot qism mijoz hisobidan', cls: 'bg-warning/10 text-warning', Icon: ShieldAlert },
  expired: { label: 'Kafolat tugagan — hammasi mijoz hisobidan', cls: 'bg-gray-100 text-gray-600', Icon: ShieldX },
  not_delivered: { label: 'Mahsulot hali yetkazilmagan', cls: 'bg-blue-50 text-blue-700', Icon: Truck },
};

const fmtCost = (s: string) => s.replace(/[^\d]/g, '').replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseInt(s.replace(/[^\d]/g, ''), 10) || 0;

function splitDt(iso?: string | null): { d: string; t: string } {
  if (!iso) return { d: '', t: '' };
  const dt = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, '0');
  return {
    d: `${dt.getFullYear()}-${pad(dt.getMonth() + 1)}-${pad(dt.getDate())}`,
    t: `${pad(dt.getHours())}:${pad(dt.getMinutes())}`,
  };
}

export default function TicketDetailModal({
  ticketId, onClose, onChanged,
}: { ticketId: string; onClose: () => void; onChanged: () => void }) {
  const qc = useQueryClient();
  const ticketQ = useQuery<Ticket>({
    queryKey: ['service-ticket', ticketId],
    queryFn: () => api.get(`/service/tickets/${ticketId}`).then((r) => r.data),
  });
  const t = ticketQ.data;

  const warrantyQ = useQuery<Warranty>({
    queryKey: ['svc-warranty', t?.order_id],
    queryFn: () => api.get(`/service/warranty/${t!.order_id}`).then((r) => r.data),
    enabled: !!t?.order_id,
  });

  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [resolution, setResolution] = useState('');
  const [cost, setCost] = useState('');
  const [newNote, setNewNote] = useState('');
  const [busy, setBusy] = useState(false);

  // Ticket yuklangach maydonlarni to'ldiramiz
  useEffect(() => {
    if (!t) return;
    const s = splitDt(t.scheduled_at);
    setDate(s.d); setTime(s.t);
    setResolution(t.resolution || '');
    setCost(t.client_cost && Number(t.client_cost) ? fmtCost(String(Math.round(Number(t.client_cost)))) : '');
  }, [t?.id]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function patch(body: Record<string, unknown>, msg = 'Saqlandi') {
    setBusy(true);
    try {
      await api.patch(`/service/tickets/${ticketId}`, body);
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      onChanged();
      toast.success(msg);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setBusy(false);
    }
  }

  function saveDetails() {
    const scheduled_at = date ? `${date}T${time || '09:00'}:00` : null;
    patch({ scheduled_at, resolution: resolution.trim() || null, client_cost: toNum(cost) });
  }

  async function addNote() {
    if (!newNote.trim() && !date) { toast.error('Izoh yozing'); return; }
    setBusy(true);
    try {
      await api.post(`/service/tickets/${ticketId}/visits`, {
        planned_at: date ? `${date}T${time || '09:00'}:00` : null,
        note: newNote.trim() || null,
      });
      setNewNote('');
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      onChanged();
      toast.success('Izoh qo\'shildi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setBusy(false);
    }
  }

  const W = t?.order_id && warrantyQ.data ? WMETA[warrantyQ.data.current_status] : null;
  const isOpen = t && !['completed', 'cancelled'].includes(t.status);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card z-10">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold">{t?.code ?? 'Ariza'}</h3>
            {t && <ServiceStatusBadge status={t.status} />}
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {!t ? (
          <div className="p-5 space-y-2">
            {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : (
          <div className="p-5 space-y-4">
            {/* Mijoz / mahsulot */}
            <div className="text-sm space-y-1">
              {t.customer && (
                <div className="flex items-center gap-2">
                  <span className="font-medium">{t.customer.full_name}</span>
                  <span className="text-ink-soft inline-flex items-center gap-1"><Phone size={13} /> {formatPhone(t.customer.phone)}</span>
                </div>
              )}
              {t.order && (
                <div className="text-ink-soft inline-flex items-center gap-1">
                  <Package size={13} /> {t.order.code}
                  {t.order.delivered_at && ` — yetkazildi ${formatDate(t.order.delivered_at)}`}
                </div>
              )}
              {t.address && <div className="text-ink-soft">{t.address}</div>}
            </div>

            {/* Kafolat */}
            {W && (
              <div className={`rounded-button p-3 text-sm flex gap-2 ${W.cls}`}>
                <W.Icon size={18} className="shrink-0 mt-0.5" />
                <span className="font-medium">{W.label}</span>
              </div>
            )}

            {/* Muammo */}
            <div>
              <div className="label">Muammo</div>
              <div className="text-sm bg-black/[0.03] rounded-button p-3 whitespace-pre-wrap">{t.problem}</div>
              <div className="text-xs text-ink-soft mt-1">Ochildi: {formatDateTime(t.opened_at)}</div>
            </div>

            {/* Status amallari */}
            {isOpen && (
              <div className="flex flex-wrap gap-2">
                {t.status === 'new' && (
                  <button disabled={busy} onClick={() => patch({ status: 'scheduled' }, 'Rejalashtirildi')}
                    className="btn-action bg-amber-100 text-amber-700 hover:bg-amber-200">
                    <CalendarClock size={15} /> Rejalashtirish
                  </button>
                )}
                <button disabled={busy} onClick={() => patch({ status: 'completed' }, 'Bajarildi deb belgilandi')}
                  className="btn-action bg-emerald-100 text-emerald-700 hover:bg-emerald-200">
                  <Check size={15} /> Bajarildi
                </button>
                <button disabled={busy} onClick={() => patch({ status: 'cancelled' }, 'Bekor qilindi')}
                  className="btn-action bg-gray-100 text-gray-600 hover:bg-gray-200">
                  <Ban size={15} /> Bekor qilish
                </button>
              </div>
            )}

            {/* Sana / yechim / xarajat */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Borish sanasi</label>
                <DateInput value={date} onChange={setDate} />
              </div>
              <div>
                <label className="label">Vaqti</label>
                <input type="time" className="input" value={time} onChange={(e) => setTime(e.target.value)} />
              </div>
            </div>

            <div>
              <label className="label">Yechim (muammo hal bo'ldimi?)</label>
              <textarea className="input min-h-[60px]" placeholder="Nima qilindi, hal bo'ldimi…"
                        value={resolution} onChange={(e) => setResolution(e.target.value)} />
            </div>

            <div>
              <label className="label">Servis xarajati (so'm, ixtiyoriy)</label>
              <input inputMode="numeric" className="input" placeholder="0"
                     value={cost} onChange={(e) => setCost(fmtCost(e.target.value))} />
            </div>

            <button disabled={busy} onClick={saveDetails} className="btn-primary w-full disabled:opacity-50">
              Saqlash
            </button>

            {/* Izohlar / tashriflar jurnali */}
            <div className="pt-2 border-t border-black/5">
              <div className="label">Izohlar jurnali</div>
              <div className="space-y-2 mb-3">
                {t.visits.length === 0 ? (
                  <div className="text-xs text-ink-soft">Hozircha izoh yo'q.</div>
                ) : (
                  [...t.visits]
                    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
                    .map((v) => (
                      <div key={v.id} className="text-sm bg-black/[0.03] rounded-button p-2">
                        {v.note && <div className="whitespace-pre-wrap">{v.note}</div>}
                        <div className="text-xs text-ink-soft mt-0.5">
                          {v.planned_at ? `Reja: ${formatDateTime(v.planned_at)} · ` : ''}{formatDateTime(v.created_at)}
                        </div>
                      </div>
                    ))
                )}
              </div>
              <div className="flex gap-2">
                <input className="input flex-1" placeholder="Yangi izoh qo'shish…"
                       value={newNote} onChange={(e) => setNewNote(e.target.value)}
                       onKeyDown={(e) => e.key === 'Enter' && addNote()} />
                <button disabled={busy} onClick={addNote} className="btn-primary px-3 disabled:opacity-50"><Plus size={16} /></button>
              </div>
            </div>

            {t.closed_at && (
              <div className="text-xs text-ink-soft">Yopildi: {formatDateTime(t.closed_at)}
                {Number(t.client_cost) > 0 && ` · Xarajat: ${formatUZS(t.client_cost)}`}</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
