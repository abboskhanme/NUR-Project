import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import {
  X, PackagePlus, PackageMinus, ClipboardCheck, ArrowRight, Coins, Banknote,
} from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney, formatQty } from '@/lib/format';
import { cn } from '@/lib/cn';
import MoneyInput from '@/components/ui/MoneyInput';
import { CURRENCY_LABEL, UNIT_LABEL, type TaminotProduct } from '@/features/taminot/types';

export type ActionKind = 'purchase' | 'consume' | 'stock';

const META: Record<ActionKind, {
  title: string; icon: typeof PackagePlus; tone: string; btn: string; save: string;
}> = {
  purchase: {
    title: 'Olib kelish', icon: PackagePlus, tone: 'text-primary',
    btn: 'bg-primary hover:bg-primary-700', save: "Qo'shish",
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
 * Bitta mahsulot uchun tezkor amal modali.
 *   kind="purchase" — olib kelish: guruhdan faqat bitta mahsulot kerak
 *                     bo'lganda. Summa mahsulotning yetkazib beruvchisi
 *                     hisobiga (umumiy qarziga) boradi.
 *   kind="consume"  — sarflash: faqat ombor qoldig'i kamayadi (pulga ta'siri yo'q)
 *   kind="stock"    — inventarizatsiya: ombordagi haqiqiy qoldiqni belgilash
 *
 * QARZ TO'LASH bu yerda yo'q — to'lov yetkazib beruvchiga qilinadi
 * (`TaminotSupplierPaymentModal`), chunki qarz guruh darajasida yuritiladi.
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
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  // Olib kelish turi: qarzga (qarz qoldig'i oshadi) yoki naqd (darhol to'langan)
  const [payMode, setPayMode] = useState<'debt' | 'cash'>('debt');

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
          qty: q, unit_price: unitPrice || 0, payment_mode: payMode, note: note.trim() || null,
        });
        toast.success(payMode === 'cash' ? "Naqd olib kelish qo'shildi" : "Olib kelish qo'shildi");
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
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
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
            <span className="text-xs text-ink-soft shrink-0">
              ombor: <span className="font-semibold text-ink">{formatQty(stock, unitLabel)}</span>
            </span>
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

              {/* To'lov turi: qarzga yoki naqd */}
              <div>
                <label className="label">To'lov turi</label>
                <div className="grid grid-cols-2 gap-2">
                  {([
                    ['debt', 'Qarzga', Coins, 'danger'],
                    ['cash', 'Naqd', Banknote, 'success'],
                  ] as const).map(([mode, label, ModeIcon, tone]) => {
                    const active = payMode === mode;
                    return (
                      <button key={mode} type="button" onClick={() => setPayMode(mode)}
                        className={cn(
                          'flex items-center justify-center gap-1.5 px-3 py-2 rounded-button text-sm font-medium border transition',
                          !active && 'border-black/10 text-ink-soft hover:bg-black/5',
                          active && tone === 'danger' && 'border-danger/40 bg-danger/10 text-danger',
                          active && tone === 'success' && 'border-success/40 bg-success/10 text-success',
                        )}>
                        <ModeIcon size={15} /> {label}
                      </button>
                    );
                  })}
                </div>
                <p className="text-[11px] text-ink-soft mt-1">
                  {payMode === 'cash'
                    ? "Naqd — summa darhol to'langan deb yoziladi, qarz qoldig'i oshmaydi"
                    : "Qarzga — summa qarz qoldig'iga qo'shiladi"}
                </p>
              </div>

              <div className={cn('rounded-button border px-4 py-3 flex items-center justify-between',
                payMode === 'cash'
                  ? 'bg-success/10 border-success/20'
                  : 'bg-primary/10 border-primary/20')}>
                <span className={cn('text-sm font-medium',
                  payMode === 'cash' ? 'text-success/90' : 'text-primary/90')}>
                  {payMode === 'cash' ? "Naqd to'lanadi" : "Qarzga qo'shiladi"}
                </span>
                <span className={cn('text-lg font-bold',
                  payMode === 'cash' ? 'text-success' : 'text-primary')}>
                  {formatMoney(total, product.currency)}
                </span>
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
          {q > 0 && (
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
