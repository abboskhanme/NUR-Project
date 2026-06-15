import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, PackagePlus, Wallet } from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney } from '@/lib/format';
import MoneyInput from '@/components/ui/MoneyInput';
import type { DebtProduct } from '@/features/debts/DebtProductModal';

/**
 * Bitta mahsulot uchun kichik amal modali.
 *   kind="purchase" — olib kelish (miqdor + birlik narxi -> umumiy qiymat)
 *   kind="payment"  — qarz to'lash (bitta summa input)
 */
export default function DebtActionModal({
  product, kind, onClose, onSaved,
}: {
  product: DebtProduct;
  kind: 'purchase' | 'payment';
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const [qty, setQty] = useState('');
  const [unitPrice, setUnitPrice] = useState<number>(product.unit_price ?? 0);
  const [amount, setAmount] = useState<number>(0);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const isPurchase = kind === 'purchase';
  const isProduct = product.debt_type === 'product';
  const total = (parseFloat(qty) || 0) * (unitPrice || 0);

  async function handleSave() {
    setSaving(true);
    try {
      if (isPurchase && isProduct) {
        const q = parseFloat(qty);
        if (!q || q <= 0) { toast.error(t('debts.purchase.qty')); setSaving(false); return; }
        await api.post(`/debts/products/${product.id}/purchase`, {
          qty: q,
          unit_price: unitPrice || 0,
          note: note.trim() || null,
        });
        toast.success(t('debts.purchase.success'));
      } else if (isPurchase) {
        if (!amount || amount <= 0) { toast.error(t('debts.addDebt.amount')); setSaving(false); return; }
        await api.post(`/debts/products/${product.id}/purchase`, {
          amount,
          note: note.trim() || null,
        });
        toast.success(t('debts.purchase.success'));
      } else {
        if (!amount || amount <= 0) { toast.error(t('debts.pay.amount')); setSaving(false); return; }
        await api.post(`/debts/products/${product.id}/payment`, {
          amount,
          note: note.trim() || null,
        });
        toast.success(t('debts.pay.success'));
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('debts.toast.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2">
            {isPurchase ? <PackagePlus size={18} className="text-primary" /> : <Wallet size={18} className="text-success" />}
            {isPurchase ? (isProduct ? t('debts.purchase.title') : t('debts.addDebt.title')) : t('debts.pay.title')}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div className="text-sm">
            <span className="font-medium">{product.name}</span>
            {isProduct && (
              <span className="text-ink-soft"> · {t(`debts.units.${product.unit}`, { defaultValue: product.unit })}</span>
            )}
          </div>

          {isPurchase && isProduct ? (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">{t('debts.purchase.qty')} *</label>
                  <input className="input" type="number" min="0" inputMode="decimal" autoFocus
                         value={qty} onChange={(e) => setQty(e.target.value)} />
                </div>
                <div>
                  <label className="label">{t('debts.purchase.unitPrice')}</label>
                  <MoneyInput value={unitPrice} onChange={setUnitPrice}
                              suffix={t(`debts.currency.${product.currency}`, { defaultValue: product.currency })} />
                </div>
              </div>
              <div className="rounded-button bg-primary/10 border border-primary/20 px-4 py-3 flex items-center justify-between">
                <span className="text-sm font-medium text-primary/90">{t('debts.purchase.total')}</span>
                <span className="text-lg font-bold text-primary">{formatMoney(total, product.currency)}</span>
              </div>
            </>
          ) : isPurchase ? (
            <div>
              <label className="label">{t('debts.addDebt.amount')} *</label>
              <MoneyInput value={amount} onChange={setAmount} autoFocus
                          suffix={t(`debts.currency.${product.currency}`, { defaultValue: product.currency })} />
            </div>
          ) : (
            <>
              <div className="rounded-button bg-danger/10 border border-danger/20 px-4 py-3 flex items-center justify-between">
                <span className="text-sm font-medium text-danger/90">{t('debts.pay.currentDebt')}</span>
                <span className="text-lg font-bold text-danger">{formatMoney(product.balance, product.currency)}</span>
              </div>
              <div>
                <label className="label">{t('debts.pay.amount')} *</label>
                <MoneyInput value={amount} onChange={setAmount} autoFocus
                            suffix={t(`debts.currency.${product.currency}`, { defaultValue: product.currency })} />
              </div>
            </>
          )}

          <div>
            <label className="label">{isPurchase ? t('debts.purchase.note') : t('debts.pay.note')}</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving}
                  className={`px-4 py-2 rounded-button font-medium text-white disabled:opacity-50 ${
                    isPurchase ? 'bg-primary hover:bg-primary-700' : 'bg-success hover:bg-success/90'}`}>
            {saving ? '...' : isPurchase ? (isProduct ? t('debts.purchase.submit') : t('debts.addDebt.submit')) : t('debts.pay.submit')}
          </button>
        </div>
      </div>
    </div>
  );
}
