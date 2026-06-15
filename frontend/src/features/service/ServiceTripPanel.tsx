import { useEffect, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Receipt, Check } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';

interface Trip {
  id: string; name?: string | null; status: string;
  collected: string; spent: string;
  note?: string | null; ticket_count: number; scheduled_count: number;
}

const grp = (s: string) => s.replace(/[^\d]/g, '').replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseInt(s.replace(/[^\d]/g, ''), 10) || 0;
const fmt = (v: string) => (Number(v) ? grp(String(Math.round(Number(v)))) : '');

/**
 * Servis safari paneli — FAQAT "Rejalashtirilgan" filtrida.
 * Nom + olingan/sarflangan avtomatik saqlanadi (Saqlash tugmasi yo'q).
 * "Safarni yakunlash" — barcha rejalashtirilgan arizalarni "bajarildi" ga o'tkazadi.
 */
export default function ServiceTripPanel({ onChanged }: { onChanged: () => void }) {
  const { t } = useTranslation();
  const tripQ = useQuery<Trip>({
    queryKey: ['service-trip'],
    queryFn: () => api.get('/service/trips/current').then((r) => r.data),
  });
  const trip = tripQ.data;

  const [name, setName] = useState('');
  const [collected, setCollected] = useState('');
  const [spent, setSpent] = useState('');
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState(false);
  const dirty = useRef(false);

  useEffect(() => {
    if (!trip) return;
    setName(trip.name ?? '');
    setCollected(fmt(trip.collected));
    setSpent(fmt(trip.spent));
    dirty.current = false;
  }, [trip?.id]);

  // Avtosaqlash — o'zgarishdan ~700ms keyin
  useEffect(() => {
    if (!trip || !dirty.current) return;
    const tmr = setTimeout(autoSave, 700);
    return () => clearTimeout(tmr);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [name, collected, spent]);

  async function autoSave() {
    if (!trip) return;
    try {
      await api.patch(`/service/trips/${trip.id}`, {
        name: name.trim() || null, collected: toNum(collected), spent: toNum(spent),
      });
      dirty.current = false;
      setSaved(true);
      setTimeout(() => setSaved(false), 1500);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    }
  }

  async function finalize() {
    if (!trip) return;
    setBusy(true);
    try {
      await api.post(`/service/trips/${trip.id}/close`);
      toast.success(t('service.trip.closed'));
      tripQ.refetch();
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setBusy(false);
    }
  }

  const net = toNum(collected) - toNum(spent);

  return (
    <div className="rounded-card border border-primary/20 bg-primary/[0.04] p-4 space-y-3">
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="font-semibold flex items-center gap-2">
          <Receipt size={16} className="text-primary" /> {t('service.trip.title')}
          {saved && <span className="text-xs font-normal text-success">✓ {t('service.trip.saved')}</span>}
        </div>
        <div className="text-xs text-ink-soft">
          {t('service.trip.ticketCount', { n: trip?.scheduled_count ?? 0 })}
        </div>
      </div>

      <div>
        <label className="text-xs text-ink-soft">{t('service.trip.name')}</label>
        <input className="input w-full mt-1" placeholder={t('service.trip.namePlaceholder')}
               value={name}
               onChange={(e) => { dirty.current = true; setName(e.target.value); }} />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <Field label={t('service.trip.collected')} value={collected} accent="text-success"
               onChange={(v) => { dirty.current = true; setCollected(grp(v)); }} />
        <Field label={t('service.trip.spent')} value={spent} accent="text-danger"
               onChange={(v) => { dirty.current = true; setSpent(grp(v)); }} />
      </div>

      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="text-sm text-ink-soft">
          {t('service.trip.net')}:{' '}
          <span className={net >= 0 ? 'text-success font-semibold' : 'text-danger font-semibold'}>
            {formatUZS(net)}
          </span>
        </div>
        <button onClick={finalize} disabled={busy}
                className="px-3 py-1.5 text-sm rounded-button border border-success/30 text-success hover:bg-success/10 disabled:opacity-50 inline-flex items-center gap-1">
          <Check size={15} /> {t('service.trip.finalize')}
        </button>
      </div>
    </div>
  );
}

function Field({ label, value, onChange, accent }: {
  label: string; value: string; onChange: (v: string) => void; accent: string;
}) {
  return (
    <div>
      <label className="text-xs text-ink-soft">{label}</label>
      <input inputMode="numeric" placeholder="0" value={value}
             onChange={(e) => onChange(e.target.value)}
             className={'input w-full mt-1 font-semibold ' + accent} />
    </div>
  );
}
