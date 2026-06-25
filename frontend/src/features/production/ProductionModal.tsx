import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Factory } from 'lucide-react';

import { api } from '@/api/client';

export type Category = 'kotyol' | 'bunker' | 'garelka' | 'tana';

// Kotyol tanasi o'lchamlari — base ishlab chiqarishda faqat shu 5 xil bor
export const TANA_SIZES = ['150', '200', '300', '400', '500'] as const;

// Modal sarlavhalari — kategoriya + qo'shish/tahrirlash bo'yicha
const MODAL_TITLES: Record<string, string> = {
  addKotyol: 'Kotyol qoʻshish',
  editKotyol: 'Kotyolni tahrirlash',
  addBunker: 'Bunker qoʻshish',
  editBunker: 'Bunkerni tahrirlash',
  addGarelka: 'Garelka qoʻshish',
  editGarelka: 'Garelkani tahrirlash',
  addTana: 'Ishlab chiqarishdan olib kelish',
  editTana: 'Ishlab chiqarishdan olib kelishni tahrirlash',
};

export interface ProductionRecord {
  id: string;
  category: Category;
  production_date: string;
  quantity: number;
  product_id?: string | null;
  bunker_direction?: string | null;
  unit_code?: string | null;
  body_size?: string | null;
  notes?: string | null;
  model?: string | null;
  kvm?: number | null;
  transferred?: boolean;
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
  const isKotyol = category === 'kotyol';
  const isTana = category === 'tana';

  const [date, setDate] = useState(record?.production_date ?? today());
  const [productId, setProductId] = useState(record?.product_id ?? '');
  const [direction, setDirection] = useState(record?.bunker_direction ?? '');
  const [unitCode, setUnitCode] = useState(record?.unit_code ?? '');
  const [bodySize, setBodySize] = useState(record?.body_size ?? '');
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
      if (!productId) { toast.error("Modelni tanlang"); return; }
      if (!unitCode.trim()) { toast.error("ID raqami kerak"); return; }
    } else if (isTana) {
      if (!bodySize.trim()) { toast.error("Oʻlcham kerak"); return; }
      if (direction !== 'right' && direction !== 'left') {
        toast.error("Yoʻnalishni tanlang (oʻng/chap)"); return;
      }
      if (!qty || Number(qty) < 1) { toast.error("Soni kamida 1 boʻlishi kerak"); return; }
    } else if (!qty || Number(qty) < 1) {
      toast.error("Soni kamida 1 boʻlishi kerak"); return;
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
      } else if (isTana) {
        payload.body_size = bodySize.trim();
        payload.bunker_direction = direction;
        payload.quantity = Number(qty);
      } else {
        payload.quantity = Number(qty);
      }
      if (record) {
        await api.patch(`/production/records/${record.id}`, payload);
      } else {
        await api.post('/production/records', { ...payload, category });
      }
      toast.success("Saqlandi");
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  const title = record
    ? MODAL_TITLES[`edit${cap(category)}`]
    : MODAL_TITLES[`add${cap(category)}`];

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold text-base flex items-center gap-2">
            <Factory size={18} className="text-primary" /> {title}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <div>
            <label className="text-xs text-ink-soft">Ishlab chiqarilgan sana</label>
            <input type="date" className="input w-full mt-1" value={date}
                   onChange={(e) => setDate(e.target.value)} />
          </div>

          {isKotyol ? (
            <>
              <div>
                <label className="text-xs text-ink-soft">Model</label>
                <select className="input w-full mt-1" value={productId}
                        onChange={(e) => setProductId(e.target.value)}>
                  <option value="">Modelni tanlang</option>
                  {models.map((p) => <option key={p.id} value={p.id}>{label(p)}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-ink-soft">Yoʻnalish</label>
                <select className="input w-full mt-1" value={direction}
                        onChange={(e) => setDirection(e.target.value)}>
                  <option value="">— tanlanmagan —</option>
                  <option value="right">Oʻngga</option>
                  <option value="left">Chapga</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-ink-soft">ID raqami</label>
                <input className="input w-full mt-1 font-mono" placeholder="masalan: KT-001"
                       value={unitCode} onChange={(e) => setUnitCode(e.target.value)} />
              </div>
            </>
          ) : isTana ? (
            <>
              <div>
                <label className="text-xs text-ink-soft">Oʻlcham</label>
                <select className="input w-full mt-1" value={bodySize}
                        onChange={(e) => setBodySize(e.target.value)}>
                  <option value="">Oʻlchamni tanlang</option>
                  {TANA_SIZES.map((sz) => <option key={sz} value={sz}>{sz}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs text-ink-soft">Yoʻnalish</label>
                <select className="input w-full mt-1" value={direction}
                        onChange={(e) => setDirection(e.target.value)}>
                  <option value="">Yoʻnalishni tanlang</option>
                  <option value="right">Oʻngga</option>
                  <option value="left">Chapga</option>
                </select>
              </div>
              <div>
                <label className="text-xs text-ink-soft">Soni</label>
                <input type="number" min={1} className="input w-full mt-1" value={qty}
                       onChange={(e) => setQty(e.target.value === '' ? '' : Number(e.target.value))} />
              </div>
            </>
          ) : (
            <div>
              <label className="text-xs text-ink-soft">Soni</label>
              <input type="number" min={1} className="input w-full mt-1" value={qty}
                     onChange={(e) => setQty(e.target.value === '' ? '' : Number(e.target.value))} />
            </div>
          )}

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
            {saving ? 'Saqlanyapti…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}

function cap(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
