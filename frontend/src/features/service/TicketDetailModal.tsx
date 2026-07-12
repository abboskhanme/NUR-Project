import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  X, Phone, Package, ShieldCheck, ShieldAlert, ShieldX, Truck,
  CalendarClock, Check, Ban, Plus,
} from 'lucide-react';

import { api } from '@/api/client';
import { formatDate, formatDateTime, formatPhone, formatUZS } from '@/lib/format';
import { ServiceStatusBadge } from './status';

interface Visit { id: string; planned_at?: string | null; note?: string | null; created_at: string }
interface Ticket {
  id: string; code: string; status: string; problem: string; category?: string | null;
  in_warranty: boolean; opened_at: string; closed_at?: string | null;
  resolution?: string | null; client_cost: string; address?: string | null; order_id?: string | null;
  parts_used?: string[];
  customer?: { full_name: string; phone: string } | null;
  order?: { code: string; delivered_at?: string | null } | null;
  visits: Visit[];
}
interface Warranty {
  current_status: 'active_full' | 'active_service_only' | 'expired' | 'not_delivered';
  year1_end?: string | null; year3_end?: string | null;
  days_remaining_year1?: number | null; days_remaining_year3?: number | null;
}

const WMETA_CLS: Record<string, { cls: string; Icon: any }> = {
  active_full: { cls: 'bg-success/10 text-success', Icon: ShieldCheck },
  active_service_only: { cls: 'bg-warning/10 text-warning', Icon: ShieldAlert },
  expired: { cls: 'bg-gray-100 text-gray-600', Icon: ShieldX },
  not_delivered: { cls: 'bg-blue-50 text-blue-700', Icon: Truck },
};

const fmtCost = (s: string) => s.replace(/[^\d]/g, '').replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseInt(s.replace(/[^\d]/g, ''), 10) || 0;

