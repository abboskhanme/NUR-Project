import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  ArrowLeft, Pencil, Phone, MapPin, User, Package, Plus, Trash2, ExternalLink, ShieldCheck,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import StatusBadge from '@/components/ui/StatusBadge';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatDate, formatUZS, formatUSD, formatPhone } from '@/lib/format';
import { computeWarranty, WARRANTY_META } from '@/features/service/warranty';
import OrderModal, { OrderEditData } from '@/features/sales/OrderModal';
import PaymentModal from '@/features/sales/PaymentModal';

interface ProductMini { id: string; product_type?: string; model?: string | null; name?: string | null; unit?: string | null; kvm?: number | null; display_name?: string; bunker_direction?: string | null; }
interface Item {
  id: string; product_id: string; product?: ProductMini | null;
  bunker_direction?: string | null;
  quantity: number; unit_price_usd: string; unit_price_uzs: string; discount: string; total_uzs: string;
}

const DIR_LABEL = (d?: string | null) => (d === 'right' ? 'O\'NGA' : d === 'left' ? 'CHAPGA' : '—');
interface Payment {
  id: string; date: string; amount: string; currency: string;
  amount_uzs_equiv: string; method?: string | null; note?: string | null;
}
interface OrderDetail {
  id: string; code: string; status: string; order_date: string; delivered_at?: string | null;
  customer?: { id: string; full_name: string; phone: string; region?: string | null; city?: string | null; address?: string | null } | null;
  inventory?: { id: string; unique_id: string; status: string } | null;
  area_m2?: number | null; bunker_direction?: string | null; delivery_address?: string | null;
  exchange_rate: string; payment_type?: string | null; note?: string | null;
  has_stamp_ruc: boolean; has_stamp_avt: boolean; has_online: boolean; has_video: boolean;
  items: Item[]; payments: Payment[];
  items_total_uzs: string; paid_uzs: string; balance_uzs: string;
}

const NEXT_STATUS: Record<string, Array<{ value: string; label: string; danger?: boolean }>> = {
  new: [
    { value: 'ready', label: 'Tayyor bo\'ldi' },
    { value: 'rejected', label: 'Rad etish', danger: true },
  ],
  ready: [
    { value: 'delivered', label: 'Yetkazildi' },
    { value: 'rejected', label: 'Rad etish', danger: true },
  ],
  delivered: [],
  rejected: [],
};

const METHOD_LABEL: Record<string, string> = { cash: 'Naqd', card: 'Karta', transfer: 'O\'tkazma' };

