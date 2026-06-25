import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, Banknote } from 'lucide-react';

import { api } from '@/api/client';
import { formatUSD } from '@/lib/format';

const today = () => new Date().toISOString().slice(0, 10);

// Minglarni probel bilan formatlaymiz: 2000000 -> "2 000 000"
function formatAmount(s: string): string {
  const cleaned = s.replace(/[^\d.]/g, '');
  const firstDot = cleaned.indexOf('.');
  const intPart = (firstDot === -1 ? cleaned : cleaned.slice(0, firstDot)).replace(/^0+(?=\d)/, '');
  const intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  if (firstDot === -1) return intFmt;
  const decPart = cleaned.slice(firstDot + 1).replace(/\./g, '').slice(0, 2);
  return `${intFmt || '0'}.${decPart}`;
}
const toNum = (s: string) => parseFloat(s.replace(/[^\d.]/g, '')) || 0;

export default function GaznaTransferModal({
  usdBalance, onClose, onSaved,
}: { usdBalance?: number; onClose: () => void; onSaved: () => void }) {
  const [date, setDate] = useState(today());
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const amt = toNum(amount);
  const overBalance = usdBalance != null && amt > usdBalance;

  async function handleSave() {
    if (!amt || amt <= 0) { toast.error("To'g'ri summa kiriting"); return; }
    if (overBalance) { toast.error("Summa USD balansidan ortiq"); return; }
    setSaving(true);
    try {
      await api.post('/finance/transfer-to-gazna', {
        amount: amt,
        tx_date: date,
        note: note || null,
      });
      toast.success("G'aznaga o'tkazildi");
      onSaved();
      onClose();
    } catch (e: any) {
      // FastAPI 422 detail'i obyektlar massivi bo'lishi mumkin — toast'ga faqat
      // matn berishimiz kerak (aks holda React render'da yiqiladi → oq ekran).
      const d = e?.response?.data?.detail;
      const msg = typeof d === 'string' ? d
        : Array.isArray(d) ? (d[0]?.msg ?? 'Xatolik')
        : 'Xatolik';
      toast.error(msg);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2">
            <Banknote size={18} className="text-warning" /> G'aznaga o'tkazish
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          <p className="text-sm text-ink-soft">
            USD kassadan naqd dollar zaxirasiga (G'azna) o'tkaziladi. Summa USD balansidan
            ayriladi va G'aznaga qo'shiladi.
          </p>

          {usdBalance != null && (
            <div className="text-sm bg-black/5 rounded-button px-3 py-2">
              Joriy USD balans: <span className="font-semibold">{formatUSD(usdBalance)}</span>
            </div>
          )}

          {overBalance && (
            <div className="text-sm text-danger bg-danger/10 rounded-button px-3 py-2">
              Summa USD balansidan ortiq — ko'pi bilan {formatUSD(usdBalance)} o'tkazish mumkin.
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Summa (USD) *</label>
              <input type="text" inputMode="decimal" className="input" placeholder="0"
                     value={amount} onChange={(e) => setAmount(formatAmount(e.target.value))} />
            </div>
            <div>
              <label className="label">Sana</label>
              <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
            </div>
          </div>

          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)}
                      placeholder="USD → G'azna o'tkazmasi" />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor qilish</button>
          <button onClick={handleSave} disabled={saving || overBalance} className="btn-primary disabled:opacity-50">
            {saving ? 'O\'tkazilmoqda…' : "O'tkazish"}
          </button>
        </div>
      </div>
    </div>
  );
}
