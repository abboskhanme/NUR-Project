import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Plus, Trash2 } from 'lucide-react';

import { api } from '@/api/client';
import { cn } from '@/lib/cn';

export interface ListProduct {
  id: string; name: string; unit: string;
  unit_price: number; currency: string;
}

interface Row { productId: string; qty: string }

const CURRENCY_LABEL: Record<string, string> = { UZS: "so'm", USD: '$' };

const fmt = (v: number, currency: string) =>
  currency === 'USD'
    ? `$${v.toLocaleString('en-US', { maximumFractionDigits: 2 })}`
    : `${Math.round(v).toLocaleString('ru-RU').replace(/ /g, ' ')} so'm`;

/**
 * «Spiska qilish» — ta'minotchi uchun xarid ro'yxati.
 *
 * Ta'minotchi kerakli mahsulotlarni tanlab, har biridan qancha olib kelishini
 * yozadi; oyna jami qancha pul kerakligini valyuta bo'yicha chiqaradi. Saqlangач
 * spiska DRAFT bo'lib turadi — ombor qoldig'iga ham, qarzga ham ta'sir qilmaydi.
 * Mahsulot haqiqatan kelganda «Qabul qilish» bosiladi.
 */
export default function TaminotListModal({
  scope, onClose, onSaved,
}: { scope: string; onClose: () => void; onSaved: () => void }) {
  const [title, setTitle] = useState('');
  const [note, setNote] = useState('');
  const [rows, setRows] = useState<Row[]>([{ productId: '', qty: '' }]);
  const [saving, setSaving] = useState(false);

  const productsQ = useQuery<ListProduct[]>({
    queryKey: ['taminot-products', scope],
    queryFn: () => api.get('/taminot/products', { params: { scope } }).then((r) => r.data),
  });
  const products = useMemo(() => productsQ.data ?? [], [productsQ.data]);
  const byId = useMemo(
    () => Object.fromEntries(products.map((p) => [p.id, p])) as Record<string, ListProduct>,
    [products],
  );

  function setRow(i: number, patch: Partial<Row>) {
    setRows((rs) => rs.map((r, idx) => (idx === i ? { ...r, ...patch } : r)));
  }
  const addRow = () => setRows((rs) => [...rs, { productId: '', qty: '' }]);
  const delRow = (i: number) => setRows((rs) => (rs.length === 1 ? rs : rs.filter((_, idx) => idx !== i)));

  // Valyuta bo'yicha jami — UZS va USD hech qachon qo'shilmaydi
  const totals = useMemo(() => {
    const acc: Record<string, number> = {};
    for (const r of rows) {
      const p = byId[r.productId];
      const q = parseFloat(r.qty.replace(',', '.'));
      if (!p || !q || q <= 0) continue;
      acc[p.currency] = (acc[p.currency] ?? 0) + q * Number(p.unit_price);
    }
    return Object.entries(acc);
  }, [rows, byId]);

  // Bir mahsulot ikki marta tanlanmasin
  const chosen = new Set(rows.map((r) => r.productId).filter(Boolean));

  async function save() {
    const items = rows
      .map((r) => ({ product_id: r.productId, qty: parseFloat(r.qty.replace(',', '.')) }))
      .filter((i) => i.product_id && i.qty > 0);
    if (!items.length) { toast.error('Kamida bitta mahsulot va miqdor kiriting'); return; }
    setSaving(true);
    try {
      await api.post('/taminot/lists', {
        scope, title: title.trim() || null, note: note.trim() || null, items,
      });
      toast.success('Spiska saqlandi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Saqlab bo‘lmadi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-3 sm:p-4"
         onClick={onClose}>
      <div className="bg-surface rounded-card w-full max-w-2xl shadow-lg max-h-[92vh] flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="px-4 sm:px-5 py-3 border-b border-black/5 flex items-center justify-between">
          <div>
            <h3 className="font-semibold">Spiska qilish</h3>
            <p className="text-xs text-ink-soft">
              Kerakli mahsulotlarni tanlang — jami qancha pul kerakligi chiqadi
            </p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-4 sm:p-5 space-y-3 overflow-y-auto">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-ink-soft">Nomi (ixtiyoriy)</label>
              <input className="input w-full mt-1" value={title} placeholder="Masalan: 6-avgust xaridi"
                     onChange={(e) => setTitle(e.target.value)} />
            </div>
            <div>
              <label className="text-xs text-ink-soft">Izoh (ixtiyoriy)</label>
              <input className="input w-full mt-1" value={note}
                     onChange={(e) => setNote(e.target.value)} />
            </div>
          </div>

          <div className="space-y-2">
            {rows.map((r, i) => {
              const p = byId[r.productId];
              const q = parseFloat(r.qty.replace(',', '.'));
              const line = p && q > 0 ? q * Number(p.unit_price) : 0;
              return (
                <div key={i} className="flex items-end gap-2">
                  <div className="flex-1 min-w-0">
                    {i === 0 && <label className="text-xs text-ink-soft">Mahsulot</label>}
                    <select className="input w-full mt-1" value={r.productId}
                            onChange={(e) => setRow(i, { productId: e.target.value })}>
                      <option value="">— tanlang —</option>
                      {products.map((op) => (
                        <option key={op.id} value={op.id}
                                disabled={op.id !== r.productId && chosen.has(op.id)}>
                          {op.name} ({fmt(Number(op.unit_price), op.currency)}/{op.unit})
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="w-24 sm:w-28 shrink-0">
                    {i === 0 && <label className="text-xs text-ink-soft">Miqdor</label>}
                    <input className="input w-full mt-1" inputMode="decimal" value={r.qty}
                           placeholder={p?.unit ?? '0'}
                           onChange={(e) => setRow(i, { qty: e.target.value })} />
                  </div>
                  <div className="w-28 sm:w-36 shrink-0 text-right text-sm pb-2 tabular-nums">
                    {line > 0 ? fmt(line, p!.currency) : <span className="text-ink-soft">—</span>}
                  </div>
                  <button onClick={() => delRow(i)} disabled={rows.length === 1}
                          className="p-2 mb-1 rounded-button text-danger hover:bg-danger/10 disabled:opacity-30 shrink-0">
                    <Trash2 size={15} />
                  </button>
                </div>
              );
            })}
          </div>

          <button onClick={addRow}
                  className="text-sm text-primary hover:underline inline-flex items-center gap-1">
            <Plus size={15} /> Mahsulot qo‘shish
          </button>

          {/* Jami — ta'minotchi shu summani olib ketadi */}
          <div className="rounded-lg bg-primary/5 border border-primary/15 px-3 py-2.5">
            <div className="text-xs text-ink-soft mb-1">Jami to‘lanadi</div>
            {totals.length === 0 ? (
              <div className="text-ink-soft text-sm">Mahsulot tanlanmagan</div>
            ) : (
              <div className="flex flex-wrap gap-x-5 gap-y-1">
                {totals.map(([cur, sum]) => (
                  <div key={cur} className="text-xl font-bold tabular-nums">{fmt(sum, cur)}</div>
                ))}
              </div>
            )}
            {totals.length > 1 && (
              <p className="text-[11px] text-ink-soft mt-1">
                Valyutalar alohida hisoblanadi — qo‘shilmaydi.
              </p>
            )}
          </div>

          <p className="text-[11px] text-ink-soft">
            Spiska <b>qoralama</b> bo‘lib saqlanadi: ombor qoldig‘iga ham, qarzga ham
            hozircha ta’sir qilmaydi. Mahsulot kelgach «Qabul qilish» bosiladi.
          </p>
        </div>

        <div className="px-4 sm:px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose}
                  className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={save} disabled={saving}
                  className={cn('px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white',
                                'hover:bg-primary/90 disabled:opacity-50')}>
            {saving ? 'Saqlanyapti…' : 'Spiskani saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}

export { CURRENCY_LABEL };
