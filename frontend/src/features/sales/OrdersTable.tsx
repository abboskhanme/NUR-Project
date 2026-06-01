import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { ExternalLink, Plus } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';

export interface ProductOpt {
  id: string; product_type?: string; model?: string | null; name?: string | null;
  kvm?: number | null; display_name?: string; base_price_usd: string;
}
interface ProductMini {
  id: string; product_type?: string; model?: string | null; name?: string | null;
  kvm?: number | null; display_name?: string;
}
interface OrderItem {
  id: string; product_id: string; product?: ProductMini | null;
  bunker_direction?: string | null; quantity: number;
  unit_price_usd: string; unit_price_uzs: string; discount: string; serial_id?: string | null;
}
export interface OrderFull {
  id: string; code: string; status: string; order_date: string; delivered_at?: string | null;
  exchange_rate: string;
  customer?: { id: string; full_name: string; phone: string; region?: string | null; address?: string | null } | null;
  items: OrderItem[];
  items_total_uzs: string; paid_uzs: string; balance_uzs: string;
  has_stamp_ruc: boolean; has_stamp_avt: boolean; has_online: boolean; has_video: boolean;
}

const STATUS_OPTIONS = [
  { value: 'new', label: 'Navbatda' },
  { value: 'ready', label: "Tayyor bo'ldi" },
  { value: 'delivered', label: 'Yetkazildi' },
  { value: 'rejected', label: 'Rad etildi' },
];

const STATUS_STYLES: Record<string, string> = {
  new: 'bg-blue-100 text-blue-700',
  ready: 'bg-teal-100 text-teal-700',
  delivered: 'bg-emerald-100 text-emerald-700',
  rejected: 'bg-red-100 text-red-700',
};

const num = (s: string | number | null | undefined) => {
  const n = parseFloat(String(s ?? '')); return Number.isNaN(n) ? 0 : n;
};
// Faqat raqam, leading nol o'chiriladi, minglik probel bilan: "0150000" -> "150 000"
const onlyDigits = (s: string | number | null | undefined) =>
  String(s ?? '').replace(/\D/g, '').replace(/^0+/, '');
const fmtInt = (s: string | number | null | undefined) => {
  const d = onlyDigits(s);
  return d ? d.replace(/\B(?=(\d{3})+(?!\d))/g, ' ') : '';
};

