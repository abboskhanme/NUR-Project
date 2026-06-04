import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';

const METHODS = [
  { value: 'cash', label: 'Naqd' },
  { value: 'card', label: 'Karta' },
  { value: 'transfer', label: 'O\'tkazma' },
];

const today = () => new Date().toISOString().slice(0, 10);

// Yozilayotganda mingliklarni bo'shliq bilan ajratib ko'rsatamiz: 2000000 -> "2 000 000"
function formatAmount(s: string): string {
  const cleaned = s.replace(/[^\d.]/g, '');
  const firstDot = cleaned.indexOf('.');
  let intPart = (firstDot === -1 ? cleaned : cleaned.slice(0, firstDot)).replace(/^0+(?=\d)/, '');
  const intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  if (firstDot === -1) return intFmt;
  const decPart = cleaned.slice(firstDot + 1).replace(/\./g, '').slice(0, 2);
  return `${intFmt || '0'}.${decPart}`;
}

export default function PaymentModal({
  orderId,
  onClose,
  onSaved,
}: {
  orderId: string;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [date, setDate] = useState(today());
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('UZS');
  const [method, setMethod] = useState('cash');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  // Buyurtma qoldig'i va kursi — limitni tekshirish uchun
  const [order, setOrder] = useState<{ balance_uzs: string; exchange_rate: string } | null>(null);
  // "To'liq to'lash" bosilganmi — saqlashda aniq UZS ekvivalentini yuborish uchun
  const [isFull, setIsFull] = useState(false);

  useEffect(() => {
    api.get(`/orders/${orderId}`).then((r) => setOrder(r.data)).catch(() => {});
  }, [orderId]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const balance = order ? Math.max(0, parseFloat(order.balance_uzs) || 0) : null;
  const rate = order ? parseFloat(order.exchange_rate) || 0 : 0;
  const amtNum = parseFloat(amount.replace(/[^\d.]/g, '')) || 0;
  // Kiritilgan summaning UZS ekvivalenti
  const amtUzs = currency === 'USD' ? amtNum * rate : amtNum;
  const exceeds = balance != null && !isFull && amtUzs > balance + 0.01;

  function payFull() {
    if (balance == null) return;
    const v = currency === 'USD' && rate > 0
      ? Math.round((balance / rate) * 100) / 100
      : balance;
    setAmount(formatAmount(String(v)));
    setIsFull(true);
  }

  async function handleSave() {
    const amt = parseFloat(amount.replace(/[^\d.]/g, ''));
    if (!amt || amt <= 0) { toast.error('To\'g\'ri summa kiriting'); return; }
    if (exceeds) {
      toast.error(`To'lov qoldiqdan oshib ketdi — qoldiq: ${formatUZS(balance!)}`);
      return;
    }
    setSaving(true);
    try {
      await api.post(`/orders/${orderId}/payments`, {
        date, amount: amt, currency, method, note: note || null,
        // To'liq to'lashda UZS ekvivalenti aniq qoldiqqa teng bo'ladi (kurs yaxlitlash xatosiz)
        ...(isFull && balance != null ? { amount_uzs_equiv: balance } : {}),
      });
      toast.success('To\'lov qo\'shildi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">To'lov qo'shish</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>
        <div className="p-5 space-y-3">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Sana</label>
              <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
            </div>
            <div>
              <label className="label">Valyuta</label>
              <select className="input" value={currency}
                      onChange={(e) => { setCurrency(e.target.value); setIsFull(false); setAmount(''); }}>
                <option value="UZS">UZS</option>
                <option value="USD">USD</option>
              </select>
            </div>
          </div>
          <div>
            <label className="label">Summa *</label>
            <input type="text" inputMode="decimal"
                   className={'input ' + (exceeds ? '!border-danger' : '')} placeholder="0"
                   value={amount}
                   onChange={(e) => { setAmount(formatAmount(e.target.value)); setIsFull(false); }} />
            <div className="flex items-center justify-between mt-1">
              <span className="text-xs text-ink-soft">
                {balance != null ? <>Qoldiq: <b>{formatUZS(balance)}</b></> : ' '}
              </span>
              {balance != null && balance > 0 && (
                <button type="button" onClick={payFull}
                        className="text-xs font-medium text-primary hover:underline">
                  To'liq to'lash
                </button>
              )}
            </div>
            {exceeds && (
              <p className="text-xs text-danger mt-0.5">
                Summa qoldiqdan oshib ketdi — maksimal {formatUZS(balance!)}
              </p>
            )}
          </div>
          <div>
            <label className="label">To'lov usuli</label>
            <select className="input" value={method} onChange={(e) => setMethod(e.target.value)}>
              {METHODS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}
            </select>
          </div>
          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>
        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor</button>
          <button onClick={handleSave} disabled={saving || exceeds} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
