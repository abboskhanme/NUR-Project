import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import MoneyInput from '@/components/ui/MoneyInput';

export interface DebtProduct {
  id: string;
  name: string;
  unit: string;
  unit_price: number;
  currency: string;
  supplier?: string | null;
  note?: string | null;
  total_purchased: number;
  total_paid: number;
  balance: number;
  last_purchase_at?: string | null;
  tx_count: number;
}

const UNITS = ['dona', 'kg', 'metr', 'list'];
const CURRENCIES = ['UZS', 'USD'];

export default function DebtProductModal({
  product, onClose, onSaved,
}: { product?: DebtProduct | null; onClose: () => void; onSaved: () => void }) {
  const { t } = useTranslation();
  const editing = !!product;
  const [name, setName] = useState(product?.name ?? '');
  const [unit, setUnit] = useState(product?.unit ?? 'dona');
  const [unitPrice, setUnitPrice] = useState<number>(product?.unit_price ?? 0);
  const [currency, setCurrency] = useState(product?.currency ?? 'UZS');
  const [supplier, setSupplier] = useState(product?.supplier ?? '');
  const [note, setNote] = useState(product?.note ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error(t('debts.product.name')); return; }
    setSaving(true);
    try {
      const payload = {
        name: name.trim(),
        unit,
        unit_price: unitPrice || 0,
        currency,
        supplier: supplier.trim() || null,
        note: note.trim() || null,
      };
      if (editing) await api.patch(`/debts/products/${product!.id}`, payload);
      else await api.post('/debts/products', payload);
      toast.success(t('debts.toast.saved'));
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
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{editing ? t('debts.product.edit') : t('debts.product.new')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <label className="label">{t('debts.product.name')} *</label>
            <input className="input" placeholder={t('debts.product.namePlaceholder')}
                   value={name} onChange={(e) => setName(e.target.value)} autoFocus />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">{t('debts.product.unit')}</label>
              <select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}>
                {UNITS.map((u) => <option key={u} value={u}>{t(`debts.units.${u}`)}</option>)}
              </select>
            </div>
            <div>
              <label className="label">{t('debts.product.currency')}</label>
              <select className="input" value={currency} onChange={(e) => setCurrency(e.target.value)}>
                {CURRENCIES.map((c) => <option key={c} value={c}>{t(`debts.currency.${c}`)}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className="label">{t('debts.product.unitPrice')}</label>
            <MoneyInput value={unitPrice} onChange={setUnitPrice}
                        suffix={t(`debts.currency.${currency}`)} />
          </div>

          <div>
            <label className="label">{t('debts.product.supplier')}</label>
            <input className="input" placeholder={t('debts.product.supplierPlaceholder')}
                   value={supplier} onChange={(e) => setSupplier(e.target.value)} />
          </div>

          <div>
            <label className="label">{t('debts.product.note')}</label>
            <textarea className="input min-h-[60px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : t('actions.save', { defaultValue: 'Saqlash' })}
          </button>
        </div>
      </div>
    </div>
  );
}
