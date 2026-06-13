import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, Boxes } from 'lucide-react';

import { api } from '@/api/client';

interface ProductOpt {
  id: string; product_type?: string; model?: string | null; kvm?: number | null;
  display_name?: string | null; name?: string | null;
}

/**
 * Ombor uchun ishlab chiqarilgan kotyol birliklarini qo'shish.
 * Har bir ID raqami alohida birlik bo'ladi (har qatorda yoki vergul bilan).
 */
export default function AddUnitsModal({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const { t } = useTranslation();
  const [productId, setProductId] = useState('');
  const [idsText, setIdsText] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);

  const { data: products } = useQuery<{ items: ProductOpt[] }>({
    queryKey: ['products', 'warehouse-add'],
    queryFn: () => api.get('/products', { params: { page_size: 200 } }).then((r) => r.data),
  });

  // Faqat asosiy (kotyol) modellar
  const mainProducts = useMemo(
    () => (products?.items ?? []).filter((p) => (p.product_type ?? 'main') === 'main'),
    [products],
  );

  const ids = useMemo(
    () => idsText.split(/[\n,]+/).map((s) => s.trim()).filter(Boolean),
    [idsText],
  );

  async function submit() {
    if (!productId) { toast.error(t('warehouse.add.pickModel')); return; }
    if (ids.length === 0) { toast.error(t('warehouse.add.needIds')); return; }
    setSaving(true);
    try {
      const r = await api.post('/inventory/units', {
        product_id: productId, unique_ids: ids, notes: notes.trim() || null,
      });
      toast.success(t('warehouse.add.created', { count: r.data.created }));
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
            <Boxes size={18} className="text-primary" /> {t('warehouse.add.title')}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.add.model')}</label>
            <select className="input w-full mt-1" value={productId} onChange={(e) => setProductId(e.target.value)}>
              <option value="">{t('warehouse.add.pickModel')}</option>
              {mainProducts.map((p) => <option key={p.id} value={p.id}>{label(p)}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.add.ids')}</label>
            <textarea
              className="input w-full mt-1 h-28 font-mono text-sm"
              placeholder={t('warehouse.add.idsPlaceholder')}
              value={idsText}
              onChange={(e) => setIdsText(e.target.value)}
            />
            <div className="text-xs text-ink-soft mt-1">{t('warehouse.add.count', { count: ids.length })}</div>
          </div>
          <div>
            <label className="text-xs text-ink-soft">{t('warehouse.add.note')}</label>
            <input className="input w-full mt-1" value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={submit} disabled={saving}
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50">
            {saving ? t('common.saving', { defaultValue: 'Saqlanyapti…' }) : t('warehouse.add.submit')}
          </button>
        </div>
      </div>
    </div>
  );
}
