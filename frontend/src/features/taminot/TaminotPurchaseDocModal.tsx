import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Plus, Trash2, PackagePlus, Coins, Banknote } from 'lucide-react';

import { api } from '@/api/client';
import { cn } from '@/lib/cn';
import { formatMoney } from '@/lib/format';
import { CURRENCY_LABEL, type TaminotProduct, type TaminotSupplier } from '@/features/taminot/types';

interface Row { productId: string; qty: string; price: string }

const emptyRow = (): Row => ({ productId: '', qty: '', price: '' });

/**
 * KIRIM HUJJATI — bitta yetkazib beruvchidan bir yo'la bir necha mahsulot.
 *
 * Bitta joydan 15 xil mahsulot olib kelinsa, hammasi shu formada kiritiladi:
 * har qatorning miqdori o'z mahsulotining ombor qoldig'iga, summasi esa
 * yetkazib beruvchining umumiy qarziga boradi.
 *
 * Narx bo'sh qoldirilsa mahsulotning joriy narxi olinadi — narx o'zgargan
 * bo'lsa shu yerda o'zgartiriladi (mahsulot kartochkasiga tegmaydi).
 */
export default function TaminotPurchaseDocModal({
  supplier, onClose, onSaved,
}: {
  supplier: TaminotSupplier;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [rows, setRows] = useState<Row[]>([emptyRow()]);
  const [payMode, setPayMode] = useState<'debt' | 'cash'>('debt');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const productsQ = useQuery<TaminotProduct[]>({
    queryKey: ['taminot-products', supplier.scope, supplier.id],
    queryFn: () => api.get('/taminot/products', {
      params: { scope: supplier.scope, supplier_id: supplier.id },
    }).then((r) => r.data),
  });
  const products = productsQ.data ?? [];
  const byId = useMemo(
    () => Object.fromEntries(products.map((p) => [p.id, p])) as Record<string, TaminotProduct>,
    [products],
  );

  function setRow(i: number, patch: Partial<Row>) {
    setRows((rs) => rs.map((r, idx) => (idx === i ? { ...r, ...patch } : r)));
  }
  // Mahsulot tanlanganda narx avtomatik to'ldiriladi — odatda o'zgarmaydi
  function pickProduct(i: number, productId: string) {
    const p = byId[productId];
    setRow(i, { productId, price: p ? String(p.unit_price) : '' });
  }
  const addRow = () => setRows((rs) => [...rs, emptyRow()]);
  const delRow = (i: number) =>
    setRows((rs) => (rs.length === 1 ? [emptyRow()] : rs.filter((_, idx) => idx !== i)));

  const num = (v: string) => parseFloat((v || '').replace(',', '.')) || 0;
  const lineOf = (r: Row) => {
    const p = byId[r.productId];
    if (!p) return { amount: 0, currency: 'UZS' };
    return { amount: num(r.qty) * num(r.price), currency: p.currency };
  };

  // Valyuta bo'yicha jami — so'm va dollar hech qachon qo'shilmaydi
  const totals = useMemo(() => {
    const acc: Record<string, number> = {};
    for (const r of rows) {
      const { amount, currency } = lineOf(r);
      if (amount > 0) acc[currency] = (acc[currency] ?? 0) + amount;
    }
    return Object.entries(acc);
  }, [rows, byId]);

  const chosen = new Set(rows.map((r) => r.productId).filter(Boolean));

  async function save() {
    const items = rows
      .filter((r) => r.productId && num(r.qty) > 0)
      .map((r) => ({
        product_id: r.productId,
        qty: num(r.qty),
        unit_price: num(r.price),
      }));
    if (!items.length) { toast.error('Kamida bitta mahsulot va miqdor kiriting'); return; }
    setSaving(true);
    try {
      await api.post(`/taminot/suppliers/${supplier.id}/purchase`, {
        items, payment_mode: payMode, note: note.trim() || null,
      });
      toast.success(payMode === 'cash'
        ? "Kirim qilindi — omborga kirdi, naqd to'langan deb yozildi"
        : 'Kirim qilindi — omborga kirdi, qarzga yozildi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] bg-black/40 flex items-center justify-center p-3 sm:p-4"
         onClick={onClose}>
      <div className="bg-card rounded-card w-full max-w-2xl shadow-lg max-h-[92vh] flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="px-4 sm:px-5 py-3 border-b border-black/5 flex items-center justify-between">
          <div className="min-w-0">
            <h3 className="font-semibold flex items-center gap-2">
              <PackagePlus size={18} className="text-primary" /> Olib kelish
            </h3>
            <p className="text-xs text-ink-soft truncate">
              {supplier.name} — bir yo'la bir necha mahsulot kiritish mumkin
            </p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-4 sm:p-5 space-y-3 overflow-y-auto">
          {products.length === 0 && !productsQ.isLoading ? (
            <div className="text-sm text-ink-soft text-center py-6">
              Bu yetkazib beruvchida hali mahsulot yo'q — avval mahsulot qo'shing
            </div>
          ) : (
            <>
              <div className="space-y-2">
                {/* Ustun sarlavhalari — faqat kengroq ekranda */}
                <div className="hidden sm:flex items-center gap-2 text-[11px] text-ink-soft px-1">
                  <div className="flex-1">Mahsulot</div>
                  <div className="w-20 text-center">Miqdor</div>
                  <div className="w-28 text-center">Birlik narxi</div>
                  <div className="w-32 text-right">Summa</div>
                  <div className="w-9" />
                </div>
                {rows.map((r, i) => {
                  const p = byId[r.productId];
                  const { amount, currency } = lineOf(r);
                  return (
                    <div key={i} className="rounded-button border border-black/[0.07] p-2 sm:p-0 sm:border-0
                                            flex flex-wrap sm:flex-nowrap items-center gap-2">
                      <div className="basis-full sm:basis-0 sm:flex-1 min-w-0">
                        <select className="input w-full" value={r.productId}
                                onChange={(e) => pickProduct(i, e.target.value)}>
                          <option value="">— mahsulotni tanlang —</option>
                          {products.map((op) => (
                            <option key={op.id} value={op.id}
                                    disabled={op.id !== r.productId && chosen.has(op.id)}>
                              {op.name} ({op.unit})
                            </option>
                          ))}
                        </select>
                      </div>
                      <input className="input w-20 shrink-0" inputMode="decimal"
                             placeholder={p?.unit ?? 'miqdor'} value={r.qty}
                             onChange={(e) => setRow(i, { qty: e.target.value })} />
                      <input className="input w-28 shrink-0" inputMode="decimal" placeholder="narx"
                             value={r.price} onChange={(e) => setRow(i, { price: e.target.value })} />
                      <div className="flex-1 sm:w-32 sm:flex-none text-right text-sm tabular-nums">
                        {amount > 0 ? formatMoney(amount, currency)
                                    : <span className="text-ink-soft">—</span>}
                      </div>
                      <button onClick={() => delRow(i)} title="Qatorni o'chirish"
                              className="w-9 h-9 shrink-0 rounded-button flex items-center justify-center text-danger hover:bg-danger/10">
                        <Trash2 size={15} />
                      </button>
                    </div>
                  );
                })}
              </div>

              <button onClick={addRow}
                      className="text-sm text-primary hover:underline inline-flex items-center gap-1">
                <Plus size={15} /> Mahsulot qo'shish
              </button>

              {/* To'lov turi */}
              <div>
                <label className="label">To'lov holati</label>
                <div className="grid grid-cols-2 gap-2">
                  {([
                    ['debt', 'Qarzga olindi', Coins, "Qarz qoldig'i oshadi"],
                    ['cash', "Naqd to'landi", Banknote, 'Qarz oshmaydi'],
                  ] as const).map(([mode, label, ModeIcon, hint]) => {
                    const active = payMode === mode;
                    return (
                      <button key={mode} type="button" onClick={() => setPayMode(mode)}
                        className={cn('rounded-button border px-3 py-2 text-left transition',
                          !active && 'border-black/10 hover:bg-black/5',
                          active && mode === 'debt' && 'border-danger/40 bg-danger/10',
                          active && mode === 'cash' && 'border-success/40 bg-success/10')}>
                        <div className={cn('text-sm font-medium flex items-center gap-1.5',
                          active && mode === 'debt' && 'text-danger',
                          active && mode === 'cash' && 'text-success')}>
                          <ModeIcon size={15} /> {label}
                        </div>
                        <div className="text-[11px] text-ink-soft">{hint}</div>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label className="label">Izoh (ixtiyoriy)</label>
                <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
              </div>

              {/* Jami */}
              <div className={cn('rounded-lg border px-3 py-2.5',
                payMode === 'cash' ? 'bg-success/5 border-success/20' : 'bg-primary/5 border-primary/15')}>
                <div className="text-xs text-ink-soft mb-1">
                  {payMode === 'cash' ? "Naqd to'lanadi" : "Qarzga qo'shiladi"}
                </div>
                {totals.length === 0 ? (
                  <div className="text-ink-soft text-sm">Mahsulot tanlanmagan</div>
                ) : (
                  <div className="flex flex-wrap gap-x-5 gap-y-1">
                    {totals.map(([cur, sum]) => (
                      <div key={cur} className="text-xl font-bold tabular-nums">
                        {formatMoney(sum, cur)}
                      </div>
                    ))}
                  </div>
                )}
                {totals.length > 1 && (
                  <p className="text-[11px] text-ink-soft mt-1">
                    {CURRENCY_LABEL.UZS} va {CURRENCY_LABEL.USD} alohida hisoblanadi — qo'shilmaydi
                  </p>
                )}
              </div>
            </>
          )}
        </div>

        <div className="px-4 sm:px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose}
                  className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={save} disabled={saving || !products.length}
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50">
            {saving ? 'Saqlanyapti…' : 'Kirim qilish'}
          </button>
        </div>
      </div>
    </div>
  );
}
