import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, Wallet } from 'lucide-react';

import { api } from '@/api/client';
import MoneyInput from '@/components/ui/MoneyInput';
import { formatMoney } from '@/lib/format';
import { cn } from '@/lib/cn';
import { CURRENCY_LABEL, type TaminotSupplier } from '@/features/taminot/types';

/**
 * Yetkazib beruvchiga qarz to'lash.
 *
 * To'lov mahsulotga emas, joyga qilinadi — 15 xil mahsulot olingan bo'lsa ham
 * to'lov bitta. Bir joyda ham so'm, ham dollar hisobi bo'lishi mumkin, shuning
 * uchun valyuta tanlanadi va ular hech qachon qo'shilmaydi.
 */
export default function TaminotSupplierPaymentModal({
  supplier, onClose, onSaved,
}: {
  supplier: TaminotSupplier;
  onClose: () => void;
  onSaved: () => void;
}) {
  // Qarzi bor valyutalar tepada — odatda to'lov aynan shularga qilinadi
  const withDebt = supplier.totals.filter((t) => t.balance > 0);
  const options = (withDebt.length ? withDebt : supplier.totals).map((t) => t.currency);
  const [currency, setCurrency] = useState(options[0] ?? 'UZS');
  const [amount, setAmount] = useState<number>(0);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const current = supplier.totals.find((t) => t.currency === currency);
  const balance = current?.balance ?? 0;

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!amount || amount <= 0) { toast.error("To'lov summasini kiriting"); return; }
    setSaving(true);
    try {
      await api.post(`/taminot/suppliers/${supplier.id}/payment`, {
        amount, currency, note: note.trim() || null,
      });
      toast.success("To'lov yozildi");
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2">
            <Wallet size={18} className="text-success" /> Qarz to'lash
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div className="text-sm">
            <span className="font-medium">{supplier.name}</span>
            <span className="text-ink-soft"> · {supplier.product_count} ta mahsulot</span>
          </div>

          {/* Valyuta — faqat bir nechtasi bo'lsa tanlov chiqadi */}
          {options.length > 1 && (
            <div>
              <label className="label">Valyuta</label>
              <div className="grid grid-cols-2 gap-2">
                {options.map((c) => (
                  <button key={c} type="button" onClick={() => setCurrency(c)}
                    className={cn('px-3 py-2 rounded-button text-sm font-medium border transition',
                      currency === c
                        ? 'border-primary bg-primary/10 text-primary'
                        : 'border-black/10 text-ink-soft hover:bg-black/5')}>
                    {CURRENCY_LABEL[c] ?? c}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className="rounded-button bg-danger/10 border border-danger/20 px-4 py-3 flex items-center justify-between">
            <span className="text-sm font-medium text-danger/90">Joriy qarz</span>
            <span className="text-lg font-bold text-danger">{formatMoney(balance, currency)}</span>
          </div>

          <div>
            <label className="label">To'lov summasi *</label>
            <MoneyInput value={amount} onChange={setAmount} autoFocus
                        suffix={CURRENCY_LABEL[currency] ?? currency} />
            {balance > 0 && (
              <button type="button" onClick={() => setAmount(balance)}
                      className="text-xs text-primary hover:underline mt-1">
                Butun qarzni to'lash
              </button>
            )}
          </div>

          {amount > balance && balance > 0 && (
            <p className="text-[11px] text-warning">
              Summa qarzdan ko'p — ortiqchasi oldindan to'lov bo'lib qoladi
            </p>
          )}

          <div>
            <label className="label">Izoh (ixtiyoriy)</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving}
                  className="px-4 py-2 rounded-button font-medium text-white bg-success hover:bg-success/90 disabled:opacity-50">
            {saving ? '...' : "To'lash"}
          </button>
        </div>
      </div>
    </div>
  );
}
