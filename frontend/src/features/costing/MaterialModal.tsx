import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X, PackagePlus } from 'lucide-react';

import { api } from '@/api/client';
import MoneyInput from '@/components/ui/MoneyInput';
import type { MaterialOption } from '@/features/costing/types';
import { CURRENCY_LABEL, UNITS, UNIT_LABEL } from '@/features/costing/types';

/**
 * Tannarx katalogiga material qo'shish / tahrirlash.
 *
 * Birlik ixtiyoriy. Narx bu yerda belgilanadi va kalkulyatsiyalarga JONLI
 * uzatiladi — narxni o'zgartirsangiz, shu materialni ishlatgan mahsulotlar
 * tannarxi o'zi yangilanadi.
 */
export default function MaterialModal({ material, onClose, onSaved }: {
  material?: MaterialOption | null;
  onClose: () => void;
  onSaved: (m: MaterialOption) => void;
}) {
  const editing = !!material;
  const [name, setName] = useState(material?.name ?? '');
  const [unit, setUnit] = useState<string>(material?.unit ?? '');
  const [price, setPrice] = useState<number>(material?.unit_price ?? 0);
  const [currency, setCurrency] = useState<'UZS' | 'USD'>(
    material?.currency === 'USD' ? 'USD' : 'UZS',
  );
  const [active, setActive] = useState(material?.is_active ?? true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (name.trim().length < 2) { toast.error('Material nomini kiriting'); return; }
    setSaving(true);
    try {
      const body = {
        name: name.trim(),
        unit: unit || null,
        unit_price: price || 0,
        currency,
        is_active: active,
      };
      const { data } = editing
        ? await api.patch<MaterialOption>(`/costing/materials/${material!.id}`, body)
        : await api.post<MaterialOption>('/costing/materials', body);
      toast.success(editing ? 'Saqlandi' : `«${data.name}» qo'shildi`);
      onSaved(data);
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-sm max-h-[90vh] overflow-y-auto"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card">
          <h3 className="font-semibold flex items-center gap-2">
            <PackagePlus size={18} className="text-primary" />
            {editing ? 'Materialni tahrirlash' : 'Yangi material'}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" autoFocus placeholder="Material nomi"
                   value={name} onChange={(e) => setName(e.target.value)} />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Birlik</label>
              <select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}>
                <option value="">— belgilanmagan —</option>
                {UNITS.map((u) => <option key={u} value={u}>{UNIT_LABEL[u]}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Valyuta</label>
              <select className="input" value={currency}
                      onChange={(e) => setCurrency(e.target.value as 'UZS' | 'USD')}>
                {(['UZS', 'USD'] as const).map((c) => (
                  <option key={c} value={c}>{CURRENCY_LABEL[c]}</option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="label">Birlik narxi</label>
            <MoneyInput value={price} onChange={setPrice} suffix={CURRENCY_LABEL[currency]} />
            <p className="text-[11px] text-ink-soft mt-1">
              Narx o‘zgarsa — shu materialni ishlatgan mahsulotlar tannarxi o‘zi yangilanadi
            </p>
          </div>

          {editing && (
            <label className="flex items-center gap-2 text-sm cursor-pointer select-none pt-1">
              <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} />
              Faol (ro‘yxatlarda ko‘rinadi)
            </label>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 sticky bottom-0 bg-card">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : editing ? 'Saqlash' : "Qo'shish"}
          </button>
        </div>
      </div>
    </div>
  );
}
