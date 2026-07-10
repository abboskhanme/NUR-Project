import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, PiggyBank } from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney } from '@/lib/format';
import MoneyInput from '@/components/ui/MoneyInput';
import { type Target, TARGET_CURRENCY } from '@/features/targets/TargetModal';
import TargetProgress, { targetTone } from '@/features/targets/TargetProgress';

/** Tez tanlash tugmalari — qolgan summaning ulushi. */
const QUICK_SHARES = [0.25, 0.5, 1];
const QUICK_LABELS = ['25%', '50%', 'Qolganini'];

/** Maqsadga summa qo'shish modali. */
export default function TargetContributeModal({
  target, onClose, onSaved,
}: { target: Target; onClose: () => void; onSaved: () => void }) {
  const [amount, setAmount] = useState<number>(0);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  // MoneyInput ichki matn holatini saqlaydi — tez tugma bosilganda uni
  // qayta yaratish uchun key'ni o'zgartiramiz
  const [quickKey, setQuickKey] = useState(0);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const tone = targetTone(target);
  const suffix = TARGET_CURRENCY[String(target.currency)] ?? target.currency;
  // Qo'shilgandan keyingi yangi holat — jonli ko'rinish
  const nextSaved = target.saved_amount + (amount || 0);
  const nextProgress = target.target_amount > 0
    ? Math.min((nextSaved / target.target_amount) * 100, 100)
    : 0;
  const overshoot = amount > 0 && nextSaved > target.target_amount;

  function pickQuick(share: number) {
    setAmount(Math.round(target.remaining * share));
    setQuickKey((k) => k + 1);
  }

  async function handleSave() {
    if (!amount || amount <= 0) { toast.error('Summani kiriting'); return; }
    setSaving(true);
    try {
      await api.post(`/targets/${target.id}/contributions`, {
        amount,
        note: note.trim() || null,
      });
      toast.success(nextSaved >= target.target_amount ? 'Maqsadga erishildi!' : "Summa qo'shildi");
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2">
            <PiggyBank size={18} className="text-primary" />
            Summa qo'shish
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <div className="text-sm font-medium">{target.name}</div>
            <div className="mt-2">
              <TargetProgress progress={nextProgress} tone={tone} />
            </div>
            <div className="flex justify-between text-xs text-ink-soft mt-1.5">
              <span>{formatMoney(nextSaved, target.currency)}</span>
              <span>{formatMoney(target.target_amount, target.currency)}</span>
            </div>
          </div>

          <div className="rounded-button bg-primary/10 border border-primary/20 px-4 py-3 flex items-center justify-between">
            <span className="text-sm font-medium text-primary/90">Qolgan summa</span>
            <span className="text-lg font-bold text-primary">
              {formatMoney(target.remaining, target.currency)}
            </span>
          </div>

          <div>
            <label className="label">Qo'shiladigan summa *</label>
            <MoneyInput key={quickKey} value={amount} onChange={setAmount} autoFocus suffix={suffix} />
            {target.remaining > 0 && (
              <div className="flex gap-1.5 mt-2">
                {QUICK_SHARES.map((share, i) => (
                  <button key={share} type="button" onClick={() => pickQuick(share)}
                          className="flex-1 px-2 py-1.5 rounded-button text-xs font-medium bg-black/5 text-ink-soft hover:bg-primary/10 hover:text-primary transition">
                    {QUICK_LABELS[i]}
                  </button>
                ))}
              </div>
            )}
            {overshoot && (
              <p className="text-xs text-warning mt-2">
                Bu summa maqsaddan {formatMoney(nextSaved - target.target_amount, target.currency)} ortiq.
              </p>
            )}
          </div>

          <div>
            <label className="label">Izoh (ixtiyoriy)</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)}
                   placeholder="Masalan: iyul oyidan" />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : "Qo'shish"}
          </button>
        </div>
      </div>
    </div>
  );
}
