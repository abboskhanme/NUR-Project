import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { usePermissions } from '@/lib/permissions';
import toast from 'react-hot-toast';
import { ExternalLink, Plus, ListPlus, Check } from 'lucide-react';

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
  unit_price_usd: string; unit_price_uzs: string; discount_usd: string; discount: string; serial_id?: string | null;
}
export interface OrderFull {
  id: string; code: string; status: string; order_date: string; delivered_at?: string | null;
  queue_position?: number | null;
  in_queue?: boolean;
  pickup_date?: string | null;
  exchange_rate: string;
  inventory_id?: string | null;
  unit_uid?: string | null;
  delivery_address?: string | null;
  customer?: { id: string; full_name: string; phone: string; region?: string | null; address?: string | null; is_dealer?: boolean } | null;
  items: OrderItem[];
  items_total_uzs: string; paid_uzs: string; balance_uzs: string;
  has_stamp_ruc: boolean; has_stamp_avt: boolean; has_online: boolean; has_video: boolean;
}

// Status option keys — resolved with t() at render time so language switching works live.
// "ready" (Tayyor) olib tashlandi — buyurtma to'g'ridan-to'g'ri new → delivered ketadi.
const STATUS_OPTION_KEYS = [
  { value: 'new', labelKey: 'sales.statusNew' },
  { value: 'delivered', labelKey: 'sales.statusDelivered' },
  { value: 'rejected', labelKey: 'sales.statusRejected' },
];

const STATUS_STYLES: Record<string, string> = {
  new: 'bg-blue-100 text-blue-700',
  ready: 'bg-teal-100 text-teal-700',   // eski (legacy) buyurtmalar uchun
  delivered: 'bg-emerald-100 text-emerald-700',
  rejected: 'bg-gray-200 text-gray-600',
};

// Qator foni (yengil tus — matn o'qiladigan qoladi):
//   rejected                          → kulrang (bekor qilingan)
//   delivered                         → yashil (yetkazilgan)
//   to'langan, hali yuk chiqmagan     → qizil (chiqarishga tayyor)
//   aks holda (yangi, to'lanmagan)    → oq
function rowTint(status: string, balance: number): string {
  if (status === 'rejected') return 'bg-gray-200/70 hover:bg-gray-200';
  if (status === 'delivered') return 'bg-emerald-50 hover:bg-emerald-100/60';
  if (balance <= 0) return 'bg-red-50 hover:bg-red-100/60';
  return 'hover:bg-gray-50';
}

const num = (s: string | number | null | undefined) => {
  const n = parseFloat(String(s ?? '')); return Number.isNaN(n) ? 0 : n;
};
// Dollar summasi uchun — raqam va bitta o'nlik nuqta
const decStr = (s: string | number | null | undefined) =>
  String(s ?? '').replace(/[^\d.]/g, '').replace(/(\..*)\./g, '$1');

