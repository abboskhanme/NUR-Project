import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import MoneyInput from '@/components/ui/MoneyInput';

const UNIT_LABEL: Record<string, string> = {
  dona: 'dona', kg: 'kg', metr: 'metr', list: 'list',
};
const CURRENCY_LABEL: Record<string, string> = {
  UZS: "so'm", USD: 'dollar',
};

/** Ombor qoldig'i holati: harakat yo'q / tugagan / kam qoldi / yetarli */
export type StockStatus = 'none' | 'out' | 'low' | 'ok';

export interface TaminotProduct {
  id: string;
  scope: string;
  name: string;
  unit: string;
  unit_price: number;
  currency: string;
  min_qty: number;
  supplier?: string | null;
  note?: string | null;
  total_purchased: number;
  total_paid: number;
  balance: number;
  last_purchase_at?: string | null;
  tx_count: number;
  // Ombor qoldig'i (miqdor bo'yicha)
  in_qty: number;
  out_qty: number;
  adjust_qty: number;
  stock: number;
  stock_value: number;
  stock_status: StockStatus;
  last_consume_at?: string | null;
}

const UNITS = ['dona', 'kg', 'metr', 'list'];
const CURRENCIES = ['UZS', 'USD'];

/**
 * Mahsulot yaratish/tahrirlash modali.
 *   - `scope` (ichki/tashqi) yangi mahsulot uchun majburiy.
 *   - `product` berilsa — tahrirlash rejimi.
 */
export default function TaminotProductModal({
  scope, product, onClose, onSaved,
}: {
  scope: string;
  product?: TaminotProduct | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const editing = !!product;
  const [name, setName] = useState(product?.name ?? '');
  const [unit, setUnit] = useState(product?.unit ?? 'dona');
  const [unitPrice, setUnitPrice] = useState<number>(product?.unit_price ?? 0);
  const [currency, setCurrency] = useState(product?.currency ?? 'UZS');
  const [minQty, setMinQty] = useState(product?.min_qty ? String(product.min_qty) : '');
  const [supplier, setSupplier] = useState(product?.supplier ?? '');
  const [note, setNote] = useState(product?.note ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error('Nomi'); return; }
    setSaving(true);
    try {
      const payload = {
        scope,
        name: name.trim(),
        unit,
        unit_price: unitPrice || 0,
        currency,
        min_qty: Math.max(0, parseFloat(minQty) || 0),
        supplier: supplier.trim() || null,
        note: note.trim() || null,
      };
      if (editing) await api.patch(`/taminot/products/${product!.id}`, payload);
      else await api.post('/taminot/products', payload);
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
          <h3 className="font-semibold">{editing ? 'Tahrirlash' : 'Yangi mahsulot'}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" placeholder="Masalan: Profil truba 40x40"
                   value={name} onChange={(e) => setName(e.target.value)} autoFocus />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Birlik</label>
              <select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}>
                {UNITS.map((u) => <option key={u} value={u}>{UNIT_LABEL[u]}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Valyuta</label>
              <select className="input" value={currency} onChange={(e) => setCurrency(e.target.value)}>
                {CURRENCIES.map((c) => <option key={c} value={c}>{CURRENCY_LABEL[c]}</option>)}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Birlik narxi</label>
              <MoneyInput value={unitPrice} onChange={setUnitPrice} suffix={CURRENCY_LABEL[currency]} />
            </div>
            <div>
              <label className="label">Kam qoldi chegarasi</label>
              <div className="relative">
                <input className="input pr-14" type="number" min="0" step="any" inputMode="decimal"
                       placeholder="0" value={minQty} onChange={(e) => setMinQty(e.target.value)} />
                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-ink-soft pointer-events-none">
                  {UNIT_LABEL[unit] ?? unit}
                </span>
              </div>
              <p className="text-[11px] text-ink-soft mt-1">
                Qoldiq shu miqdordan pastga tushsa — qizil bilan ogohlantiriladi
              </p>
            </div>
          </div>

          <div>
            <label className="label">Taʼminotchi</label>
            <input className="input" placeholder="Taʼminotchi ismi yoki firma"
                   value={supplier} onChange={(e) => setSupplier(e.target.value)} />
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
