import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, Plus, Trash2, RefreshCw } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';
import CustomerPicker, { CustomerLite } from './CustomerPicker';

interface Product {
  id: string; product_type?: string; model?: string | null; kvm?: number | null;
  name?: string | null; unit?: string | null; display_name?: string;
  bunker_direction?: string | null; base_price_usd: string;
}
interface ItemRow {
  product_id: string;
  bunker_direction: string;
  quantity: number;
  unit_price_usd: string;
  discount: string; // chegirma DOLLARDA
}

export interface OrderEditData {
  id: string;
  customer?: CustomerLite | null;
  customer_id: string;
  order_date: string;
  exchange_rate: string;
  delivery_address?: string | null;
  note?: string | null;
  items: Array<{ product_id: string; bunker_direction?: string | null; quantity: number; unit_price_usd: string; discount_usd?: string; discount?: string }>;
}

const today = () => new Date().toISOString().slice(0, 10);
const num = (s: string | number | null | undefined) => {
  const n = parseFloat(String(s ?? '')); return Number.isNaN(n) ? 0 : n;
};
// Dollar summasi uchun — raqam va bitta nuqta (o'nlik) ruxsat etiladi
const decStr = (s: string | number | null | undefined) =>
  String(s ?? '').replace(/[^\d.]/g, '').replace(/(\..*)\./g, '$1');

