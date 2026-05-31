import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';

export type ProductType = 'main' | 'additional';

export interface ProductFull {
  id: string;
  product_type: ProductType;
  model?: string | null;
  kvm?: number | null;
  name?: string | null;
  unit?: string | null;
  sku?: string | null;
  description?: string | null;
  base_price_usd: string;
  status: string;
}

const UNITS = ['dona', 'metr', 'komplekt', 'kg', 'litr'];

const num = (s: string) => {
  const n = parseFloat(s); return Number.isNaN(n) ? 0 : n;
};

export default function ProductModal({
  product,
  defaultType,
  onClose,
  onSaved,
}: {
  product: ProductFull | null;
  defaultType: ProductType;
  onClose: () => void;
  onSaved: () => void;
}) {
  const isCreate = product === null;
  const type: ProductType = product?.product_type ?? defaultType;

  const [model, setModel] = useState(product?.model ?? '');
  const [kvm, setKvm] = useState(product?.kvm != null ? String(product.kvm) : '');
  const [name, setName] = useState(product?.name ?? '');
  const [unit, setUnit] = useState(product?.unit ?? 'dona');
  const [price, setPrice] = useState(product ? String(num(product.base_price_usd)) : '');
  const [description, setDescription] = useState(product?.description ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (type === 'main' && !model.trim()) { toast.error('Model majburiy'); return; }
    if (type === 'additional' && !name.trim()) { toast.error('Mahsulot nomi majburiy'); return; }

    const body: Record<string, unknown> = {
      product_type: type,
      base_price_usd: num(price),
      description: description.trim() || null,
    };
    if (type === 'main') {
      body.model = model.trim();
      body.kvm = kvm.trim() ? parseInt(kvm, 10) : null;
      body.name = null;
      body.unit = null;
    } else {
      body.name = name.trim();
      body.unit = unit || null;
      body.model = null;
      body.kvm = null;
    }

    setSaving(true);
    try {
      if (isCreate) {
        await api.post('/products', body);
        toast.success('Mahsulot qo\'shildi');
      } else {
        await api.patch(`/products/${product!.id}`, body);
        toast.success('Yangilandi');
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  const titleType = type === 'main' ? 'kotyol' : 'qo\'shimcha mahsulot';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[92vh] overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">
            {isCreate ? `Yangi ${titleType}` : `Tahrirlash — ${titleType}`}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {type === 'main' ? (
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Model *</label>
                <input className="input" placeholder="PREMIUM 3 / ULTRA ..." value={model}
                       onChange={(e) => setModel(e.target.value)} />
              </div>
              <div>
                <label className="label">Kvadratura (kvm)</label>
                <input type="number" min={0} className="input" placeholder="200" value={kvm}
                       onChange={(e) => setKvm(e.target.value)} />
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label className="label">Mahsulot nomi *</label>
                <input className="input" placeholder="Turba, defizor ..." value={name}
                       onChange={(e) => setName(e.target.value)} />
              </div>
              <div>
                <label className="label">O'lchov birligi</label>
                <select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}>
                  {UNITS.map((u) => <option key={u} value={u}>{u}</option>)}
                </select>
              </div>
            </div>
          )}

          <div>
            <label className="label">Narx (USD)</label>
            <input type="text" inputMode="decimal" className="input" placeholder="0" value={price}
                   onChange={(e) => setPrice(e.target.value.replace(/[^\d.]/g, ''))} />
          </div>

          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[56px]" value={description}
                      onChange={(e) => setDescription(e.target.value)} />
          </div>

          {type === 'main' && (
            <p className="text-xs text-ink-soft">
              Yo'nalish (o'ng/chap) buyurtma qilishda tanlanadi — narxga ta'sir qilmaydi.
            </p>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor qilish</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
