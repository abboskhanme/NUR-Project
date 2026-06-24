import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, Factory } from 'lucide-react';

import { api } from '@/api/client';

export type Category = 'kotyol' | 'bunker' | 'garelka';

export interface ProductionRecord {
  id: string;
  category: Category;
  production_date: string;
  quantity: number;
  product_id?: string | null;
  bunker_direction?: string | null;
  unit_code?: string | null;
  notes?: string | null;
  model?: string | null;
  kvm?: number | null;
}

interface ProductOpt {
  id: string; model?: string | null; kvm?: number | null;
  display_name?: string | null;
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Ishlab chiqarish yozuvini qo'shish / tahrirlash.
 * Kotyol — model (ombor modelidan) + yo'nalish + ID raqami; bunker/garelka — faqat soni.
 */
export default function ProductionModal({
  category, record, onClose, onSaved,
}: {
  category: Category;
  record: ProductionRecord | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const isKotyol = category === 'kotyol';

  const [date, setDate] = useState(record?.production_date ?? today());
  const [productId, setProductId] = useState(record?.product_id ?? '');
  const [direction, setDirection] = useState(record?.bunker_direction ?? '');
  const [unitCode, setUnitCode] = useState(record?.unit_code ?? '');
  const [qty, setQty] = useState<number | ''>(record?.quantity ?? 1);
  const [notes, setNotes] = useState(record?.notes ?? '');
  const [saving, setSaving] = useState(false);

  // Ombor modellari (faqat kotyol uchun kerak)
  const { data: products } = useQuery<{ items: ProductOpt[] }>({
    queryKey: ['products', 'warehouse-prod'],
    queryFn: () => api.get('/products', {
      params: { product_type: 'warehouse', page_size: 200 },
    }).then((r) => r.data),
    enabled: isKotyol,
  });
  const models = useMemo(() => products?.items ?? [], [products]);
  const label = (p: ProductOpt) =>
    p.display_name || [p.model, p.kvm ? `${p.kvm} kvm` : null].filter(Boolean).join(' · ') || '—';

  async function submit() {
    if (isKotyol) {
      if (!productId) { toast.error(t('production.modal.needModel')); return; }
      if (!unitCode.trim()) { toast.error(t('production.modal.needId')); return; }
    } else if (!qty || Number(qty) < 1) {
      toast.error(t('production.modal.needQty')); return;
    }
    setSaving(true);
    try {
      const payload: Record<string, unknown> = {
        production_date: date || null,
        notes: notes.trim() || null,
      };
      if (isKotyol) {
        payload.product_id = productId;
        payload.bunker_direction = direction || null;
        payload.unit_code = unitCode.trim();
      } else {
        payload.quantity = Number(qty);
      }
      if (record) {
        await api.patch(`/production/records/${record.id}`, payload);
      } else {
        await api.post('/production/records', { ...payload, category });
      }
      toast.success(t('production.modal.saved'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

  const titleKey = record
    ? (`production.modal.edit${cap(category)}` as const)
    : (`production.modal.add${cap(category)}` as const);

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold text-base flex items-center gap-2">
            <Factory size={18} className="text-primary" /> {t(titleKey)}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <div>
            <label className="text-xs text-ink-soft">{t('production.modal.date')}</label>
            <input type="date" className="input w-full mt-1" value={date}
                   onChange={(e) => setDate(e.target.value)} />
          </div>

          {isKotyol ? (
            <>
              <div>
                <label className="text-xs text-ink-soft">{t('production.modal.model')}</label>
                <select className="input w-full mt-1" value={productId}
                        onChange={(e) => setProductId(e.target.value)}>
                  <option value="">{t('production.modal.pickModel')}</option>
                  {models.map((p) => <option key={p.id} value={p.id}>{label(p)}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-ink-soft">{t('production.modal.direction')}</label>
                <select className="input w-full mt-1" value={direction}
                        onChange={(e) => setDirection(e.target.value)}>
                  <option value="">{t('production.dir.any')}</option>
                  <option value="right">{t('production.dir.right')}</option>
                  <option value="left">{t('production.dir.left')}</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-ink-soft">{t('production.modal.id')}</label>
                <input className="input w-full mt-1 font-mono" placeholder={t('production.modal.idPlaceholder')}
                       value={unitCode} onChange={(e) => setUnitCode(e.target.value)} />
              </div>
            </>
          ) : (
            <div>
              <label className="text-xs text-ink-soft">{t('production.modal.qty')}</label>
              <input type="number" min={1} className="input w-full mt-1" value={qty}
                     onChange={(e) => setQty(e.target.value === '' ? '' : Number(e.target.value))} />
            </div>
          )}

          <div>
            <label className="text-xs text-ink-soft">{t('production.modal.note')}</label>
            <input className="input w-full mt-1" value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={submit} disabled={saving}
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50">
            {saving ? t('common.saving', { defaultValue: 'Saqlanyapti…' }) : t('actions.save', { defaultValue: 'Saqlash' })}
          </button>
        </div>
      </div>
    </div>
  );
}

function cap(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