export default function OrderModal({
  order,
  onClose,
  onSaved,
}: {
  order: OrderEditData | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const isCreate = order === null;

  const [customer, setCustomer] = useState<CustomerLite | null>(order?.customer ?? null);
  const [orderDate, setOrderDate] = useState(order?.order_date ?? today());
  const [rate, setRate] = useState(order ? String(num(order.exchange_rate)) : '');
  const [address, setAddress] = useState(order?.delivery_address ?? '');
  const [note, setNote] = useState(order?.note ?? '');
  const [items, setItems] = useState<ItemRow[]>(
    order?.items?.map((i) => ({
      product_id: i.product_id, bunker_direction: i.bunker_direction ?? '',
      quantity: i.quantity,
      unit_price_usd: String(num(i.unit_price_usd)), discount: String(num(i.discount_usd)),
    })) ?? [],
  );
  const [saving, setSaving] = useState(false);

  const productsQ = useQuery({
    queryKey: ['products', 'picker'],
    queryFn: () => api.get('/products', { params: { page_size: 200 } }).then((r) => r.data),
  });
  // Ombor turlari (product_type='warehouse') sotuvda ko'rsatilmaydi — aralashmasligi uchun
  const products: Product[] = (productsQ.data?.items ?? [])
    .filter((p: Product) => p.product_type !== 'warehouse');

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function fetchRate(silent = false) {
    try {
      const r = await api.get('/finance/exchange-rates/latest');
      const latest = r.data;
      if (latest?.usd_to_uzs) {
        setRate(String(num(latest.usd_to_uzs)));
        if (!silent) {
          const src = latest.source === 'cbu' ? t('sales.rateSourceCbu') : t('sales.rateSourceDefault');
          toast.success(t('sales.rateSource', { src }));
        }
      } else if (!silent) {
        toast.error(t('sales.rateNotFound'));
      }
    } catch {
      if (!silent) toast.error(t('sales.rateFetchError'));
    }
  }

  useEffect(() => {
    if (isCreate && !rate) fetchRate(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const rateNum = num(rate);

  function rowTotal(it: ItemRow): number {
    const uzs = num(it.unit_price_usd) * rateNum;
    // chegirma dollarda — UZS jamiga aylantirib ayiramiz
    return uzs * (it.quantity || 1) - num(it.discount) * rateNum;
  }
  const grandTotal = useMemo(() => items.reduce((s, it) => s + rowTotal(it), 0), [items, rateNum]);

  function addRow() {
    setItems((p) => [...p, { product_id: products[0]?.id ?? '', bunker_direction: '', quantity: 1, unit_price_usd: '', discount: '' }]);
  }
  function updateRow(idx: number, patch: Partial<ItemRow>) {
    setItems((p) => p.map((r, i) => (i === idx ? { ...r, ...patch } : r)));
  }
  function removeRow(idx: number) {
    setItems((p) => p.filter((_, i) => i !== idx));
  }
  function onProductChange(idx: number, productId: string) {
    const prod = products.find((p) => p.id === productId);
    const prefill = prod ? String(num(prod.base_price_usd)) : '';
    const dir = prod?.bunker_direction ?? items[idx].bunker_direction;
    updateRow(idx, {
      product_id: productId,
      unit_price_usd: prefill,
      bunker_direction: items[idx].bunker_direction || (dir ?? ''),
    });
  }

  function isMainItem(it: ItemRow): boolean {
    const p = products.find((pp) => pp.id === it.product_id);
    return p?.product_type !== 'additional';
  }

  function buildItem(it: ItemRow, qty: number, discountUsd: number) {
    return {
      product_id: it.product_id,
      bunker_direction: isMainItem(it) ? (it.bunker_direction || null) : null,
      quantity: qty,
      unit_price_usd: num(it.unit_price_usd),
      unit_price_uzs: num(it.unit_price_usd) * rateNum,
      discount_usd: discountUsd,
    };
  }

  async function handleSave() {
    if (!customer) { toast.error(t('sales.errNoCustomer')); return; }
    if (items.length === 0) { toast.error(t('sales.errNoItems')); return; }
    if (items.some((it) => !it.product_id)) { toast.error(t('sales.errNoProduct')); return; }
    if (items.some((it) => isMainItem(it) && !it.bunker_direction)) { toast.error(t('sales.errNoBunker')); return; }
    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      // chegirma ($) mahsulot summasidan ($ × soni) oshmasligi kerak
      const subtotalUsd = num(it.unit_price_usd) * (it.quantity || 1);
      if (num(it.discount) > subtotalUsd) {
        toast.error(t('sales.errDiscountExceeds', { row: i + 1 }));
        return;
      }
    }

    const additionalItems = items.filter((it) => !isMainItem(it));
    const mainUnits: Array<{ it: ItemRow; discount: number }> = [];
    for (const it of items.filter(isMainItem)) {
      const q = it.quantity || 1;
      const per = num(it.discount) / q;
      for (let k = 0; k < q; k++) mainUnits.push({ it, discount: per });
    }

    type ApiItem = ReturnType<typeof buildItem>;
    const orderItemLists: ApiItem[][] = [];
    if (mainUnits.length === 0) {
      orderItemLists.push(additionalItems.map((it) => buildItem(it, it.quantity || 1, num(it.discount))));
    } else {
      mainUnits.forEach((mu, i) => {
        const list: ApiItem[] = [buildItem(mu.it, 1, mu.discount)];
        if (i === 0) for (const a of additionalItems) list.push(buildItem(a, a.quantity || 1, num(a.discount)));
        orderItemLists.push(list);
      });
    }

    const baseBody = {
      customer_id: customer.id,
      order_date: orderDate,
      exchange_rate: rateNum,
      delivery_address: address || null,
      note: note || null,
    };

    setSaving(true);
    try {
      const n = orderItemLists.length;
      if (isCreate) {
        for (const its of orderItemLists) await api.post('/orders', { ...baseBody, items: its });
        toast.success(n > 1 ? t('sales.createdMany', { count: n }) : t('sales.createdOne'));
      } else {
        await api.patch(`/orders/${order!.id}`, { ...baseBody, items: orderItemLists[0] });
        for (const its of orderItemLists.slice(1)) await api.post('/orders', { ...baseBody, items: its });
        toast.success(n > 1 ? t('sales.updatedMany', { count: n - 1 }) : t('sales.updatedOne'));
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-3xl max-h-[94vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">{isCreate ? t('sales.modalCreateTitle') : t('sales.modalEditTitle')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {/* Customer + date + rate */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div className="md:col-span-2">
              <label className="label">{t('sales.labelCustomer')}</label>
              <CustomerPicker value={customer} onChange={setCustomer} />
            </div>
            <div>
              <label className="label">{t('sales.labelOrderDate')}</label>
              <input type="date" className="input" value={orderDate} onChange={(e) => setOrderDate(e.target.value)} />
            </div>
            <div>
              <label className="label">{t('sales.labelRate')}</label>
              <div className="flex gap-2">
                <input type="text" inputMode="decimal" className="input" placeholder="0"
                       value={rate} onChange={(e) => setRate(e.target.value.replace(/[^\d.]/g, ''))} />
                <button type="button" onClick={() => fetchRate()} className="btn-ghost shrink-0" title={t('sales.labelRateTooltip')}>
                  <RefreshCw size={15} />
                </button>
              </div>
            </div>
          </div>

          {/* Items */}
          <div className="border border-black/5 rounded-card p-3">
            <div className="flex items-center justify-between mb-2">
              <div className="font-medium text-sm">{t('sales.labelItems')}</div>
              <button type="button" onClick={addRow} className="text-xs text-primary font-medium flex items-center gap-1">
                <Plus size={14} /> {t('sales.addRowBtn')}
              </button>
            </div>
            <p className="text-xs text-ink-soft mb-2">
              {t('sales.itemsHint')}
            </p>
            {items.length === 0 ? (
              <div className="text-sm text-ink-soft py-3 text-center">{t('sales.noItemsAdded')}</div>
            ) : (
              <div className="space-y-2">
                {/* Column headers */}
                <div className="grid grid-cols-12 gap-2 px-0.5 text-[11px] font-medium text-ink-soft">
                  <div className="col-span-3">{t('sales.colItemProduct')}</div>
                  <div className="col-span-2">{t('sales.colBunker')}</div>
                  <div className="col-span-2">{t('sales.colItemQtyShort')}</div>
                  <div className="col-span-2">{t('sales.colPriceUsdShort')}</div>
                  <div className="col-span-2">{t('sales.colDiscountUsd')}</div>
                  <div className="col-span-1" />
                </div>
                {items.map((it, idx) => (
                  <div key={idx} className="grid grid-cols-12 gap-2 items-center">
                    <select
                      className={`input col-span-3 ${!it.product_id ? 'border-danger ring-1 ring-danger/40' : ''}`}
                      value={it.product_id} required
                      onChange={(e) => onProductChange(idx, e.target.value)}>
                      <option value="">{t('sales.selectProduct')}</option>
                      {products.map((p) => (
                        <option key={p.id} value={p.id}>
                          {p.display_name ?? p.model ?? p.name ?? '—'}
                        </option>
                      ))}
                    </select>
                    {products.find((p) => p.id === it.product_id)?.product_type !== 'additional' ? (
                      <select
                        className={`input col-span-2 ${!it.bunker_direction ? 'border-danger ring-1 ring-danger/40' : ''}`}
                        value={it.bunker_direction} required
                        onChange={(e) => updateRow(idx, { bunker_direction: e.target.value })} title={t('sales.colBunker')}>
                        <option value="">{t('sales.dirPlaceholder')}</option>
                        <option value="right">{t('sales.bunkerRight')}</option>
                        <option value="left">{t('sales.bunkerLeft')}</option>
                      </select>
                    ) : (
                      <div className="col-span-2" />
                    )}
                    <input type="number" min={1} className="input col-span-2" value={it.quantity}
                           onChange={(e) => updateRow(idx, { quantity: parseInt(e.target.value, 10) || 1 })} title={t('sales.colItemQtyShort')} />
                    <input type="text" inputMode="decimal" readOnly tabIndex={-1}
                           className="input col-span-2 bg-black/5 text-ink-soft cursor-not-allowed"
                           placeholder="$ narx" value={it.unit_price_usd}
                           title={t('sales.priceReadOnly')} />
                    <input type="text" inputMode="decimal" className="input col-span-2 text-right" placeholder="$ 0"
                           value={it.discount}
                           onChange={(e) => updateRow(idx, { discount: decStr(e.target.value) })} title={t('sales.colDiscountUsd')}
                           style={rowTotal(it) < 0 ? { borderColor: '#E74C3C', color: '#E74C3C' } : undefined} />
                    <button type="button" onClick={() => removeRow(idx)} className="col-span-1 p-1 rounded hover:bg-danger/10 text-danger justify-self-end">
                      <Trash2 size={15} />
                    </button>
                  </div>
                ))}
              </div>
            )}
            <div className="flex justify-end mt-3 pt-2 border-t border-black/5 text-sm">
              <span className="text-ink-soft mr-2">{t('sales.grandTotal')}</span>
              <span className="font-bold text-primary">{formatUZS(grandTotal)}</span>
            </div>
          </div>

          {/* Address + note */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label className="label">{t('sales.labelAddress')}</label>
              <textarea className="input min-h-[60px]" value={address} onChange={(e) => setAddress(e.target.value)} />
            </div>
            <div>
              <label className="label">{t('sales.labelNote')}</label>
              <textarea className="input min-h-[60px]" value={note} onChange={(e) => setNote(e.target.value)} />
            </div>
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">{t('sales.cancelBtn')}</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('sales.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