export default function OrdersTable({
  orders, products, onChanged, onPay,
}: {
  orders: OrderFull[];
  products: ProductOpt[];
  onChanged: () => void;
  onPay: (orderId: string) => void;
}) {
  return (
    <div className="overflow-x-auto -mx-2">
      <table className="text-sm border-collapse table-fixed w-[1774px]">
        <colgroup>
          <col style={{ width: 140 }} />{/* Buyurtma */}
          <col style={{ width: 140 }} />{/* Yetkazilgan */}
          <col style={{ width: 170 }} />{/* Mijoz */}
          <col style={{ width: 180 }} />{/* Manzil */}
          <col style={{ width: 180 }} />{/* Model */}
          <col style={{ width: 96 }} />{/* Yo'nalish */}
          <col style={{ width: 90 }} />{/* Narx $ */}
          <col style={{ width: 64 }} />{/* Soni */}
          <col style={{ width: 84 }} />{/* Chegirma */}
          <col style={{ width: 140 }} />{/* Jami */}
          <col style={{ width: 160 }} />{/* To'langan */}
          <col style={{ width: 140 }} />{/* Qoldiq */}
          <col style={{ width: 140 }} />{/* Status */}
          <col style={{ width: 50 }} />{/* ochish */}
        </colgroup>
        <thead className="text-left text-ink-soft border-b border-black/10">
          <tr className="[&>th]:py-2 [&>th]:px-2 [&>th]:font-medium [&>th]:whitespace-nowrap">
            <th>Buyurtma</th>
            <th>Yetkazilgan</th>
            <th>Mijoz</th>
            <th>Manzil</th>
            <th>Model</th>
            <th>Yo'nalish</th>
            <th className="text-right">Narx $</th>
            <th className="text-right">Soni</th>
            <th className="text-right">Chegirma</th>
            <th className="text-right">Jami</th>
            <th className="text-right">To'langan</th>
            <th className="text-right">Qoldiq</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {orders.map((o) => (
            <Row key={o.id} o={o} products={products} onChanged={onChanged} onPay={onPay} />
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Row({
  o, products, onChanged, onPay,
}: {
  o: OrderFull; products: ProductOpt[]; onChanged: () => void; onPay: (id: string) => void;
}) {
  const navigate = useNavigate();
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState(o.status);
  useEffect(() => setStatus(o.status), [o.status]);

  const mainIdx = Math.max(0, o.items.findIndex((it) => it.product?.product_type !== 'additional'));
  const main: OrderItem | undefined = o.items[mainIdx];
  const isAdditionalMain = main?.product?.product_type === 'additional';
  const balance = num(o.balance_uzs);

  async function patchOrder(body: Record<string, unknown>) {
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}`, body);
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  // Asosiy item maydonini o'zgartirib, butun items ro'yxatini qayta yuboramiz
  function itemsWith(overrides: Record<string, unknown>) {
    const rate = num(o.exchange_rate);
    return o.items.map((it, i) => {
      const base = {
        product_id: it.product_id,
        serial_id: it.serial_id ?? null,
        bunker_direction: it.bunker_direction ?? null,
        quantity: it.quantity,
        unit_price_usd: num(it.unit_price_usd),
        unit_price_uzs: num(it.unit_price_uzs),
        discount: num(it.discount),
      };
      if (i !== mainIdx) return base;
      const merged: any = { ...base, ...overrides };
      merged.unit_price_uzs = num(merged.unit_price_usd) * rate;
      return merged;
    });
  }
  function saveMain(overrides: Record<string, unknown>) {
    if (!main) return;
    return patchOrder({ items: itemsWith(overrides) });
  }

  async function patchCustomer(body: Record<string, unknown>) {
    if (!o.customer) return;
    setSaving(true);
    try {
      await api.patch(`/customers/${o.customer.id}`, body);
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  function onStatusChange(next: string) {
    if (next === 'delivered' && balance > 0) {
      toast.error("Buyurtma to'liq to'lanmagan");
      setStatus(o.status);
      return;
    }
    setStatus(next);
    patchOrder({ status: next });
  }

  // onBlur: faqat o'zgargan bo'lsa saqlaymiz
  const blurNum = (orig: string | number, key: 'unit_price_usd' | 'quantity' | 'discount') =>
    (e: React.FocusEvent<HTMLInputElement>) => {
      const v = key === 'quantity'
        ? (parseInt(e.target.value, 10) || 1)
        : num(e.target.value.replace(/\s/g, '')); // probellarni olib tashlab raqamga aylantiramiz
      if (v !== num(orig)) saveMain({ [key]: v });
    };

  const cell = 'px-2 py-1 align-middle whitespace-nowrap';
  const inp = 'w-full bg-transparent border border-transparent hover:border-black/10 focus:border-primary rounded px-1 py-0.5 outline-none';

  return (
    <tr className={'border-b border-black/5 ' + (saving ? 'opacity-60' : '')}>
      {/* Sanalar */}
      <td className={cell}>
        <input type="date" defaultValue={o.order_date} className={inp}
               onChange={(e) => e.target.value && e.target.value !== o.order_date && patchOrder({ order_date: e.target.value })} />
      </td>
      <td className={cell}>
        <input type="date" defaultValue={o.delivered_at ?? ''} className={inp}
               onChange={(e) => e.target.value !== (o.delivered_at ?? '') && patchOrder({ delivered_at: e.target.value || null })} />
      </td>

      {/* Mijoz */}
      <td className={cell}>
        <input defaultValue={o.customer?.full_name ?? ''} className={inp}
               onBlur={(e) => e.target.value !== (o.customer?.full_name ?? '') && patchCustomer({ full_name: e.target.value })} />
      </td>
      <td className={cell}>
        <input defaultValue={o.customer?.address ?? ''} className={inp}
               onBlur={(e) => e.target.value !== (o.customer?.address ?? '') && patchCustomer({ address: e.target.value })} />
      </td>

      {/* Mahsulot */}
      <td className={cell}>
        <select className={inp} value={main?.product_id ?? ''}
                onChange={(e) => {
                  const p = products.find((pp) => pp.id === e.target.value);
                  saveMain({ product_id: e.target.value, bunker_direction: p?.product_type === 'additional' ? null : (main?.bunker_direction ?? null) });
                }}>
          {products.map((p) => (
            <option key={p.id} value={p.id}>{p.display_name ?? p.model ?? p.name ?? '—'}</option>
          ))}
        </select>
      </td>
      <td className={cell}>
        {isAdditionalMain ? (
          <span className="text-ink-soft">—</span>
        ) : (
          <select className={inp} value={main?.bunker_direction ?? ''}
                  onChange={(e) => saveMain({ bunker_direction: e.target.value || null })}>
            <option value="">—</option>
            <option value="right">O'NG</option>
            <option value="left">CHAP</option>
          </select>
        )}
      </td>

      {/* Narx / soni / chegirma */}
      <td className={cell + ' text-right text-ink-soft'} title="Narx mahsulotlar bo'limidan olinadi — bu yerda o'zgartirilmaydi">
        {num(main?.unit_price_usd)}
      </td>
      <td className={cell + ' text-right'}>
        <input type="number" min={1} defaultValue={main?.quantity ?? 1}
               className={inp + ' text-right'} onBlur={blurNum(main?.quantity ?? 1, 'quantity')} />
      </td>
      <td className={cell + ' text-right'}>
        <input type="text" inputMode="numeric" defaultValue={fmtInt(main?.discount)} placeholder="0"
               className={inp + ' text-right'}
               onChange={(e) => { e.target.value = fmtInt(e.target.value); }}
               onBlur={blurNum(main?.discount ?? 0, 'discount')} />
      </td>

      {/* Hisob */}
      <td className={cell + ' text-right font-medium'}>{formatUZS(o.items_total_uzs)}</td>
      <td className={cell + ' text-right text-success'}>
        <span className="inline-flex items-center gap-1 justify-end">
          {formatUZS(o.paid_uzs)}
          {balance > 0 && (
            <button onClick={() => onPay(o.id)} className="p-0.5 rounded hover:bg-primary/10 text-primary" title="To'lov qo'shish">
              <Plus size={13} />
            </button>
          )}
        </span>
      </td>
      <td className={cell + ' text-right ' + (balance > 0 ? 'text-danger font-medium' : 'text-ink-soft')}>
        {formatUZS(o.balance_uzs)}
      </td>

      {/* Status */}
      <td className={cell}>
        <select
          value={status}
          onChange={(e) => onStatusChange(e.target.value)}
          className={'rounded-full px-2.5 py-1 text-xs font-medium border-0 outline-none cursor-pointer ' +
            (STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-700')}>
          {STATUS_OPTIONS.map((st) => <option key={st.value} value={st.value}>{st.label}</option>)}
        </select>
      </td>

      <td className={cell}>
        <button onClick={() => navigate(`/orders/${o.id}`)} className="p-1 rounded hover:bg-black/5 text-ink-soft" title="Ochish">
          <ExternalLink size={14} />
        </button>
      </td>
    </tr>
  );
}
