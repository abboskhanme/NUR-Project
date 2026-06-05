import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { usePermissions } from '@/lib/permissions';
import toast from 'react-hot-toast';
import { ExternalLink, Plus } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS, formatPhone, formatDate } from '@/lib/format';
import { CellDate, CellSelect } from '@/components/ui/TablePickers';

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
  queue_position?: number | null;
  exchange_rate: string;
  inventory_id?: string | null;
  delivery_address?: string | null;
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
      <table className="text-sm border-collapse table-fixed w-[2000px]">
        <colgroup>
          <col style={{ width: 70 }} />{/* Navbat */}
          <col style={{ width: 140 }} />{/* Buyurtma */}
          <col style={{ width: 140 }} />{/* Yetkazilgan */}
          <col style={{ width: 170 }} />{/* Mijoz */}
          <col style={{ width: 140 }} />{/* Telefon */}
          <col style={{ width: 180 }} />{/* Manzil */}
          <col style={{ width: 180 }} />{/* Model */}
          <col style={{ width: 96 }} />{/* Yo'nalish */}
          <col style={{ width: 70 }} />{/* Narx $ */}
          <col style={{ width: 64 }} />{/* Soni */}
          <col style={{ width: 120 }} />{/* Chegirma */}
          <col style={{ width: 140 }} />{/* Jami */}
          <col style={{ width: 160 }} />{/* To'langan */}
          <col style={{ width: 140 }} />{/* Qoldiq */}
          <col style={{ width: 140 }} />{/* Status */}
          <col style={{ width: 50 }} />{/* ochish */}
        </colgroup>
        <thead className="text-left text-ink-soft border-b border-black/10">
          <tr className="[&>th]:py-2 [&>th]:px-2 [&>th]:font-medium [&>th]:whitespace-nowrap">
            <th>Navbat</th>
            <th>Buyurtma</th>
            <th>Yetkazilgan</th>
            <th>Mijoz</th>
            <th>Telefon</th>
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
  const { can } = usePermissions();
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState(o.status);
  useEffect(() => setStatus(o.status), [o.status]);

  const mainIdx = Math.max(0, o.items.findIndex((it) => it.product?.product_type !== 'additional'));
  const main: OrderItem | undefined = o.items[mainIdx];
  const isAdditionalMain = main?.product?.product_type === 'additional';
  const balance = num(o.balance_uzs);
  // Yetkazilgan buyurtma to'liq qulflanadi — hech bir maydon tahrirlanmaydi
  const locked = o.status === 'delivered';

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

  async function onStatusChange(next: string) {
    if (next === 'delivered' && balance > 0) {
      toast.error("Buyurtma to'liq to'lanmagan");
      setStatus(o.status);
      return;
    }
    setStatus(next);
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}`, { status: next });
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
      setStatus(o.status); // backend rad etdi — eski holatga qaytaramiz
    } finally {
      setSaving(false);
    }
  }

  // onBlur: faqat o'zgargan bo'lsa saqlaymiz
  const blurNum = (orig: string | number, key: 'unit_price_usd' | 'quantity' | 'discount') =>
    (e: React.FocusEvent<HTMLInputElement>) => {
      const v = key === 'quantity'
        ? (parseInt(e.target.value, 10) || 1)
        : num(e.target.value.replace(/\s/g, '')); // probellarni olib tashlab raqamga aylantiramiz
      if (v === num(orig)) return;
      if (key === 'discount' && main) {
        // Chegirma mahsulot summasidan (narx * soni) oshmasligi kerak
        const subtotal = num(main.unit_price_uzs) * (main.quantity || 1);
        if (v < 0 || v > subtotal) {
          toast.error("Chegirma mahsulot summasidan oshib ketdi");
          e.target.value = fmtInt(orig); // eski qiymatga qaytaramiz
          return;
        }
      }
      saveMain({ [key]: v });
    };

  const cell = 'px-2 py-1 align-middle whitespace-nowrap';
  const inp = 'w-full bg-transparent border border-transparent hover:border-black/10 focus:border-primary rounded px-1 py-0.5 outline-none';
  // Qulflangan katak — input bilan bir xil ichki joylashuv (padding/border), shunda qatorlar tekis turadi
  const ro = 'block px-1 py-0.5 border border-transparent truncate';

  return (
    <tr className={'border-b border-black/5 ' + (saving ? 'opacity-60' : '')}>
      {/* Navbat raqami — faqat aktiv (new/ready) buyurtmalar uchun */}
      <td className={cell + ' text-center'}>
        {o.queue_position ? (
          <span className="inline-flex items-center justify-center min-w-[28px] px-1.5 py-0.5 rounded-full bg-blue-50 text-blue-700 text-xs font-semibold"
                title={`Navbatda ${o.queue_position}-o'rinda`}>
            №{o.queue_position}
          </span>
        ) : (
          <span className="text-ink-soft">—</span>
        )}
      </td>
      {/* Sanalar */}
      <td className={cell}>
        {locked ? <span className={ro}>{formatDate(o.order_date)}</span> : (
          <CellDate value={o.order_date} clearable={false} triggerClassName={inp}
                    onChange={(iso) => iso && iso !== o.order_date && patchOrder({ order_date: iso })} />
        )}
      </td>
      <td className={cell}>
        {locked ? <span className={ro}>{o.delivered_at ? formatDate(o.delivered_at) : '—'}</span> : (
          <CellDate value={o.delivered_at ?? ''} triggerClassName={inp}
                    onChange={(iso) => iso !== (o.delivered_at ?? '') && patchOrder({ delivered_at: iso || null })} />
        )}
      </td>

      {/* Mijoz */}
      <td className={cell}>
        {locked ? (
          <span className={ro} title={o.customer?.full_name ?? ''}>{o.customer?.full_name ?? '—'}</span>
        ) : (
          <input defaultValue={o.customer?.full_name ?? ''} className={inp}
                 onBlur={(e) => e.target.value !== (o.customer?.full_name ?? '') && patchCustomer({ full_name: e.target.value })} />
        )}
      </td>
      {/* Telefon — faqat ko'rish uchun, tahrirlanmaydi */}
      <td className={cell + ' text-ink-soft'} title="Telefon raqami (tahrirlanmaydi)">
        {o.customer?.phone ? formatPhone(o.customer.phone) : '—'}
      </td>
      <td className={cell}>
        {/* Buyurtmada yetkazish manzili bo'lsa o'shani ko'rsatamiz (masalan usta ish joyi),
            aks holda mijozning manzili. Tahrirlash ham shu manbaga yoziladi. */}
        {(() => {
          const hasDelivery = !!(o.delivery_address && o.delivery_address.trim());
          const shown = hasDelivery ? o.delivery_address! : (o.customer?.address ?? '');
          if (locked) return <span className={ro} title={shown}>{shown || '—'}</span>;
          return (
            <input
              key={hasDelivery ? 'delivery' : 'customer'}
              defaultValue={shown}
              className={inp}
              title={hasDelivery ? 'Yetkazish manzili (buyurtma)' : 'Mijoz manzili'}
              onBlur={(e) => {
                const v = e.target.value;
                if (v === shown) return;
                if (hasDelivery) patchOrder({ delivery_address: v || null });
                else patchCustomer({ address: v });
              }}
            />
          );
        })()}
      </td>

      {/* Mahsulot */}
      <td className={cell}>
        {locked ? (
          <span className={ro}
                title={main?.product ? (main.product.display_name ?? main.product.model ?? main.product.name ?? '') : ''}>
            {main?.product ? (main.product.display_name ?? main.product.model ?? main.product.name ?? '—') : '—'}
          </span>
        ) : (
          <CellSelect
            value={main?.product_id ?? ''}
            triggerClassName={inp}
            options={products.map((p) => ({ value: p.id, label: p.display_name ?? p.model ?? p.name ?? '—' }))}
            onChange={(v) => {
              const p = products.find((pp) => pp.id === v);
              // Mahsulot almashganda narx YANGI mahsulotdan olinadi,
              // eski serial tozalanadi va sklad rezervi bo'shatiladi
              // (ular eski mahsulotga tegishli edi).
              const items = itemsWith({
                product_id: v,
                unit_price_usd: num(p?.base_price_usd),
                serial_id: null,
                bunker_direction: p?.product_type === 'additional' ? null : (main?.bunker_direction ?? null),
              });
              patchOrder(o.inventory_id ? { items, inventory_id: null } : { items });
            }}
          />
        )}
      </td>
      <td className={cell}>
        {isAdditionalMain ? (
          <span className="text-ink-soft">—</span>
        ) : locked ? (
          <span className={ro}>{main?.bunker_direction === 'right' ? "O'NG" : main?.bunker_direction === 'left' ? 'CHAP' : '—'}</span>
        ) : (
          <CellSelect
            value={main?.bunker_direction ?? ''}
            triggerClassName={inp}
            allowEmpty
            options={[{ value: 'right', label: "O'NG" }, { value: 'left', label: 'CHAP' }]}
            onChange={(v) => saveMain({ bunker_direction: v || null })}
          />
        )}
      </td>

      {/* Narx / soni / chegirma */}
      <td className={cell + ' text-right text-ink-soft'} title="Narx mahsulotlar bo'limidan olinadi — bu yerda o'zgartirilmaydi">
        {num(main?.unit_price_usd)}
      </td>
      <td className={cell + ' text-right'}>
        {locked ? <span className={ro}>{main?.quantity ?? 1}</span> : (
          <input type="number" min={1} defaultValue={main?.quantity ?? 1}
                 className={inp + ' text-right'} onBlur={blurNum(main?.quantity ?? 1, 'quantity')} />
        )}
      </td>
      <td className={cell + ' text-right'}>
        {locked ? <span className={ro}>{fmtInt(main?.discount) || '0'}</span> : (
          <input type="text" inputMode="numeric" defaultValue={fmtInt(main?.discount)} placeholder="0"
                 className={inp + ' text-right'}
                 onChange={(e) => { e.target.value = fmtInt(e.target.value); }}
                 onBlur={blurNum(main?.discount ?? 0, 'discount')} />
        )}
      </td>

      {/* Hisob */}
      <td className={cell + ' text-right font-medium'}>{formatUZS(o.items_total_uzs)}</td>
      <td className={cell + ' text-right text-success'}>
        <span className="inline-flex items-center gap-1 justify-end">
          {formatUZS(o.paid_uzs)}
          {balance > 0 && can('finance:write') && (
            <button onClick={() => onPay(o.id)} className="p-0.5 rounded hover:bg-primary/10 text-primary" title="To'lov qo'shish (moliya)">
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
        {locked ? (
          <span className={'inline-block rounded-full px-2.5 py-1 text-xs font-medium ' +
            (STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-700')}
                title="Yetkazilgan buyurtma o'zgartirilmaydi">
            {STATUS_OPTIONS.find((st) => st.value === status)?.label ?? status}
          </span>
        ) : (
          <CellSelect
            value={status}
            onChange={onStatusChange}
            options={STATUS_OPTIONS}
            triggerClassName={'rounded-full px-2.5 py-1 text-xs font-medium cursor-pointer ' +
              (STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-700')}
            valueClassName="text-xs font-medium"
          />
        )}
      </td>

      <td className={cell}>
        <button onClick={() => navigate(`/orders/${o.id}`)} className="p-1 rounded hover:bg-black/5 text-ink-soft" title="Ochish">
          <ExternalLink size={14} />
        </button>
      </td>
    </tr>
  );
}
