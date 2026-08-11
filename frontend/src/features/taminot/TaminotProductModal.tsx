import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import MoneyInput from '@/components/ui/MoneyInput';
import {
  CURRENCY_LABEL, UNIT_LABEL,
  type TaminotProduct, type TaminotSupplier,
} from '@/features/taminot/types';

// Eski importlar buzilmasligi uchun qayta eksport
export type { TaminotProduct, StockStatus } from '@/features/taminot/types';

const UNITS = ['dona', 'kg', 'metr', 'list'];
const CURRENCIES = ['UZS', 'USD'];

/**
 * Mahsulot yaratish/tahrirlash modali.
 *   - `scope` (ichki/tashqi) yangi mahsulot uchun majburiy.
 *   - `supplierId` berilsa — mahsulot o'sha yetkazib beruvchiga qo'shiladi va
 *     tanlov ko'rsatilmaydi (yetkazib beruvchi ichidan chaqirilganda shunday).
 *   - `product` berilsa — tahrirlash rejimi; bunda mahsulotni boshqa yetkazib
 *     beruvchiga ko'chirish ham mumkin (tarixi bilan birga ko'chadi).
 */
export default function TaminotProductModal({
  scope, supplierId, product, onClose, onSaved,
}: {
  scope: string;
  supplierId?: string;
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
  const [note, setNote] = useState(product?.note ?? '');
  const [supplier, setSupplier] = useState(product?.supplier_id ?? supplierId ?? '');
  const [saving, setSaving] = useState(false);

  // Yetkazib beruvchi tashqaridan berilgan bo'lsa ro'yxat kerak emas
  const needsPicker = !supplierId;
  const suppliersQ = useQuery<TaminotSupplier[]>({
    queryKey: ['taminot-suppliers', scope],
    queryFn: () => api.get('/taminot/suppliers', { params: { scope } }).then((r) => r.data),
    enabled: needsPicker,
  });
  const suppliers = suppliersQ.data ?? [];

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error('Nomini kiriting'); return; }
    if (!supplier) { toast.error('Yetkazib beruvchini tanlang'); return; }
    setSaving(true);
    try {
      const payload = {
        scope,
        supplier_id: supplier,
        name: name.trim(),
        unit,
        unit_price: unitPrice || 0,
        currency,
        min_qty: Math.max(0, parseFloat(minQty) || 0),
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
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md max-h-[92vh] overflow-y-auto"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card">
          <h3 className="font-semibold">{editing ? 'Tahrirlash' : 'Yangi mahsulot'}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" placeholder="Masalan: Profil truba 40x40"
                   value={name} onChange={(e) => setName(e.target.value)} autoFocus />
          </div>

          {/* Yetkazib beruvchi — mahsulot puli o'sha joyning hisobiga boradi */}
          {needsPicker && (
            <div>
              <label className="label">Yetkazib beruvchi *</label>
              <select className="input" value={supplier} onChange={(e) => setSupplier(e.target.value)}>
                <option value="">— tanlang —</option>
                {suppliers.map((s) => (
                  <option key={s.id} value={s.id}>{s.name}</option>
                ))}
              </select>
              {editing && (
                <p className="text-[11px] text-ink-soft mt-1">
                  Boshqa joyga ko'chirilsa, mahsulotning butun tarixi ham o'sha
                  joyning hisobiga o'tadi
                </p>
              )}
            </div>
          )}

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
            <label className="label">Izoh</label>
            <textarea className="input min-h-[60px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 sticky bottom-0 bg-card">
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
