import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import MoneyInput from '@/components/ui/MoneyInput';
import DateInput from '@/components/ui/DateInput';

export const TARGET_CURRENCY: Record<string, string> = {
  UZS: "so'm",
  USD: 'dollar',
};
const CURRENCIES = ['UZS', 'USD'];

export interface Target {
  id: string;
  name: string;
  target_amount: number;
  currency: string;
  deadline?: string | null;
  note?: string | null;
  created_at: string;
  saved_amount: number;
  remaining: number;
  progress: number;
  is_completed: boolean;
  last_contribution_at?: string | null;
  contribution_count: number;
}

/** Maqsad yaratish / tahrirlash modali. */
export default function TargetModal({
  target, onClose, onSaved,
}: { target?: Target | null; onClose: () => void; onSaved: () => void }) {
  const editing = !!target;
  const [name, setName] = useState(target?.name ?? '');
  const [amount, setAmount] = useState<number>(target?.target_amount ?? 0);
  const [currency, setCurrency] = useState(target?.currency ?? 'UZS');
  const [deadline, setDeadline] = useState(target?.deadline ?? '');
  const [note, setNote] = useState(target?.note ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error('Nomini kiriting'); return; }
    if (!amount || amount <= 0) { toast.error("Maqsad summasi 0 dan katta bo'lishi kerak"); return; }
    // Tahrirlashda yig'ilgan summadan past maqsad qo'yish mantiqsiz emas, lekin
    // foydalanuvchini ogohlantirmasdan progress darhol 100% bo'lib qoladi.
    setSaving(true);
    try {
      const payload = {
        name: name.trim(),
        target_amount: amount,
        currency,
        deadline: deadline || null,
        note: note.trim() || null,
      };
      if (editing) await api.patch(`/targets/${target!.id}`, payload);
      else await api.post('/targets', payload);
      toast.success('Saqlandi');
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
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{editing ? 'Maqsadni tahrirlash' : 'Yangi maqsad'}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" placeholder="Masalan: Yangi stanok olish"
                   value={name} onChange={(e) => setName(e.target.value)} autoFocus />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Maqsad summasi *</label>
              <MoneyInput value={amount} onChange={setAmount}
                          suffix={TARGET_CURRENCY[String(currency)]} />
            </div>
            <div>
              <label className="label">Valyuta</label>
              <select className="input" value={currency} onChange={(e) => setCurrency(e.target.value)}>
                {CURRENCIES.map((c) => <option key={c} value={c}>{TARGET_CURRENCY[String(c)]}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className="label">Muddat (ixtiyoriy)</label>
            <DateInput value={deadline ?? ''} onChange={setDeadline} placeholder="kun.oy.yil" />
          </div>

          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[60px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
