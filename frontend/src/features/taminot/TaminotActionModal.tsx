import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, PackagePlus, Wallet, PackageMinus, ClipboardCheck, ArrowRight } from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney, formatQty } from '@/lib/format';
import MoneyInput from '@/components/ui/MoneyInput';
import type { TaminotProduct } from '@/features/taminot/TaminotProductModal';

const UNIT_LABEL: Record<string, string> = {
  dona: 'dona', kg: 'kg', metr: 'metr', list: 'list',
};
const CURRENCY_LABEL: Record<string, string> = {
  UZS: "so'm", USD: 'dollar',
};

export type ActionKind = 'purchase' | 'payment' | 'consume' | 'stock';

const META: Record<ActionKind, {
  title: string; icon: typeof PackagePlus; tone: string; btn: string; save: string;
}> = {
  purchase: {
    title: 'Olib kelish', icon: PackagePlus, tone: 'text-primary',
    btn: 'bg-primary hover:bg-primary-700', save: "Qo'shish",
  },
  payment: {
    title: "Qarz to'lash", icon: Wallet, tone: 'text-success',
    btn: 'bg-success hover:bg-success/90', save: "To'lash",
  },
  consume: {
    title: 'Sarflash (ombordan chiqim)', icon: PackageMinus, tone: 'text-warning',
    btn: 'bg-warning hover:bg-warning/90', save: 'Sarflash',
  },
  stock: {
    title: "Qoldiqni to'g'rilash", icon: ClipboardCheck, tone: 'text-ink',
    btn: 'bg-primary hover:bg-primary-700', save: 'Saqlash',
  },
};

/**
 * Bitta mahsulot uchun amal modali.
 *   kind="purchase" — olib kelish (miqdor + birlik narxi → qarz va ombor qoldig'i oshadi)
 *   kind="payment"  — qarz to'lash (bitta summa)
 *   kind="consume"  — sarflash: faqat ombor qoldig'i kamayadi (pulga ta'siri yo'q)
 *   kind="stock"    — inventarizatsiya: ombordagi haqiqiy qoldiqni belgilash
 */
