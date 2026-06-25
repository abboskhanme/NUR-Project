import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Warehouse } from 'lucide-react';

import { api } from '@/api/client';
import type { ProductionRecord } from './ProductionModal';

interface ProductOpt {
  id: string; model?: string | null; kvm?: number | null;
  display_name?: string | null;
}

const productLabel = (p: ProductOpt) =>
  p.display_name || [p.model, p.kvm ? `${p.kvm} kvm` : null].filter(Boolean).join(' · ') || '—';

/**
 * Ishlab chiqarilgan tayyor kotyolni ombor skladiga o'tkazish.
 * Parametrlar kotyol yozuvidan oldindan to'ldiriladi (model, ID, yo'nalish, sana, izoh);
 * kerak bo'lsa tahrirlanadi, so'ng `POST /inventory/units` orqali ombor birligi yaratiladi.
 */
export default function KotyolToWarehouseModal({
  record, onClose, onSaved,
}: {
  record: ProductionRecord; onClose: () => void; onSaved: () => void;
}) {
  const [productId, setProductId] = useState(record.product_id ?? '');
  const [uniqueId, setUniqueId] = useState(record.unit_code ?? '');
  const [direction, setDirection] = useState(record.bunker_direction ?? '');
  const [addedDate, setAddedDate] = useState(record.production_date ?? '');
  const [notes, setNotes] = useState(record.notes ?? '');
  const [saving, setSaving] = useState(false);

  const { data: products } = useQuery<{ items: ProductOpt[] }>({
    queryKey: ['products', 'warehouse-prod'],
    queryFn: () => api.get('/products', {
      params: { product_type: 'warehouse', page_size: 200 },
    }).then((r) => r.data),
  });
  const models = useMemo(() => products?.items ?? [], [products]);

  async function submit() {
    if (!productId) { toast.error("Modelni tanlang"); return; }
    if (!uniqueId.trim()) { toast.error("ID raqami kerak"); return; }
    setSaving(true);
    try {
      await api.post(`/production/records/${record.id}/transfer`, {
        product_id: productId,
        unique_id: uniqueId.trim(),
        added_date: addedDate || null,
        notes: notes.trim() || null,
        bunker_direction: direction || null,
      });
      toast.success("Kotyol omborga oʻtkazildi");
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold text-base flex items-center gap-2">
            <Warehouse size={18} className="text-primary" /> Omborga oʻtkazish
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <p className="text-xs text-ink-soft">Tayyor kotyolni ombor skladiga qoʻshadi. Parametrlar yozuvdan olindi — kerak boʻlsa tahrirlang.</p>

          <div>
            <label className="text-xs text-ink-soft">Model</label>
            <select className="input w-full mt-1" value={productId} onChange={(e) => setProductId(e.target.value)}>
              <option value="">Modelni tanlang</option>
              {models.map((p) => <option key={p.id} value={p.id}>{productLabel(p)}</option>)}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-ink-soft">ID raqami</label>
              <input className="input w-full mt-1 font-mono" value={uniqueId}
                     onChange={(e) => setUniqueId(e.target.value)} />
            </div>
            <div>
              <label className="text-xs text-ink-soft">Yoʻnalish</label>
              <select className="input w-full mt-1" value={direction} onChange={(e) => setDirection(e.target.value)}>
                <option value="">— tanlanmagan —</option>
                <option value="right">Oʻngga</option>
                <option value="left">Chapga</option>
              </select>
            </div>
          </div>

          <div>
            <label className="text-xs text-ink-soft">Ishlab chiqarilgan sana</label>
            <input type="date" className="input w-full mt-1" value={addedDate ?? ''}
                   onChange={(e) => setAddedDate(e.target.value)} />
          </div>

          <div>
            <label className="text-xs text-ink-soft">Izoh (ixtiyoriy)</label>
            <input className="input w-full mt-1" value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={submit} disabled={saving}
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50 inline-flex items-center gap-1.5">
            <Warehouse size={15} />
            {saving ? 'Saqlanyapti…' : "Omborga oʻtkazish"}
          </button>
        </div>
      </div>
    </div>
  );
}
