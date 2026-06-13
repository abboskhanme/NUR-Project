import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, Pencil } from 'lucide-react';

import { api } from '@/api/client';

export interface EditableUnit {
  id: string;
  unique_id: string;
  notes?: string | null;
  model?: string | null;
  kvm?: number | null;
  status?: string;
  added_date?: string;
  product_id?: string;
}

interface ProductOpt {
  id: string; product_type?: string; model?: string | null; kvm?: number | null;
  display_name?: string | null; name?: string | null;
}

/** Ombor birligining barcha ma'lumotlarini tahrirlash (model, ID, sana, izoh). */
export default function EditUnitModal({ unit, onClose, onSaved }: {
  unit: EditableUnit; onClose: () => void; onSaved: () => void;
}) {
  const { t } = useTranslation();
  const [productId, setProductId] = useState(unit.product_id ?? '');
  const [uniqueId, setUniqueId] = useState(unit.unique_id);
  const [addedDate, setAddedDate] = useState((unit.added_date ?? '').slice(0, 10));
  const [notes, setNotes] = useState(unit.notes ?? '');
  const [saving, setSaving] = useState(false);

  const { data: products } = useQuery<{ items: ProductOpt[] }>({
    queryKey: ['products', 'warehouse-edit'],
    queryFn: () => api.get('/products', { params: { page_size: 200 } }).then((r) => r.data),
  });
  const mainProducts = useMemo(
    () => (products?.items ?? []).filter((p) => (p.product_type ?? 'main') === 'main'),
    [products],
  );

  async function submit() {
    const id = uniqueId.trim();
    if (!id) { toast.error(t('warehouse.edit.needId')); return; }
    setSaving(true);
    try {
      await api.patch(`/inventory/units/${unit.id}`, {
        unique_id: id,
        product_id: productId || undefined,
        added_date: addedDate || undefined,
        notes: notes.trim() || null,
      });
      toast.success(t('common.updated'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

  const label = (p: ProductOpt) =>
    p.display_name || [p.model, p.kvm ? `${p.kvm} kvm` : null].filter(Boolean).join(' · ') || p.name || '—';

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold text-base flex items-center gap-2">
            <Pencil size={17} className="text-primary" /> {t('warehouse.edit.title')}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.edit.model')}</label>
            <select className="input w-full mt-1" value={productId} onChange={(e) => setProductId(e.target.value)}>
              {mainProducts.map((p) => <option key={p.id} value={p.id}>{label(p)}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.edit.id')}</label>
            <input className="input w-full mt-1 font-mono" value={uniqueId} onChange={(e) => setUniqueId(e.target.value)} autoFocus />
          </div>
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.edit.added')}</label>
            <input type="date" className="input w-full mt-1" value={addedDate} onChange={(e) => setAddedDate(e.target.value)} />
          </div>
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.edit.note')}</label>
            <input className="input w-full mt-1" value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={submit} disabled={saving}
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50">
            {saving ? t('common.saving', { defaultValue: 'Saqlanyapti…' }) : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