export default function TaminotActionModal({
  product, kind, onClose, onSaved,
}: {
  product: TaminotProduct;
  kind: ActionKind;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [qty, setQty] = useState(kind === 'stock' ? String(product.stock ?? 0) : '');
  const [unitPrice, setUnitPrice] = useState<number>(product.unit_price ?? 0);
  const [amount, setAmount] = useState<number>(0);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const meta = META[kind];
  const Icon = meta.icon;
  const unitLabel = UNIT_LABEL[product.unit] ?? product.unit;
  const curLabel = CURRENCY_LABEL[product.currency] ?? product.currency;
  const q = parseFloat(qty) || 0;
  const total = q * (unitPrice || 0);
  const stock = product.stock ?? 0;
  // Amaldan keyingi qoldiq — foydalanuvchi natijani oldindan ko'radi
  const nextStock = kind === 'purchase' ? stock + q
    : kind === 'consume' ? stock - q
    : kind === 'stock' ? q
    : stock;

  async function handleSave() {
    setSaving(true);
    try {
      if (kind === 'purchase') {
        if (!q || q <= 0) { toast.error('Miqdorni kiriting'); setSaving(false); return; }
        await api.post(`/taminot/products/${product.id}/purchase`, {
          qty: q, unit_price: unitPrice || 0, note: note.trim() || null,
        });
        toast.success("Olib kelish qo'shildi");
      } else if (kind === 'payment') {
        if (!amount || amount <= 0) { toast.error("To'lov summasini kiriting"); setSaving(false); return; }
        await api.post(`/taminot/products/${product.id}/payment`, {
          amount, note: note.trim() || null,
        });
        toast.success("To'lov qo'shildi");
      } else if (kind === 'consume') {
        if (!q || q <= 0) { toast.error('Miqdorni kiriting'); setSaving(false); return; }
        await api.post(`/taminot/products/${product.id}/consume`, {
          qty: q, note: note.trim() || null,
        });
        toast.success('Sarflandi');
      } else {
        if (qty.trim() === '' || q < 0) { toast.error('Qoldiqni kiriting'); setSaving(false); return; }
        await api.post(`/taminot/products/${product.id}/stock`, {
          qty: q, note: note.trim() || null,
        });
        toast.success("Qoldiq to'g'rilandi");
      }
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
            <Icon size={18} className={meta.tone} />
            {meta.title}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div className="text-sm flex items-center justify-between gap-3">
            <div className="min-w-0">
              <span className="font-medium">{product.name}</span>
              <span className="text-ink-soft"> · {unitLabel}</span>
            </div>
            {kind !== 'payment' && (
              <span className="text-xs text-ink-soft shrink-0">
                ombor: <span className="font-semibold text-ink">{formatQty(stock, unitLabel)}</span>
              </span>
            )}
          </div>

          {kind === 'purchase' && (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Miqdori *</label>
                  <input className="input" type="number" min="0" step="any" inputMode="decimal" autoFocus
                         value={qty} onChange={(e) => setQty(e.target.value)} />
                </div>
                <div>
                  <label className="label">Birlik narxi</label>
                  <MoneyInput value={unitPrice} onChange={setUnitPrice} suffix={curLabel} />
                </div>
              </div>
              <div className="rounded-button bg-primary/10 border border-primary/20 px-4 py-3 flex items-center justify-between">
                <span className="text-sm font-medium text-primary/90">Umumiy qiymat</span>
                <span className="text-lg font-bold text-primary">{formatMoney(total, product.currency)}</span>
              </div>
            </>
          )}

          {kind === 'payment' && (
            <>
              <div className="rounded-button bg-danger/10 border border-danger/20 px-4 py-3 flex items-center justify-between">
                <span className="text-sm font-medium text-danger/90">Joriy qarz</span>
                <span className="text-lg font-bold text-danger">{formatMoney(product.balance, product.currency)}</span>
              </div>
              <div>
                <label className="label">To'lov summasi *</label>
                <MoneyInput value={amount} onChange={setAmount} autoFocus suffix={curLabel} />
              </div>
            </>
          )}

          {kind === 'consume' && (
            <div>
              <label className="label">Sarflangan miqdor *</label>
              <div className="relative">
                <input className="input pr-14" type="number" min="0" step="any" inputMode="decimal" autoFocus
                       value={qty} onChange={(e) => setQty(e.target.value)} />
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-ink-soft pointer-events-none">
                  {unitLabel}
                </span>
              </div>
              <p className="text-[11px] text-ink-soft mt-1">
                Faqat ombor qoldig'i kamayadi — qarzga ta'sir qilmaydi
              </p>
            </div>
          )}

          {kind === 'stock' && (
            <div>
              <label className="label">Ombordagi haqiqiy qoldiq *</label>
              <div className="relative">
                <input className="input pr-14" type="number" min="0" step="any" inputMode="decimal" autoFocus
                       value={qty} onChange={(e) => setQty(e.target.value)} />
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-ink-soft pointer-events-none">
                  {unitLabel}
                </span>
              </div>
              <p className="text-[11px] text-ink-soft mt-1">
                Inventarizatsiya: farq alohida yozuv sifatida tarixda saqlanadi
              </p>
            </div>
          )}

          {/* Amaldan keyingi qoldiq ko'rinishi */}
          {kind !== 'payment' && q > 0 && (
            <div className="rounded-button bg-black/[0.03] border border-black/10 px-4 py-2.5 flex items-center justify-between text-sm">
              <span className="text-ink-soft">Qoldiq</span>
              <span className="flex items-center gap-2 font-semibold">
                {formatQty(stock)}
                <ArrowRight size={13} className="text-ink-soft" />
                <span className={nextStock <= (product.min_qty || 0) ? 'text-danger' : 'text-success'}>
                  {formatQty(nextStock, unitLabel)}
                </span>
              </span>
            </div>
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
                  className={`px-4 py-2 rounded-button font-medium text-white disabled:opacity-50 ${meta.btn}`}>
            {saving ? '...' : meta.save}
          </button>
        </div>
      </div>
    </div>
  );
}
