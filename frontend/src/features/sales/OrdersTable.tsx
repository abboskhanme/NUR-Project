import { useEffect, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { usePermissions } from '@/lib/permissions';
import toast from 'react-hot-toast';
import { ExternalLink, Plus, Pencil, ListPlus, Check, Printer } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS, formatPhone, formatDate } from '@/lib/format';
import { CellDate, CellSelect } from '@/components/ui/TablePickers';
import ReceiptModal from './ReceiptModal';

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
  salesperson_id?: string | null;
  salesperson_name?: string | null;
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

// Status option labels.
// "ready" (Tayyor) olib tashlandi — buyurtma to'g'ridan-to'g'ri new → delivered ketadi.
const STATUS_OPTIONS = [
  { value: 'new', label: 'Navbatda' },
  { value: 'delivered', label: 'Yetkazildi' },
  { value: 'rejected', label: 'Rad etildi' },
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
interface Salesperson { id: string; full_name: string }

// Ustun kengliklari — jadval, colgroup va yuqoridagi sinxron scrollbar
// SHU massivdan hisoblanadi (bitta manba), aks holda ular orasidagi
// nomuvofiqlik oxirgi ustunni (Chek/Ochish tugmalari) scroll orqali
// hech qachon to'liq ko'rinmaydigan qilib qo'yadi.
const COL_WIDTHS = [44, 210, 140, 140, 170, 140, 180, 280, 96, 70, 64, 120, 140, 160, 140, 140, 80];
const TABLE_WIDTH = COL_WIDTHS.reduce((a, b) => a + b, 0);

// Dollar summasi uchun — raqam va bitta o'nlik nuqta
const decStr = (s: string | number | null | undefined) =>
  String(s ?? '').replace(/[^\d.]/g, '').replace(/(\..*)\./g, '$1');

// So'm summasi uchun — faqat butun qism (nuqtagacha), har 3 xonaga bo'shliq (1 234 567).
// "18128340.00" -> "18 128 340" (o'nlik qism tashlanadi, so'm butun sonda yuritiladi).
const somStr = (s: string | number | null | undefined) => {
  const digits = String(s ?? '').split('.')[0].replace(/[^\d]/g, '').replace(/^0+(?=\d)/, '');
  return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
};

export default function OrdersTable({
  orders, products, onChanged, onPay,
}: {
  orders: OrderFull[];
  products: ProductOpt[];
  onChanged: () => void;
  onPay: (orderId: string) => void;
}) {
  const { canSpecial } = usePermissions();
  // Sotuvchi tanlovi — buyurtma override ruxsati bo'lganlarga (super-admin yoki system:order_override)
  const canOrderOverride = canSpecial('system:order_override');
  const spQ = useQuery<Salesperson[]>({
    queryKey: ['order-salespeople'],
    queryFn: () => api.get('/orders/salespeople').then((r) => r.data),
    enabled: canOrderOverride,
  });
  const salespeople = spQ.data ?? [];

  // Gorizontal scroll'ni ro'yxat tepasiga chiqaramiz: tepadagi ko'rinadigan chiziq
  // jadval bilan sinxron suriladi, pastdagi (jadval ichidagi) scrollbar yashiriladi.
  const topRef = useRef<HTMLDivElement>(null);
  const bodyRef = useRef<HTMLDivElement>(null);
  function syncFromTop() {
    if (topRef.current && bodyRef.current) bodyRef.current.scrollLeft = topRef.current.scrollLeft;
  }
  function syncFromBody() {
    if (topRef.current && bodyRef.current) topRef.current.scrollLeft = bodyRef.current.scrollLeft;
  }

  return (
    <div className="-mx-2">
      {/* Tepadagi gorizontal scroll — jadval bilan sinxron, DOIMIY ko'rinadi
          (touchpadsiz, sichqoncha bilan sudrab surish uchun). macOS overlay
          scrollbar'i yashirinmasligi uchun maxsus uslub beramiz. */}
      <div ref={topRef} onScroll={syncFromTop}
           className="overflow-x-scroll sticky top-16 z-[5] bg-card
                      [scrollbar-width:auto]
                      [&::-webkit-scrollbar]:h-3
                      [&::-webkit-scrollbar-track]:bg-black/5 [&::-webkit-scrollbar-track]:rounded-full
                      [&::-webkit-scrollbar-thumb]:bg-black/30 [&::-webkit-scrollbar-thumb]:rounded-full
                      hover:[&::-webkit-scrollbar-thumb]:bg-black/45">
        <div className="h-px" style={{ width: TABLE_WIDTH }} />
      </div>
      <div ref={bodyRef} onScroll={syncFromBody}
           className="overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      <table className="text-sm border-collapse table-fixed" style={{ width: TABLE_WIDTH }}>
        <colgroup>
          {COL_WIDTHS.map((w, i) => <col key={i} style={{ width: w }} />)}
        </colgroup>
        <thead className="text-left text-ink-soft border-b border-black/10">
          <tr className="[&>th]:py-2 [&>th]:px-2 [&>th]:font-medium [&>th]:whitespace-nowrap">
            <th></th>
            <th>ID raqami</th>
            <th>Buyurtma</th>
            <th>Yetkazilgan</th>
            <th>Mijoz</th>
            <th>Telefon</th>
            <th>Manzil</th>
            <th>Model</th>
            <th>Yo'nalish</th>
            <th className="text-right">Narx $</th>
            <th className="text-right">Soni</th>
            <th className="text-right">Chegirma ($)</th>
            <th className="text-right">Jami</th>
            <th className="text-right">To'langan</th>
            <th className="text-right">Qoldiq</th>
            <th>Status</th>
            <th className="sticky right-0 z-[6] bg-card border-l border-black/10"></th>
          </tr>
        </thead>
        <tbody>
          {orders.map((o) => (
            <Row key={o.id} o={o} products={products} salespeople={salespeople}
                 onChanged={onChanged} onPay={onPay} />
          ))}
        </tbody>
      </table>
      </div>
    </div>
  );
}

function Row({
  o, products, salespeople, onChanged, onPay,
}: {
  o: OrderFull; products: ProductOpt[]; salespeople: Salesperson[];
  onChanged: () => void; onPay: (id: string) => void;
}) {
  const navigate = useNavigate();
  const { can, canSpecial } = usePermissions();
  const canOrderOverride = canSpecial('system:order_override');
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState(o.status);
  const [receiptOpen, setReceiptOpen] = useState(false);
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
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  // Super-admin: Jami / To'langan (so'm) ni qo'lda to'g'rilash (import tuzatish).
  // Yetkazilgan buyurtmada ham ishlaydi.
  async function overrideAmounts(body: { total_uzs?: number; paid_uzs?: number }) {
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}/override-amounts`, body);
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
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
  // Sotuvchini biriktirish (faqat super-admin) — yetkazilgan buyurtmada ham ishlaydi
  async function saveSalesperson(id: string) {
    if ((id || null) === (o.salesperson_id ?? null)) return;
    setSaving(true);
    try {
      await api.patch(`/orders/${o.id}/salesperson`, { salesperson_id: id || null });
      onChanged();
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  async function saveUnitUid(e: React.FocusEvent<HTMLInputElement>) {
    const v = e.target.value.trim();
    if (v === (o.unit_uid ?? '')) return;
    setSaving(true);
    try {
      // Yetkazilgan buyurtmada (locked) ID'ni alohida endpoint orqali — ombor talab
      // qilinmaydi, snapshot sifatida yoziladi. Aktivda — oddiy yo'l (ombor bog'lanadi).
      const url = locked ? `/orders/${o.id}/unit-uid` : `/orders/${o.id}`;
      await api.patch(url, { unit_uid: v || null });
      onChanged();
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || "Xatolik yuz berdi");
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
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setSaving(false);
    }
  }

  async function onStatusChange(next: string) {
    if (next === 'delivered' && balance > 0 && !o.customer?.is_dealer) {
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
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
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
          toast.error("Chegirma mahsulot summasidan oshib ketdi");
          e.target.value = String(num(orig));
          return;
        }
        saveMain({ discount_usd: v });
        return;
      }
      saveMain({ [key]: v });
    };

  // Status options.
  // Eski "ready" buyurtma bo'lsa — uni ham ko'rsatamiz (ko'chirib olish uchun).
  const statusOptions = status === 'ready'
    ? [{ value: 'ready', label: "Tayyor bo'ldi" }, ...STATUS_OPTIONS]
    : STATUS_OPTIONS;
  // Direction options
  const dirOptions = [
    { value: 'right', label: "O'NGA" },
    { value: 'left', label: "CHAPGA" },
  ];

  const cell = 'px-2 py-1 align-middle whitespace-nowrap';
  const inp = 'w-full bg-transparent border border-transparent hover:border-black/10 focus:border-primary rounded px-1 py-0.5 outline-none';
  const ro = 'block px-1 py-0.5 border border-transparent truncate';

  const tint = rowTint(status, balance);

  return (
    <tr className={'border-b border-black/5 transition-colors ' + tint + (saving ? ' opacity-60' : '')}>
      {/* Navbatga olish — qator boshida, yorqin */}
      <td className={cell + ' text-center'}>
        <QueueButton o={o} onChanged={onChanged} />
      </td>
      {/* Ombor ID raqami — navbat raqami o'rniga; bo'sh kotyolni band qiladi */}
      <td className={cell}>
        <div className="flex items-center gap-1.5">
          {/* Sotuvchi to'liq ismi hammaga ko'rinadi; override ruxsatli rol dropdown orqali
              o'zgartiradi (yetkazilganda ham), boshqalar faqat ko'radi (read-only). */}
          {canOrderOverride ? (
            <CellSelect
              value={o.salesperson_id ?? ''}
              onChange={saveSalesperson}
              options={salespeople.map((s) => ({ value: s.id, label: s.full_name }))}
              allowEmpty
              emptyLabel="—"
              placeholder="—"
              hideChevron
              triggerClassName="shrink-0 max-w-[124px] h-5 px-2 rounded-full bg-primary/10 text-primary text-[11px] font-semibold leading-5"
              valueClassName="truncate"
            />
          ) : (
            <span
              className="shrink-0 inline-block max-w-[124px] truncate h-5 px-2 rounded-full bg-primary/10 text-primary text-[11px] font-semibold leading-5"
              title={o.salesperson_name ?? ''}
            >
              {o.salesperson_name || '—'}
            </span>
          )}
          {/* Aktiv buyurtmada ID'ni menejer (orders:write) tahrirlaydi; YETKAZILGAN
              buyurtmada esa override ruxsatli rol (eski/ombordan chiqib ketgan ID'lar uchun). */}
          {!(locked ? canOrderOverride : can('orders:write')) ? (
            <span className={ro + ' font-mono text-center flex-1'} title="Yetkazilgan — ID raqamini o'zgartirib bo'lmaydi">
              {o.unit_uid || '—'}
            </span>
          ) : (
            <input
              key={o.unit_uid ?? ''}
              defaultValue={o.unit_uid ?? ''}
              className={inp + ' text-center font-mono flex-1 min-w-0'}
              placeholder="ID"
              title="Ombor ID raqami — bo'sh kotyolni band qiladi"
              onBlur={saveUnitUid}
            />
          )}
        </div>
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
      <td className={cell + ' text-ink-soft'} title="Telefon raqami (tahrirlanmaydi)">
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
              title={hasDelivery ? "Yetkazish manzili (buyurtma)" : "Mijoz manzili"}
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
      <td className={cell + ' !whitespace-normal'}>
        {locked ? (
          <span className="block px-1 py-0.5 border border-transparent whitespace-normal break-words leading-tight"
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
            {main?.bunker_direction === 'right' ? "O'NGA" : main?.bunker_direction === 'left' ? "CHAPGA" : '—'}
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
        {locked ? <span className={ro}>{num(main?.discount_usd) ? '$' + num(main?.discount_usd) : '$0'}</span> : (
          <input type="text" inputMode="decimal" defaultValue={num(main?.discount_usd) || ''} placeholder="$ 0"
                 className={inp + ' text-right'}
                 onChange={(e) => { e.target.value = decStr(e.target.value); }}
                 onBlur={blurNum(main?.discount_usd ?? 0, 'discount')} />
        )}
      </td>

      {/* Totals — super-admin (order_override) so'mda Jami va To'langan'ni qo'lda
          to'g'rilashi mumkin (eski importda 0 bo'lib qolganlar uchun). */}
      <td className={cell + ' text-right font-medium'}>
        {canOrderOverride ? (
          <input type="text" inputMode="numeric" defaultValue={somStr(o.items_total_uzs)}
                 key={'tot-' + o.items_total_uzs} placeholder="0"
                 title="Jami summa (so'm) — super-admin tuzatishi (eski import uchun)"
                 className={inp + ' text-right'}
                 onChange={(e) => { e.target.value = somStr(e.target.value); }}
                 onBlur={(e) => { const v = num(e.target.value.replace(/\s/g, '')); if (v === num(o.items_total_uzs)) return; overrideAmounts({ total_uzs: v }); }} />
        ) : formatUZS(o.items_total_uzs)}
      </td>
      <td className={cell + ' text-right text-success'}>
        {/* To'langan — barcha to'lovlar (real + eski import) modal orqali boshqariladi.
            Super-admin (order_override): ✎ tugma HAR DOIM modalni ochadi (yetkazilgan/0
            qoldiqda ham). Oddiy foydalanuvchi: qarz bo'lsa "+" orqali to'lov qo'shadi. */}
        <span className="inline-flex items-center gap-1 justify-end">
          {formatUZS(o.paid_uzs)}
          {canOrderOverride ? (
            <button onClick={() => onPay(o.id)} className="p-0.5 rounded hover:bg-primary/10 text-primary" title="To'lovlarni boshqarish (qo'shish/tahrirlash)">
              <Pencil size={13} />
            </button>
          ) : balance > 0 && can('orders:write') ? (
            <button onClick={() => onPay(o.id)} className="p-0.5 rounded hover:bg-primary/10 text-primary" title="To'lov qo'shish (moliya)">
              <Plus size={13} />
            </button>
          ) : null}
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
                title="Buyurtma to'liq to'lanmagan">
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

      {/* Sticky — gorizontal scroll qanchalik uzun bo'lmasin, bu tugmalar doim
          ko'rinib turadi (2240px kenglikdagi jadvalda oxirgi ustun ko'zdan
          qochib, "tugma yo'q" deb tuyulishining oldini olish uchun). */}
      <td className={cell + ' sticky right-0 z-[2] bg-card border-l border-black/10'}>
        <div className="flex items-center justify-center gap-0.5">
          <button onClick={() => setReceiptOpen(true)} className="p-1 rounded hover:bg-accent/10 text-accent" title="Chek chiqarish (termal printer)">
            <Printer size={14} />
          </button>
          <button onClick={() => navigate(`/orders/${o.id}`)} className="p-1 rounded hover:bg-black/5 text-ink-soft" title="Ochish">
            <ExternalLink size={14} />
          </button>
        </div>
        {receiptOpen && <ReceiptModal order={o} onClose={() => setReceiptOpen(false)} />}
      </td>
    </tr>
  );
}

function QueueButton({ o, onChanged }: { o: OrderFull; onChanged: () => void }) {
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
        toast.success("Navbatga qo'shildi");
      }
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik yuz berdi");
    } finally {
      setBusy(false);
    }
  }

  return o.in_queue ? (
    <button onClick={toggleQueue} disabled={busy}
            className="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-emerald-500 text-white shadow-sm ring-1 ring-emerald-600/20 hover:bg-emerald-600 transition disabled:opacity-50"
            title="Navbatdan chiqarish">
      <Check size={16} strokeWidth={3} />
    </button>
  ) : (
    <button onClick={toggleQueue} disabled={busy}
            className="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-primary/10 text-primary ring-1 ring-primary/25 hover:bg-primary hover:text-white transition disabled:opacity-50"
            title="Navbatga o'tkazish">
      <ListPlus size={15} strokeWidth={2.5} />
    </button>
  );
}
