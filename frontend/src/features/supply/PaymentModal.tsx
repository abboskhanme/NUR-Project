import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';
import { formatAmount, toNum, today } from './money';

interface VendorLite { id: string; name: string; open_debt?: string }

export default function PaymentModal({
  vendors, fixedVendorId, initialVendorId, onClose, onSaved,
}: {
  vendors: VendorLite[];
  fixedVendorId?: string;
  initialVendorId?: string;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [vendorId, setVendorId] = useState(fixedVendorId ?? initialVendorId ?? '');
  const [date, setDate] = useState(today());
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const balanceQ = useQuery({
    queryKey: ['vendor-balance', vendorId],
    queryFn: () => api.get(`/supply/vendors/${vendorId}/balance`).then((r) => r.data),
    enabled: !!vendorId,
  });
  const debt = Number(balanceQ.data?.open_debt ?? 0);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!vendorId) { toast.error('Taminotchini tanlang'); return; }
    if (toNum(amount) <= 0) { toast.error('Summani kiriting'); return; }
    setSaving(true);
    try {
      await api.post('/supply/payments', {
        vendor_id: vendorId, date, amount: toNum(amount), note: note || null,
      });
      toast.success("Qarz to'lovi saqlandi");
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
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">Qarz to'lash</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          {!fixedVendorId && (
            <div>
              <label className="label">Taminotchi *</label>
              <select className="input" value={vendorId} onChange={(e) => setVendorId(e.target.value)}>
                <option value="">— Tanlang —</option>
                {vendors.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
              </select>
            </div>
          )}

          <div className="p-3 rounded-button bg-warning/5 border border-warning/20">
            <div className="text-sm text-ink-soft">Joriy qarz</div>
            <div className="text-xl font-bold mt-0.5">
              {!vendorId ? '—' : balanceQ.isLoading ? '…' : formatUZS(debt)}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Sana</label>
              <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
            </div>
            <div>
              <label className="label">Summa *</label>
              <input className="input" inputMode="decimal" value={amount}
                     onChange={(e) => setAmount(formatAmount(e.target.value))} placeholder="0" />
            </div>
          </div>

          {vendorId && debt > 0 && (
            <button type="button"
                    onClick={() => setAmount(formatAmount(String(Math.round(debt))))}
                    className="text-xs text-primary hover:underline">
              {`To'liq qarzni qo'yish (${formatUZS(debt)})`}
            </button>
          )}

          <div>
            <label className="label">Izoh</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
          <p className="text-xs text-ink-soft">
            To'lov eng eski qarzlardan boshlab avtomatik so'ndiriladi.
          </p>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : "To'lash"}
          </button>
        </div>
      </div>
    </div>
  );
}