export default function OrderDetailPage() {
  const { orderId } = useParams<{ orderId: string }>();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [editing, setEditing] = useState(false);
  const [addingPayment, setAddingPayment] = useState(false);
  const [confirm, setConfirm] = useState<{
    title: string; message: string; confirmText: string;
    variant: 'danger' | 'primary'; action: () => Promise<void>;
  } | null>(null);
  const [confirmLoading, setConfirmLoading] = useState(false);

  const { data: o, isLoading } = useQuery<OrderDetail>({
    queryKey: ['order', orderId],
    queryFn: () => api.get(`/orders/${orderId}`).then((r) => r.data),
    enabled: !!orderId,
  });

  function refresh() {
    qc.invalidateQueries({ queryKey: ['order', orderId] });
    qc.invalidateQueries({ queryKey: ['orders'] });
  }

  function askChangeStatus(status: string, label: string) {
    setConfirm({
      title: 'Statusni o\'zgartirish',
      message: `Buyurtma statusi "${label}" ga o'zgartirilsinmi?`,
      confirmText: label,
      variant: 'primary',
      action: async () => {
        await api.post(`/orders/${orderId}/status`, { status });
        toast.success('Status yangilandi');
        refresh();
      },
    });
  }

  function askDeletePayment(pid: string) {
    setConfirm({
      title: 'To\'lovni o\'chirish',
      message: 'Ushbu to\'lov o\'chirilsinmi?',
      confirmText: 'O\'chirish',
      variant: 'danger',
      action: async () => {
        await api.delete(`/orders/${orderId}/payments/${pid}`);
        toast.success('O\'chirildi');
        refresh();
      },
    });
  }

  async function runConfirm() {
    if (!confirm) return;
    setConfirmLoading(true);
    try {
      await confirm.action();
      setConfirm(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setConfirmLoading(false);
    }
  }

  if (isLoading || !o) {
    return (
      <div className="space-y-4">
        <div className="h-8 w-40 rounded bg-black/5 animate-pulse" />
        <div className="h-40 rounded-lg bg-black/5 animate-pulse" />
      </div>
    );
  }

  const nexts = NEXT_STATUS[o.status] ?? [];
  const balance = parseFloat(o.balance_uzs || '0');

  const w = computeWarranty(o.delivered_at);
  const wm = WARRANTY_META[w.status];
  const wDays =
    w.status === 'active_full' ? ` · ${w.daysYear1} kun qoldi`
    : w.status === 'active_service_only' ? ` · ${w.daysYear3} kun qoldi`
    : '';

  return (
    <div className="space-y-4">
      <button onClick={() => navigate('/orders')} className="flex items-center gap-1.5 text-sm text-ink-soft hover:text-ink">
        <ArrowLeft size={16} /> Buyurtmalarga qaytish
      </button>

      {/* Header */}
      <Card>
        <div className="flex items-start justify-between flex-wrap gap-3">
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-bold">{o.code}</h1>
              <StatusBadge status={o.status} />
            </div>
            <div className="text-sm text-ink-soft mt-1">
              Sana: {formatDate(o.order_date)}
              {o.delivered_at && ` • Yetkazilgan: ${formatDate(o.delivered_at)}`}
            </div>
            <div className="mt-2">
              <span className={`badge ${wm.cls}`} title={wm.long}>
                <ShieldCheck size={12} className="mr-1" /> Servis kafolati: {wm.short}{wDays}
              </span>
            </div>
          </div>
          <button onClick={() => setEditing(true)} className="btn-ghost"><Pencil size={15} /> Tahrirlash</button>
        </div>

        {/* Status workflow */}
        {nexts.length > 0 && (
          <div className="flex flex-wrap gap-2 mt-4 pt-4 border-t border-black/5">
            {nexts.map((n) => {
              const blockedDeliver = n.value === 'delivered' && balance > 0;
              return (
                <button key={n.value}
                        disabled={blockedDeliver}
                        title={blockedDeliver ? "Buyurtma to'liq to'lanmagan" : undefined}
                        onClick={() => askChangeStatus(n.value, n.label)}
                        className={(n.danger ? 'btn-danger' : 'btn-primary') + ' text-sm py-1.5 disabled:opacity-50 disabled:cursor-not-allowed'}>
                  {n.label}
                </button>
              );
            })}
            {nexts.some((n) => n.value === 'delivered') && balance > 0 && (
              <span className="text-xs text-danger self-center">
                "Yetkazildi" uchun qoldiq to'liq to'lanishi kerak ({formatUZS(o.balance_uzs)})
              </span>
            )}
          </div>
        )}
      </Card>

      {/* Customer + spec */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card
          title="Mijoz"
          action={o.customer && (
            <button
              type="button"
              onClick={() => navigate(`/customers/${o.customer!.id}`)}
              className="btn-ghost text-sm flex items-center gap-1.5"
              title="Mijoz haqida batafsil"
            >
              <ExternalLink size={14} /> Profilni ochish
            </button>
          )}
        >
          {o.customer ? (
            <div className="space-y-1.5 text-sm">
              <div className="flex items-center gap-2 font-medium"><User size={14} className="text-ink/40" /> {o.customer.full_name}</div>
              <div className="flex items-center gap-2"><Phone size={14} className="text-ink/40" /> {formatPhone(o.customer.phone)}</div>
              <div className="flex items-center gap-2"><MapPin size={14} className="text-ink/40" />
                {[o.customer.region, o.customer.city].filter(Boolean).join(', ') || '—'}
              </div>
              {o.delivery_address && (
                <div className="flex items-start gap-2 text-ink-soft"><MapPin size={14} className="text-ink/40 mt-0.5" /> Yetkazish: {o.delivery_address}</div>
              )}
            </div>
          ) : <div className="text-sm text-ink-soft">—</div>}
        </Card>

        <Card title="Tafsilotlar">
          <div className="grid grid-cols-2 gap-y-2 gap-x-4 text-sm">
            <Detail label="Valyuta kursi" value={parseFloat(o.exchange_rate) ? formatUZS(o.exchange_rate) : '—'} />
            <Detail label="Mahsulotlar soni" value={String(o.items.length)} />
          </div>
          {o.note && <div className="mt-3 pt-3 border-t border-black/5 text-sm text-ink-soft whitespace-pre-line">{o.note}</div>}
        </Card>
      </div>

      {/* Items */}
      <Card title="Mahsulotlar">
        {o.items.length === 0 ? (
          <div className="text-sm text-ink-soft">Mahsulot yo'q</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Mahsulot</th>
                  <th className="py-2 pr-3 text-center">Soni</th>
                  <th className="py-2 pr-3 text-right">Dona narxi</th>
                  <th className="py-2 pr-3 text-right">Chegirma</th>
                  <th className="py-2 pr-3 text-right">Jami</th>
                </tr>
              </thead>
              <tbody>
                {o.items.map((it) => (
                  <tr key={it.id} className="border-b border-black/5">
                    <td className="py-2 pr-3">
                      <span className="flex items-center gap-2"><Package size={14} className="text-ink/40" />
                        {it.product ? (it.product.display_name ?? it.product.model ?? it.product.name ?? '—') : it.product_id.slice(0, 8)}
                        {it.product?.product_type !== 'additional' && DIR_LABEL(it.bunker_direction) !== '—' && (
                          <span className="text-ink-soft">{DIR_LABEL(it.bunker_direction)}</span>
                        )}
                      </span>
                    </td>
                    <td className="py-2 pr-3 text-center">{it.quantity}</td>
                    <td className="py-2 pr-3 text-right">{formatUSD(it.unit_price_usd)}</td>
                    <td className="py-2 pr-3 text-right">{formatUZS(it.discount)}</td>
                    <td className="py-2 pr-3 text-right font-medium">{formatUZS(it.total_uzs)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <div className="mt-4 pt-3 border-t border-black/5 grid grid-cols-3 gap-3 text-sm">
          <Total label="Umumiy" value={formatUZS(o.items_total_uzs)} accent="text-ink" />
          <Total label="To'langan" value={formatUZS(o.paid_uzs)} accent="text-success" />
          <Total label="Qoldiq" value={formatUZS(o.balance_uzs)} accent={balance > 0 ? 'text-danger' : 'text-ink-soft'} />
        </div>
      </Card>

      {/* Payments */}
      <Card title="To'lovlar" action={
        balance > 0
          ? <button onClick={() => setAddingPayment(true)} className="btn-primary text-sm py-1.5"><Plus size={15} /> To'lov</button>
          : <span className="text-xs text-success font-medium">To'liq to'langan</span>
      }>
        {o.payments.length === 0 ? (
          <div className="text-sm text-ink-soft">To'lovlar yo'q</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Sana</th>
                <th className="py-2 pr-3 text-right">Summa</th>
                <th className="py-2 pr-3">Usul</th>
                <th className="py-2 pr-3">Izoh</th>
                <th className="py-2 pr-3"></th>
              </tr>
            </thead>
            <tbody>
              {o.payments.map((p) => (
                <tr key={p.id} className="border-b border-black/5">
                  <td className="py-2 pr-3">{formatDate(p.date)}</td>
                  <td className="py-2 pr-3 text-right font-medium">
                    {p.currency === 'USD' ? formatUSD(p.amount) : formatUZS(p.amount)}
                  </td>
                  <td className="py-2 pr-3">{p.method ? (METHOD_LABEL[p.method] ?? p.method) : '—'}</td>
                  <td className="py-2 pr-3 text-ink-soft">{p.note || '—'}</td>
                  <td className="py-2 pr-3 text-right">
                    <button onClick={() => askDeletePayment(p.id)} className="p-1 rounded hover:bg-danger/10 text-danger">
                      <Trash2 size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>

      {editing && (
        <OrderModal order={o as unknown as OrderEditData} onClose={() => setEditing(false)} onSaved={refresh} />
      )}
      {addingPayment && (
        <PaymentModal orderId={orderId!} onClose={() => setAddingPayment(false)} onSaved={refresh} />
      )}

      <ConfirmModal
        open={confirm !== null}
        title={confirm?.title ?? ''}
        message={confirm?.message ?? ''}
        confirmText={confirm?.confirmText}
        variant={confirm?.variant ?? 'primary'}
        loading={confirmLoading}
        onConfirm={runConfirm}
        onCancel={() => setConfirm(null)}
      />
    </div>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-xs text-ink-soft">{label}</div>
      <div className="font-medium">{value}</div>
    </div>
  );
}

function Total({ label, value, accent }: { label: string; value: string; accent?: string }) {
  return (
    <div className="text-center">
      <div className="text-xs text-ink-soft">{label}</div>
      <div className={'text-lg font-bold mt-0.5 ' + (accent ?? 'text-ink')}>{value}</div>
    </div>
  );
}