export default function OrdersTable({
  orders, products, onChanged, onPay,
}: {
  orders: OrderFull[];
  products: ProductOpt[];
  onChanged: () => void;
  onPay: (orderId: string) => void;
}) {
  const { t } = useTranslation();

  return (
    <div className="overflow-x-auto -mx-2">
      <table className="text-sm border-collapse table-fixed w-[2000px]">
        <colgroup>
          <col style={{ width: 44 }} />
          <col style={{ width: 70 }} />
          <col style={{ width: 140 }} />
          <col style={{ width: 140 }} />
          <col style={{ width: 170 }} />
          <col style={{ width: 140 }} />
          <col style={{ width: 180 }} />
          <col style={{ width: 180 }} />
          <col style={{ width: 96 }} />
          <col style={{ width: 70 }} />
          <col style={{ width: 64 }} />
          <col style={{ width: 120 }} />
          <col style={{ width: 140 }} />
          <col style={{ width: 160 }} />
          <col style={{ width: 140 }} />
          <col style={{ width: 140 }} />
          <col style={{ width: 50 }} />
        </colgroup>
        <thead className="text-left text-ink-soft border-b border-black/10">
          <tr className="[&>th]:py-2 [&>th]:px-2 [&>th]:font-medium [&>th]:whitespace-nowrap">
            <th></th>
            <th>{t('sales.colUnitId')}</th>
            <th>{t('sales.colOrder')}</th>
            <th>{t('sales.colDelivered')}</th>
            <th>{t('sales.colCustomer')}</th>
            <th>{t('sales.colPhone')}</th>
            <th>{t('sales.colAddress')}</th>
            <th>{t('sales.colModel')}</th>
            <th>{t('sales.colDirection')}</th>
            <th className="text-right">{t('sales.colPriceUsd')}</th>
            <th className="text-right">{t('sales.colQty')}</th>
            <th className="text-right">{t('sales.colDiscount')}</th>
            <th className="text-right">{t('sales.colTotal')}</th>
            <th className="text-right">{t('sales.colPaid')}</th>
            <th className="text-right">{t('sales.colBalance')}</th>
            <th>{t('sales.colStatus')}</th>
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
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { can } = usePermissions();
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState(o.status);
  useEffect(() => setStatus(o.status), [o.status]);

  const mainIdx = Math.max(0, o.items.findIndex((it) => it.product?.product_type !== 'additional'));
  const main: OrderItem | undefined = o.items[mainIdx];
  const isAdditionalMain = main?.product?.product_type === 'additional';
  const balance = num(o.balance_uzs);
  const locked = o.status === 'delivered';

  async function patchOrder(body: Record<string, unknown>) {
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}`, body);
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

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
        discount_usd: num(it.discount_usd),
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

  // Ombor ID raqami — bo'sh kotyolni band qiladi. Xato bo'lsa qiymatni qaytaramiz.
  async function saveUnitUid(e: React.FocusEvent<HTMLInputElement>) {
    const v = e.target.value.trim();
    if (v === (o.unit_uid ?? '')) return;
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}`, { unit_uid: v || null });
      onChanged();
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || t('common.error'));
      e.target.value = o.unit_uid ?? '';
    } finally {
      setSaving(false);
    }
  }

  async function patchCustomer(body: Record<string, unknown>) {
    if (!o.customer) return;
    setSaving(true);
    try {
      await api.patch(`/customers/${o.customer.id}`, body);
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

  async function onStatusChange(next: string) {
    if (next === 'delivered' && balance > 0 && !o.customer?.is_dealer) {
      toast.error(t('sales.notPaidError'));
      setStatus(o.status);
      return;
    }
    setStatus(next);
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}`, { status: next });
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
      setStatus(o.status);
    } finally {
      setSaving(false);
    }
  }

  const blurNum = (orig: string | number, key: 'unit_price_usd' | 'quantity' | 'discount') =>
    (e: React.FocusEvent<HTMLInputElement>) => {
      const v = key === 'quantity'
        ? (parseInt(e.target.value, 10) || 1)
        : num(e.target.value.replace(/\s/g, ''));
      if (v === num(orig)) return;
      if (key === 'discount' && main) {
        // chegirma dollarda — narx ($) × soni dan oshmasligi kerak
        const subtotalUsd = num(main.unit_price_usd) * (main.quantity || 1);
        if (v < 0 || v > subtotalUsd) {
          toast.error(t('sales.discountExceedsRow'));
          e.target.value = String(num(orig));
          return;
        }
        saveMain({ discount_usd: v });
        return;
      }
      saveMain({ [key]: v });
    };

  // Status options resolved at render time.
  // Eski "ready" buyurtma bo'lsa — uni ham ko'rsatamiz (ko'chirib olish uchun).
  const statusKeys = status === 'ready'
    ? [{ value: 'ready', labelKey: 'sales.statusReady' }, ...STATUS_OPTION_KEYS]
    : STATUS_OPTION_KEYS;
  const statusOptions = statusKeys.map((s) => ({ value: s.value, label: t(s.labelKey) }));
  // Direction options resolved at render time
  const dirOptions = [
    { value: 'right', label: t('sales.dirRightFull') },
    { value: 'left', label: t('sales.dirLeftFull') },
  ];

  const cell = 'px-2 py-1 align-middle whitespace-nowrap';
  const inp = 'w-full bg-transparent border border-transparent hover:border-black/10 focus:border-primary rounded px-1 py-0.5 outline-none';
  const ro = 'block px-1 py-0.5 border border-transparent truncate';

  return (
    <tr className={'border-b border-black/5 transition-colors ' + rowTint(status, balance) + (saving ? ' opacity-60' : '')}>
      {/* Navbatga olish — qator boshida, yorqin */}
      <td className={cell + ' text-center'}>
        <QueueButton o={o} onChanged={onChanged} />
      </td>
      {/* Ombor ID raqami — navbat raqami o'rniga; bo'sh kotyolni band qiladi */}
      <td className={cell + ' text-center'}>
        {locked ? (
          <span className={ro + ' font-mono text-center'} title={t('sales.unitIdReadOnly')}>
            {o.unit_uid || '—'}
          </span>
        ) : (
          <input
            key={o.unit_uid ?? ''}
            defaultValue={o.unit_uid ?? ''}
            className={inp + ' text-center font-mono'}
            placeholder={t('sales.unitIdPlaceholder')}
            title={t('sales.unitIdEdit')}
            onBlur={saveUnitUid}
          />
        )}
      </td>
      {/* Dates */}
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

      {/* Customer */}
      <td className={cell}>
        {locked ? (
          <span className={ro} title={o.customer?.full_name ?? ''}>{o.customer?.full_name ?? '—'}</span>
        ) : (
          <input defaultValue={o.customer?.full_name ?? ''} className={inp}
                 onBlur={(e) => e.target.value !== (o.customer?.full_name ?? '') && patchCustomer({ full_name: e.target.value })} />
        )}
      </td>
      {/* Phone — read-only */}
      <td className={cell + ' text-ink-soft'} title={t('sales.phoneReadOnly')}>
        {o.customer?.phone ? formatPhone(o.customer.phone) : '—'}
      </td>
      <td className={cell}>
        {(() => {
          const hasDelivery = !!(o.delivery_address && o.delivery_address.trim());
          const shown = hasDelivery ? o.delivery_address! : (o.customer?.address ?? '');
          if (locked) return <span className={ro} title={shown}>{shown || '—'}</span>;
          return (
            <input
              key={hasDelivery ? 'delivery' : 'customer'}
              defaultValue={shown}
              className={inp}
              title={hasDelivery ? t('sales.deliveryAddressTitle') : t('sales.customerAddressTitle')}
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

      {/* Product */}
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
              const items = itemsWith({
                product_id: v,
                unit_price_usd: num(p?.base_price_usd),
                serial_id: null,
                bunker_direction: p?.product_type === 'additional' ? null : (main?.bunker_direction ?? null),
              });
              patchOrder(o.unit_uid ? { items, unit_uid: null } : { items });
            }}
          />
        )}
      </td>
      <td className={cell}>
        {isAdditionalMain ? (
          <span className="text-ink-soft">—</span>
        ) : locked ? (
          <span className={ro}>
            {main?.bunker_direction === 'right' ? t('sales.dirRightFull') : main?.bunker_direction === 'left' ? t('sales.dirLeftFull') : '—'}
          </span>
        ) : (
          <CellSelect
            value={main?.bunker_direction ?? ''}
            triggerClassName={inp}
            allowEmpty
            options={dirOptions}
            onChange={(v) => saveMain({ bunker_direction: v || null })}
          />
        )}
      </td>

      {/* Price / qty / discount */}
      <td className={cell + ' text-right text-ink-soft'} title={t('sales.priceReadOnly')}>
        {num(main?.unit_price_usd)}
      </td>
      <td className={cell + ' text-right'}>
        {locked ? <span className={ro}>{main?.quantity ?? 1}</span> : (
          <input type="number" min={1} defaultValue={main?.quantity ?? 1}
                 className={inp + ' text-right'} onBlur={blurNum(main?.quantity ?? 1, 'quantity')} />
        )}
      </td>
      <td className={cell + ' text-right'}>
        {locked ? <span className={ro}>{num(main?.discount_usd) ? '$' + num(main?.discount_usd) : '$0'}</span> : (
          <input type="text" inputMode="decimal" defaultValue={num(main?.discount_usd) || ''} placeholder="$ 0"
                 className={inp + ' text-right'}
                 onChange={(e) => { e.target.value = decStr(e.target.value); }}
                 onBlur={blurNum(main?.discount_usd ?? 0, 'discount')} />
        )}
      </td>

      {/* Totals */}
      <td className={cell + ' text-right font-medium'}>{formatUZS(o.items_total_uzs)}</td>
      <td className={cell + ' text-right text-success'}>
        <span className="inline-flex items-center gap-1 justify-end">
          {formatUZS(o.paid_uzs)}
          {balance > 0 && can('finance:write') && (
            <button onClick={() => onPay(o.id)} className="p-0.5 rounded hover:bg-primary/10 text-primary" title={t('sales.addPaymentTooltip')}>
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
                title={t('sales.blockedDeliverTitle')}>
            {statusOptions.find((st) => st.value === status)?.label ?? status}
          </span>
        ) : (
          <CellSelect
            value={status}
            onChange={onStatusChange}
            options={statusOptions}
            triggerClassName={'rounded-full px-2.5 py-1 text-xs font-medium cursor-pointer ' +
              (STATUS_STYLES[status] ?? 'bg-gray-100 text-gray-700')}
            valueClassName="text-xs font-medium"
          />
        )}
      </td>

      <td className={cell}>
        <div className="flex items-center justify-center">
          <button onClick={() => navigate(`/orders/${o.id}`)} className="p-1 rounded hover:bg-black/5 text-ink-soft" title={t('sales.openOrder')}>
            <ExternalLink size={14} />
          </button>
        </div>
      </td>
    </tr>
  );
}

function QueueButton({ o, onChanged }: { o: OrderFull; onChanged: () => void }) {
  const { t } = useTranslation();
  const [busy, setBusy] = useState(false);
  if (o.status === 'delivered' || o.status === 'rejected') return null;

  // Bir bosishda navbatga olish/chiqarish — sana so'ralmaydi (majburiy emas).
  async function toggleQueue() {
    setBusy(true);
    try {
      if (o.in_queue) {
        await api.post(`/orders/${o.id}/from-queue`);
      } else {
        await api.post(`/orders/${o.id}/to-queue`, {});
        toast.success(t('sales.queueAdded'));
      }
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setBusy(false);
    }
  }

  return o.in_queue ? (
    <button onClick={toggleQueue} disabled={busy}
            className="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-emerald-500 text-white shadow-sm ring-1 ring-emerald-600/20 hover:bg-emerald-600 transition disabled:opacity-50"
            title={t('sales.removeFromQueue')}>
      <Check size={16} strokeWidth={3} />
    </button>
  ) : (
    <button onClick={toggleQueue} disabled={busy}
            className="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-primary/10 text-primary ring-1 ring-primary/25 hover:bg-primary hover:text-white transition disabled:opacity-50"
            title={t('sales.addToQueue')}>
      <ListPlus size={15} strokeWidth={2.5} />
    </button>
  );
}
