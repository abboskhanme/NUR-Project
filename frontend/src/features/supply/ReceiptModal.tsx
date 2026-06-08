import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';
import { formatAmount, toNum, today } from './money';

interface VendorLite { id: string; name: string }
interface ItemLite { id: string; name: string; unit: string; unit_price: string }

export default function ReceiptModal({
  vendors, fixedVendorId, onClose, onSaved,
}: {
  vendors: VendorLite[];
  fixedVendorId?: string;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const [vendorId, setVendorId] = useState(fixedVendorId ?? '');
  const [itemId, setItemId] = useState('');
  const [date, setDate] = useState(today());
  const [qty, setQty] = useState('');
  const [unitPrice, setUnitPrice] = useState('');
  const [paid, setPaid] = useState('');
  const [note, setNote] = useState('');
  const [priceTouched, setPriceTouched] = useState(false);
  const [saving, setSaving] = useState(false);

  const effVendor = fixedVendorId ?? vendorId;

  const itemsQ = useQuery<ItemLite[]>({
    queryKey: ['supply-items-picker', effVendor],
    queryFn: () => api.get('/supply/items', {
      params: { vendor_id: fixedVendorId ? undefined : (vendorId || undefined), page_size: 200 },
    }).then((r) => r.data.items ?? []),
  });

  const items = itemsQ.data ?? [];
  const selected = useMemo(() => items.find((i) => i.id === itemId), [items, itemId]);

  useEffect(() => {
    if (selected && !priceTouched) {
      const p = parseFloat(selected.unit_price) || 0;
      setUnitPrice(p ? formatAmount(String(p)) : '');
    }
  }, [itemId]); // eslint-disable-line

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const total = toNum(qty) * toNum(unitPrice);
  const debt = Math.max(0, total - toNum(paid));

  async function handleSave() {
    if (!effVendor) { toast.error(t('supply.receiptModal.vendorRequired')); return; }
    if (!itemId) { toast.error(t('supply.receiptModal.itemRequired')); return; }
    if (toNum(qty) <= 0) { toast.error(t('supply.receiptModal.qtyRequired')); return; }
    setSaving(true);
    try {
      await api.post('/supply/receipts', {
        date, vendor_id: fixedVendorId ? undefined : vendorId,
        item_id: itemId, qty: toNum(qty),
        unit_price: toNum(unitPrice), paid: toNum(paid), note: note || null,
      });
      toast.success(t('supply.receiptModal.saved'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('supply.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{t('supply.receiptModal.title')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          {!fixedVendorId && (
            <div>
              <label className="label">{t('supply.receiptModal.labelVendor')}</label>
              <select className="input" value={vendorId}
                      onChange={(e) => { setVendorId(e.target.value); setItemId(''); }}>
                <option value="">{t('supply.receiptModal.optionSelect')}</option>
                {vendors.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
              </select>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">{t('supply.receiptModal.labelDate')}</label>
              <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
            </div>
            <div>
              <label className="label">{t('supply.receiptModal.labelItem')}</label>
              <select className="input" value={itemId}
                      onChange={(e) => { setItemId(e.target.value); setPriceTouched(false); }}
                      disabled={!fixedVendorId && !vendorId}>
                <option value="">{t('supply.receiptModal.optionSelect')}</option>
                {items.map((i) => <option key={i.id} value={i.id}>{i.name} ({i.unit})</option>)}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">
                {selected
                  ? t('supply.receiptModal.labelQtyWithUnit', { unit: selected.unit })
                  : t('supply.receiptModal.labelQty')}
              </label>
              <input className="input" inputMode="decimal" value={qty}
                     onChange={(e) => setQty(e.target.value.replace(/[^\d.]/g, ''))} placeholder="0" />
            </div>
            <div>
              <label className="label">{t('supply.receiptModal.labelUnitPrice')}</label>
              <input className="input" inputMode="decimal" value={unitPrice}
                     onChange={(e) => { setUnitPrice(formatAmount(e.target.value)); setPriceTouched(true); }}
                     placeholder="0" />
            </div>
          </div>

          <div className="p-3 rounded-button bg-primary/5 border border-primary/10 space-y-1">
            <div className="flex justify-between text-sm">
              <span className="text-ink-soft">{t('supply.receiptModal.totalLabel')}</span>
              <span className="font-semibold">{formatUZS(total)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-ink-soft">{t('supply.receiptModal.debtLabel')}</span>
              <span className={`font-semibold ${debt > 0 ? 'text-danger' : 'text-success'}`}>
                {formatUZS(debt)}
              </span>
            </div>
          </div>

          <div>
            <label className="label">{t('supply.receiptModal.labelPaid')}</label>
            <input className="input" inputMode="decimal" value={paid}
                   onChange={(e) => setPaid(formatAmount(e.target.value))} placeholder="0" />
            <p className="text-xs text-ink-soft mt-1">{t('supply.receiptModal.hintPaid')}</p>
          </div>

          <div>
            <label className="label">{t('supply.receiptModal.labelNote')}</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('supply.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('supply.receiptModal.saving') : t('supply.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
