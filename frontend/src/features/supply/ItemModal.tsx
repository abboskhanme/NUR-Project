import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import { formatAmount, toNum, UNITS } from './money';

export interface ItemLite {
  id: string; name: string; vendor_id?: string | null; unit: string;
  unit_price: string; stock_qty: string; min_qty: string; note?: string | null;
}
interface VendorLite { id: string; name: string }

export default function ItemModal({
  item, vendors, fixedVendorId, onClose, onSaved,
}: {
  item?: ItemLite | null;
  vendors: VendorLite[];
  fixedVendorId?: string;   // taminotchi rejimida — vendor tanlash yashiriladi
  onClose: () => void;
  onSaved: () => void;
}) {
  const editing = !!item;
  const [name, setName] = useState(item?.name ?? '');
  const [vendorId, setVendorId] = useState(item?.vendor_id ?? fixedVendorId ?? '');
  const [unit, setUnit] = useState(item?.unit ?? 'dona');
  const [unitPrice, setUnitPrice] = useState(item ? formatAmount(item.unit_price) : '');
  const [stock, setStock] = useState(item ? String(parseFloat(item.stock_qty)) : '0');
  const [minQty, setMinQty] = useState(item ? String(parseFloat(item.min_qty)) : '0');
  const [note, setNote] = useState(item?.note ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!name.trim()) { toast.error('Nomini kiriting'); return; }
    setSaving(true);
    try {
      const body: any = {
        name: name.trim(), unit,
        unit_price: toNum(unitPrice),
        min_qty: toNum(minQty),
        note: note || null,
      };
      if (!fixedVendorId) body.vendor_id = vendorId || null;
      if (editing) {
        await api.patch(`/supply/items/${item!.id}`, body);
      } else {
        body.stock_qty = toNum(stock);
        await api.post('/supply/items', body);
      }
      toast.success(editing ? 'Yangilandi' : 'Mahsulot qo\'shildi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{editing ? 'Mahsulotni tahrirlash' : 'Yangi mahsulot'}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          <div>
            <label className="label">Nomi *</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)}
                   placeholder="Masalan: Profil truba 40x40" />
          </div>

          {!fixedVendorId && (
            <div>
              <label className="label">Taminotchi</label>
              <select className="input" value={vendorId} onChange={(e) => setVendorId(e.target.value)}>
                <option value="">— Tanlanmagan —</option>
                {vendors.map((v) => <option key={v.id} value={v.id}>{v.name}</option>)}
              </select>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">O'lchov birligi</label>
              <select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}>
                {UNITS.map((u) => <option key={u} value={u}>{u}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Birlik narxi (so'm)</label>
              <input className="input" inputMode="decimal" value={unitPrice}
                     onChange={(e) => setUnitPrice(formatAmount(e.target.value))} placeholder="0" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {!editing && (
              <div>
                <label className="label">Boshlang'ich qoldiq</label>
                <input className="input" inputMode="decimal" value={stock}
                       onChange={(e) => setStock(e.target.value)} placeholder="0" />
              </div>
            )}
            <div>
              <label className="label">Minimum qoldiq</label>
              <input className="input" inputMode="decimal" value={minQty}
                     onChange={(e) => setMinQty(e.target.value)} placeholder="0" />
            </div>
          </div>
          <p className="text-xs text-ink-soft">
            Qoldiq minimumdan past tushganda «Kam» belgisi va bildirishnoma chiqadi.
          </p>

          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[48px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
