import { useEffect, useRef, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  MapPin, Navigation, Copy, Trash2, Send, Loader2, AlertTriangle, X,
} from 'lucide-react';

import { api } from '@/api/client';
import { formatDateTime } from '@/lib/format';
import {
  copyToClipboard, formatCoords, hasLocation, mapLinks, sourceLabel,
  type TicketLocationFields,
} from './location';

interface LocationRequest {
  ticket_code: string;
  expires_at: string;
  deep_link?: string | null;
  bot_username?: string | null;
}

/**
 * Ariza kartochkasidagi lokatsiya bloki.
 *
 * Lokatsiya AYNAN shu arizaga tegishli — mijozga doimiy biriktirilmaydi.
 * Uch yo'l bilan tushadi: botga forward qilingan Telegram pin, xarita
 * havolasi yoki qo'lda yozilgan koordinata.
 */
export default function TicketLocation({
  ticketId, loc, onChanged,
}: { ticketId: string; loc: TicketLocationFields; onChanged: () => void }) {
  const qc = useQueryClient();
  const has = hasLocation(loc);

  const [raw, setRaw] = useState('');
  const [note, setNote] = useState(loc.location_note ?? '');
  const [busy, setBusy] = useState(false);
  const [editing, setEditing] = useState(false);
  const [waiting, setWaiting] = useState<LocationRequest | null>(null);
  const savedNote = useRef(loc.location_note ?? '');

  useEffect(() => {
    setNote(loc.location_note ?? '');
    savedNote.current = loc.location_note ?? '';
  }, [loc.location_note]);

  // Botdan lokatsiya kutilayotganda — arizani muntazam yangilab turamiz.
  useEffect(() => {
    if (!waiting) return;
    const timer = setInterval(() => {
      qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
    }, 4000);
    return () => clearInterval(timer);
  }, [waiting, ticketId, qc]);

  // Lokatsiya kelib tushdi — kutishni yopamiz. `location_added_at` ham
  // kuzatiladi: mavjud lokatsiya bot orqali ALMASHTIRILGANDA `has` o'zgarmaydi.
  useEffect(() => {
    if (waiting && has) {
      setWaiting(null);
      setEditing(false);
      toast.success('Lokatsiya biriktirildi');
      onChanged();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [has, loc.location_added_at]);

  // Kutish muddati tugadi.
  useEffect(() => {
    if (!waiting) return;
    const left = new Date(waiting.expires_at).getTime() - Date.now();
    if (left <= 0) { setWaiting(null); return; }
    const timer = setTimeout(() => setWaiting(null), left);
    return () => clearTimeout(timer);
  }, [waiting]);

  async function save() {
    const value = raw.trim();
    if (!value) { toast.error('Havola yoki koordinatani kiriting'); return; }
    setBusy(true);
    try {
      await api.patch(`/service/tickets/${ticketId}/location`, {
        raw: value, note: note.trim() || null,
      });
      setRaw('');
      setEditing(false);
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      onChanged();
      toast.success('Lokatsiya saqlandi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  async function saveNote() {
    if (!has || note.trim() === savedNote.current.trim()) return;
    try {
      await api.patch(`/service/tickets/${ticketId}/location`, { note: note.trim() || null });
      savedNote.current = note.trim();
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    }
  }

  async function remove() {
    setBusy(true);
    try {
      await api.delete(`/service/tickets/${ticketId}/location`);
      await qc.invalidateQueries({ queryKey: ['service-ticket', ticketId] });
      onChanged();
      toast.success("Lokatsiya o'chirildi");
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  async function askTelegram() {
    setBusy(true);
    try {
      const r = await api.post(`/service/tickets/${ticketId}/location-request`);
      setWaiting(r.data);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  const links = has ? mapLinks(loc.lat as number, loc.lon as number) : null;

  return (
    <div className="space-y-2">
      {has && links && (
        <div className="rounded-button border border-success/25 bg-success/[0.07] p-3 space-y-2">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <div className="text-sm font-medium text-success inline-flex items-center gap-1.5">
                <MapPin size={15} /> Lokatsiya biriktirilgan
              </div>
              <button type="button"
                      onClick={async () => {
                        const ok = await copyToClipboard(formatCoords(loc.lat as number, loc.lon as number));
                        toast[ok ? 'success' : 'error'](ok ? 'Nusxalandi' : 'Nusxalab bo\'lmadi');
                      }}
                      className="mt-1 text-xs font-mono text-ink-soft hover:text-ink inline-flex items-center gap-1">
                {formatCoords(loc.lat as number, loc.lon as number)} <Copy size={12} />
              </button>
            </div>
            <button type="button" onClick={remove} disabled={busy}
                    title="Lokatsiyani o'chirish"
                    className="p-1 rounded hover:bg-black/5 text-ink-soft hover:text-danger">
              <Trash2 size={15} />
            </button>
          </div>

          <div className="flex flex-wrap gap-2">
            <a href={links.yandexRoute} target="_blank" rel="noreferrer"
               className="btn-action bg-primary text-white hover:bg-primary-700">
              <Navigation size={15} /> Yandex Navigator
            </a>
            <a href={links.google} target="_blank" rel="noreferrer"
               className="btn-action bg-black/5 text-ink hover:bg-black/10">
              <MapPin size={15} /> Google Maps
            </a>
            <button type="button" onClick={() => setEditing((v) => !v)}
                    className="btn-action bg-black/5 text-ink-soft hover:bg-black/10">
              Almashtirish
            </button>
          </div>

          <input className="input text-sm" placeholder="Mo'ljal (masalan: ko'k darvoza, do'kon yonida)"
                 value={note} onChange={(e) => setNote(e.target.value)} onBlur={saveNote} />

          <div className="text-[11px] text-ink-soft">
            {sourceLabel(loc.location_source)}
            {loc.location_added_at && ` · ${formatDateTime(loc.location_added_at)}`}
          </div>
        </div>
      )}

      {/* Havola saqlangan, lekin koordinata aniqlanmagan */}
      {!has && loc.location_url && (
        <div className="rounded-button border border-warning/30 bg-warning/10 p-3 text-sm flex gap-2">
          <AlertTriangle size={16} className="shrink-0 mt-0.5 text-warning" />
          <div className="min-w-0">
            <div className="font-medium text-warning">Havola saqlandi, koordinata aniqlanmadi</div>
            {loc.location_url.toLowerCase().startsWith('http') ? (
              <a href={loc.location_url} target="_blank" rel="noreferrer"
                 className="text-xs text-ink-soft underline break-all">{loc.location_url}</a>
            ) : (
              <div className="text-xs text-ink-soft break-all">{loc.location_url}</div>
            )}
            <div className="text-xs text-ink-soft mt-0.5">
              Havolani xaritada ochib, uzun (to'liq) havolani quyiga qo'ying.
            </div>
          </div>
        </div>
      )}

      {waiting ? (
        <div className="rounded-button border border-primary/25 bg-primary/[0.06] p-3 space-y-2 text-sm">
          <div className="font-medium text-primary inline-flex items-center gap-1.5">
            <Loader2 size={15} className="animate-spin" /> Lokatsiya kutilmoqda — {waiting.ticket_code}
          </div>
          <ol className="text-xs text-ink-soft list-decimal list-inside space-y-0.5">
            <li>Botga o'ting</li>
            <li>Mijoz yuborgan lokatsiyani botga <b>forward</b> qiling</li>
            <li>Bu yerda avtomatik paydo bo'ladi</li>
          </ol>
          <div className="flex flex-wrap items-center gap-2">
            {waiting.deep_link ? (
              <a href={waiting.deep_link} target="_blank" rel="noreferrer"
                 className="btn-action bg-primary text-white hover:bg-primary-700">
                <Send size={15} /> Botga o'tish
              </a>
            ) : (
              <span className="text-xs text-danger">
                Bot havolasi sozlanmagan (TELEGRAM_BOT_USERNAME) — administratorga ayting.
              </span>
            )}
            <button type="button" onClick={() => setWaiting(null)}
                    className="btn-action bg-black/5 text-ink-soft hover:bg-black/10">
              <X size={15} /> Bekor qilish
            </button>
          </div>
          <div className="text-[11px] text-ink-soft">
            Muddat: {formatDateTime(waiting.expires_at)} gacha
          </div>
        </div>
      ) : (!has || editing) && (
        <div className="rounded-button border border-dashed border-black/15 p-3 space-y-2">
          {!has && (
            <div className="text-sm font-medium text-ink-soft inline-flex items-center gap-1.5">
              <MapPin size={15} /> Lokatsiya biriktirilmagan
            </div>
          )}
          <input className="input text-sm" placeholder="Xarita havolasi yoki 41.311, 69.240"
                 value={raw} onChange={(e) => setRaw(e.target.value)}
                 onKeyDown={(e) => e.key === 'Enter' && save()} />
          {!has && (
            <input className="input text-sm" placeholder="Mo'ljal (ixtiyoriy)"
                   value={note} onChange={(e) => setNote(e.target.value)} />
          )}
          <div className="flex flex-wrap gap-2">
            <button type="button" onClick={save} disabled={busy}
                    className="btn-action bg-primary text-white hover:bg-primary-700">
              Saqlash
            </button>
            <button type="button" onClick={askTelegram} disabled={busy}
                    title="Botga o'tib, mijoz yuborgan lokatsiyani forward qilasiz"
                    className="btn-action bg-black/5 text-ink hover:bg-black/10">
              <Send size={15} /> Telegram orqali olish
            </button>
            {editing && (
              <button type="button" onClick={() => { setEditing(false); setRaw(''); }}
                      className="btn-action bg-black/5 text-ink-soft hover:bg-black/10">
                Bekor qilish
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
