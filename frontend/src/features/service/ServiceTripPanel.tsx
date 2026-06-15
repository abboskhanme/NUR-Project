import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Receipt, Check } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';

interface Trip {
  id: string; status: string;
  collected: string; spent: string; total_cost: string;
  note?: string | null; ticket_count: number; scheduled_count: number;
}

const grp = (s: string) => s.replace(/[^\d]/g, '').replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseInt(s.replace(/[^\d]/g, ''), 10) || 0;
const fmt = (v: string) => (Number(v) ? grp(String(Math.round(Number(v)))) : '');

/**
 * Servis safari paneli — FAQAT "Rejalashtirilgan" filtrida ko'rsatiladi.
 * Barcha rejalashtirilgan arizalar bitta safar; uchta umumiy summa qo'lda kiritiladi.
 */
export default function ServiceTripPanel({ onChanged }: { onChanged: () => void }) {
  const { t } = useTranslation();
  const tripQ = useQuery<Trip>({
    queryKey: ['service-trip'],
    queryFn: () => api.get('/service/trips/current').then((r) => r.data),
  });
  const trip = tripQ.data;

  const [collected, setCollected] = useState('');
  const [spent, setSpent] = useState('');
  const [totalCost, setTotalCost] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!trip) return;
    setCollected(fmt(trip.collected));
    setSpent(fmt(trip.spent));
    setTotalCost(fmt(trip.total_cost));
  }, [trip?.id]);

  async function save() {
    if (!trip) return;
    setBusy(true);
    try {
      await api.patch(`/service/trips/${trip.id}`, {
        collected: toNum(collected), spent: toNum(spent), total_cost: toNum(totalCost),
      });
      toast.success(t('common.updated'));
      tripQ.refetch();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setBusy(false);
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
        </div>
        <div className="text-xs text-ink-soft">
          {t('service.trip.ticketCount', { n: trip?.scheduled_count ?? 0 })}
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <Field label={t('service.trip.collected')} value={collected} accent="text-success"
               onChange={(v) => setCollected(grp(v))} />
        <Field label={t('service.trip.spent')} value={spent} accent="text-danger"
               onChange={(v) => setSpent(grp(v))} />
        <Field label={t('service.trip.totalCost')} value={totalCost} accent="text-ink"
               onChange={(v) => setTotalCost(grp(v))} />
      </div>

      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="text-sm text-ink-soft">
          {t('service.trip.net')}:{' '}
          <span className={net >= 0 ? 'text-success font-semibold' : 'text-danger font-semibold'}>
            {formatUZS(net)}
          </span>
        </div>
        <div className="flex gap-2">
          <button onClick={save} disabled={busy} className="btn-primary disabled:opacity-50">
            {t('actions.save')}
          </button>
          <button onClick={finalize} disabled={busy}
                  className="px-3 py-1.5 text-sm rounded-button border border-success/30 text-success hover:bg-success/10 disabled:opacity-50 inline-flex items-center gap-1">
            <Check size={15} /> {t('service.trip.finalize')}
          </button>
        </div>
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