export default function TicketDetailModal({
  ticketId, onClose, onChanged,
}: { ticketId: string; onClose: () => void; onChanged: () => void }) {
  const qc = useQueryClient();
  const ticketQ = useQuery<Ticket>({
    queryKey: ['service-ticket', ticketId],
    queryFn: () => api.get(`/service/tickets/${ticketId}`).then((r) => r.data),
  });
  const tk = ticketQ.data;

  const warrantyQ = useQuery<Warranty>({
    queryKey: ['svc-warranty', tk?.order_id],
    queryFn: () => api.get(`/service/warranty/${tk!.order_id}`).then((r) => r.data),
    enabled: !!tk?.order_id,
  });
  const partsQ = useQuery<{ id: string; name: string }[]>({
    queryKey: ['service-parts'],
    queryFn: () => api.get('/service/parts').then((r) => r.data),
  });
  const allParts = partsQ.data ?? [];

  const [resolution, setResolution] = useState('');
  const [cost, setCost] = useState('');
  const [partsUsed, setPartsUsed] = useState<string[]>([]);
  const [newNote, setNewNote] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!tk) return;
    setResolution(tk.resolution || '');
    setCost(tk.client_cost && Number(tk.client_cost) ? fmtCost(String(Math.round(Number(tk.client_cost)))) : '');
    setPartsUsed(tk.parts_used ?? []);
  }, [tk?.id]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  // Warranty label — literal o'zbekcha matnlar
  function warrantyLabel(status: string): string {
    return status === 'active_full' ? '1-yil — to\'liq bepul (ish + ehtiyot qism)'
      : status === 'active_service_only' ? '2–3-yil — faqat ish bepul, ehtiyot qism mijoz hisobidan'
      : status === 'expired' ? 'Kafolat tugagan — hammasi mijoz hisobidan'
      : 'Mahsulot hali yetkazilmagan';
  }

  async function patch(body: Record<string, unknown>, msg: string, closeAfter = false) {
    setBusy(true);
    try {
      await api.patch(`/service/tickets/${ticketId}`, body);
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      // Hisobot (Sarflangan mablag) — servis xarajati o'zgarsa yangilansin
      qc.invalidateQueries({ queryKey: ['service-trips-stats'] });
      qc.invalidateQueries({ queryKey: ['service-expenses'] });
      onChanged();
      toast.success(msg);
      if (closeAfter) onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  // "Servis xarajati"ni saqlagach modal yopiladi
  function saveDetails() {
    patch({ resolution: resolution.trim() || null, client_cost: toNum(cost), parts_used: partsUsed },
          'Saqlandi', true);
  }

  function togglePart(name: string) {
    setPartsUsed((cur) => (cur.includes(name) ? cur.filter((x) => x !== name) : [...cur, name]));
  }

  async function addNote() {
    if (!newNote.trim()) { toast.error('Izoh yozing'); return; }
    setBusy(true);
    try {
      await api.post(`/service/tickets/${ticketId}/visits`, {
        note: newNote.trim() || null,
      });
      setNewNote('');
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      onChanged();
      toast.success('Izoh qo\'shildi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  const W = tk?.order_id && warrantyQ.data ? WMETA_CLS[warrantyQ.data.current_status] : null;
  const wStatus = warrantyQ.data?.current_status;
  const isOpen = tk && !['completed', 'cancelled'].includes(tk.status);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card z-10">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold">{tk?.code ?? 'Ariza'}</h3>
            {tk && <ServiceStatusBadge status={tk.status} />}
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {!tk ? (
          <div className="p-5 space-y-2">
            {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : (
          <div className="p-5 space-y-4">
            {/* Customer / product */}
            <div className="text-sm space-y-1">
              {tk.customer && (
                <div className="flex items-center gap-2">
                  <span className="font-medium">{tk.customer.full_name}</span>
                  <span className="text-ink-soft inline-flex items-center gap-1"><Phone size={13} /> {formatPhone(tk.customer.phone)}</span>
                </div>
              )}
              {tk.order && (
                <div className="text-ink-soft inline-flex items-center gap-1">
                  <Package size={13} /> {tk.order.code}
                  {tk.order.delivered_at && ` — yetkazildi ${formatDate(tk.order.delivered_at)}`}
                </div>
              )}
              {tk.address && <div className="text-ink-soft">{tk.address}</div>}
            </div>

            {/* Warranty */}
            {W && wStatus && (
              <div className={`rounded-button p-3 text-sm flex gap-2 ${W.cls}`}>
                <W.Icon size={18} className="shrink-0 mt-0.5" />
                <span className="font-medium">{warrantyLabel(wStatus)}</span>
              </div>
            )}

            {/* Problem */}
            <div>
              <div className="label">Muammo</div>
              <div className="text-sm bg-black/[0.03] rounded-button p-3 whitespace-pre-wrap">{tk.problem}</div>
              <div className="text-xs text-ink-soft mt-1">Ochildi: {formatDateTime(tk.opened_at)}</div>
            </div>

            {/* Status actions */}
            {isOpen && (
              <div className="flex flex-wrap gap-2">
                {tk.status === 'new' && (
                  <button disabled={busy}
                    onClick={() => patch({ status: 'scheduled' }, 'Rejalashtirildi')}
                    className="btn-action bg-amber-100 text-amber-700 hover:bg-amber-200">
                    <CalendarClock size={15} /> Rejalashtirish
                  </button>
                )}
                <button disabled={busy}
                  onClick={() => patch({ status: 'completed' }, 'Bajarildi deb belgilandi')}
                  className="btn-action bg-emerald-100 text-emerald-700 hover:bg-emerald-200">
                  <Check size={15} /> Bajarildi
                </button>
                <button disabled={busy}
                  onClick={() => patch({ status: 'cancelled' }, 'Bekor qilindi')}
                  className="btn-action bg-gray-100 text-gray-600 hover:bg-gray-200">
                  <Ban size={15} /> Bekor qilish
                </button>
              </div>
            )}

            {/* Ishlatilgan ehtiyot qismlar — ko'p tanlov */}
            {allParts.length > 0 && (
              <div>
                <label className="label">Ishlatilgan ehtiyot qismlar</label>
                <div className="flex flex-wrap gap-1.5 mt-1">
                  {allParts.map((p) => {
                    const on = partsUsed.includes(p.name);
                    return (
                      <button key={p.id} type="button" onClick={() => togglePart(p.name)}
                        className={'px-2.5 py-1 rounded-full text-xs font-medium border transition ' +
                          (on ? 'bg-primary text-white border-primary'
                              : 'bg-black/5 text-ink-soft border-transparent hover:bg-black/10')}>
                        {p.name}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Resolution / cost */}
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

            {/* Notes / visits journal */}
            <div className="pt-2 border-t border-black/5">
              <div className="label">Izohlar jurnali</div>
              <div className="space-y-2 mb-3">
                {tk.visits.length === 0 ? (
                  <div className="text-xs text-ink-soft">Hozircha izoh yo'q.</div>
                ) : (
                  [...tk.visits]
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

            {tk.closed_at && (
              <div className="text-xs text-ink-soft">
                Yopildi: {formatDateTime(tk.closed_at)}
                {Number(tk.client_cost) > 0 && ` · Xarajat: ${formatUZS(tk.client_cost)}`}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
