import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
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
  const [productId, setProductId] = useState('');
  const [idsText, setIdsText] = useState('');
  const [notes, setNotes] = useState('');
  const [direction, setDirection] = useState('');
  const [saving, setSaving] = useState(false);

  const { data: products } = useQuery<{ items: ProductOpt[] }>({
    queryKey: ['products', 'warehouse-add'],
    queryFn: () => api.get('/products', {
      params: { product_type: 'warehouse', page_size: 200 },
    }).then((r) => r.data),
  });

  // Faqat ombor turlari (kotyol) — sotuv mahsulotlari bilan aralashmaydi
  const mainProducts = useMemo(() => products?.items ?? [], [products]);

  const ids = useMemo(
    () => idsText.split(/[\n,]+/).map((s) => s.trim()).filter(Boolean),
    [idsText],
  );

  async function submit() {
    if (!productId) { toast.error("Modelni tanlang"); return; }
    if (ids.length === 0) { toast.error("Kamida bitta ID raqami kerak"); return; }
    setSaving(true);
    try {
      const r = await api.post('/inventory/units', {
        product_id: productId, unique_ids: ids, notes: notes.trim() || null,
        bunker_direction: direction || null,
      });
      toast.success(`${r.data.created} ta birlik qoʻshildi`);
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
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
            <Boxes size={18} className="text-primary" /> Birlik qoʻshish
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <div>
            <label className="text-xs text-ink-soft">Model (kotyol)</label>
            <select className="input w-full mt-1" value={productId} onChange={(e) => setProductId(e.target.value)}>
              <option value="">Modelni tanlang</option>
              {mainProducts.map((p) => <option key={p.id} value={p.id}>{label(p)}</option>)}
            </select>
          </div>
          <div>
            <label className="text-xs text-ink-soft">ID raqamlari</label>
            <textarea
              className="input w-full mt-1 h-28 font-mono text-sm"
              placeholder="Har qatorda yoki vergul bilan: SKL-001, SKL-002 …"
              value={idsText}
              onChange={(e) => setIdsText(e.target.value)}
            />
            <div className="text-xs text-ink-soft mt-1">{`${ids.length} ta ID`}</div>
          </div>
          <div>
            <label className="text-xs text-ink-soft">Yoʻnalish</label>
            <select className="input w-full mt-1" value={direction} onChange={(e) => setDirection(e.target.value)}>
              <option value="">— tanlanmagan —</option>
              <option value="right">Oʻngga</option>
              <option value="left">Chapga</option>
            </select>
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
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50">
            {saving ? 'Saqlanyapti…' : "Qoʻshish"}
          </button>
        </div>
      </div>
    </div>
  );
}
