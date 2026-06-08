import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, Pencil, Phone, MapPin, User, ShoppingCart, Wallet, AlertCircle } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import StatusBadge from '@/components/ui/StatusBadge';
import EmptyState from '@/components/ui/EmptyState';
import { formatPhone, formatDate, formatUZS } from '@/lib/format';
import CustomerModal, { CustomerFull } from '@/features/customers/CustomerModal';

interface OrderRow {
  id: string; code: string; status: string; order_date: string;
  items_total_uzs: string; paid_uzs: string; balance_uzs: string;
}

const n = (s: string | null | undefined) => {
  const v = parseFloat(String(s ?? '')); return Number.isNaN(v) ? 0 : v;
};

export default function CustomerDetailPage() {
  const { customerId } = useParams<{ customerId: string }>();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { t } = useTranslation();
  const [editing, setEditing] = useState(false);

  const custQ = useQuery<CustomerFull>({
    queryKey: ['customer', customerId],
    queryFn: () => api.get(`/customers/${customerId}`).then((r) => r.data),
    enabled: !!customerId,
  });

  const ordersQ = useQuery({
    queryKey: ['orders', 'by-customer', customerId],
    queryFn: () => api.get('/orders', { params: { customer_id: customerId, page_size: 100 } }).then((r) => r.data),
    enabled: !!customerId,
  });
  const orders: OrderRow[] = ordersQ.data?.items ?? [];

  const totals = orders.reduce(
    (acc, o) => ({
      revenue: acc.revenue + n(o.items_total_uzs),
      paid: acc.paid + n(o.paid_uzs),
      balance: acc.balance + n(o.balance_uzs),
    }),
    { revenue: 0, paid: 0, balance: 0 },
  );

  function refresh() {
    qc.invalidateQueries({ queryKey: ['customer', customerId] });
    qc.invalidateQueries({ queryKey: ['customers'] });
  }

  const c = custQ.data;
  if (custQ.isLoading || !c) {
    return (
      <div className="space-y-4">
        <div className="h-8 w-40 rounded bg-black/5 animate-pulse" />
        <div className="h-40 rounded-lg bg-black/5 animate-pulse" />
      </div>
    );
  }

  const initial = c.full_name?.[0]?.toUpperCase() ?? '?';

  return (
    <div className="space-y-4">
      <button onClick={() => navigate('/customers')} className="flex items-center gap-1.5 text-sm text-ink-soft hover:text-ink">
        <ArrowLeft size={16} /> {t('customers.detail.backToList')}
      </button>

      {/* Header */}
      <Card>
        <div className="flex items-start gap-4 flex-wrap">
          <div className="w-16 h-16 rounded-full bg-primary/10 text-primary flex items-center justify-center text-2xl font-bold shrink-0">
            {initial}
          </div>
          <div className="flex-1 min-w-[200px]">
            <div className="flex items-center justify-between gap-2 flex-wrap">
              <h1 className="text-2xl font-bold">{c.full_name}</h1>
              <button onClick={() => setEditing(true)} className="btn-ghost"><Pencil size={15} /> {t('customers.editTooltip')}</button>
            </div>
            <div className="mt-2 grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-1.5 text-sm text-ink/80">
              <span className="flex items-center gap-2"><Phone size={14} className="text-ink/40" /> {formatPhone(c.phone)}</span>
              {c.phone2 && <span className="flex items-center gap-2"><Phone size={14} className="text-ink/40" /> {formatPhone(c.phone2)}</span>}
              <span className="flex items-center gap-2"><MapPin size={14} className="text-ink/40" /> {[c.country, c.region, c.city].filter(Boolean).join(', ') || '—'}</span>
              {c.address && <span className="flex items-center gap-2"><User size={14} className="text-ink/40" /> {c.address}</span>}
            </div>
            {c.note && <div className="mt-2 text-sm text-ink-soft whitespace-pre-line">{c.note}</div>}
          </div>
        </div>
      </Card>

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Kpi icon={<ShoppingCart size={18} />} label={t('customers.detail.kpiOrders')} value={String(orders.length)} />
        <Kpi icon={<Wallet size={18} />} label={t('customers.detail.kpiRevenue')} value={formatUZS(totals.revenue)} accent="text-ink" />
        <Kpi icon={<Wallet size={18} />} label={t('customers.detail.kpiPaid')} value={formatUZS(totals.paid)} accent="text-success" />
        <Kpi icon={<AlertCircle size={18} />} label={t('customers.detail.kpiDebt')} value={formatUZS(totals.balance)} accent={totals.balance > 0 ? 'text-danger' : 'text-ink-soft'} />
      </div>

      {/* Orders */}
      <Card title={t('customers.detail.ordersHistory')}>
        {ordersQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : orders.length === 0 ? (
          <EmptyState title={t('customers.detail.ordersEmpty')} description={t('customers.detail.ordersEmptyDesc')} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">{t('customers.detail.colCode')}</th>
                  <th className="py-2 pr-3">{t('customers.detail.colDate')}</th>
                  <th className="py-2 pr-3 text-right">{t('customers.detail.colAmount')}</th>
                  <th className="py-2 pr-3 text-right">{t('customers.detail.colPaid')}</th>
                  <th className="py-2 pr-3 text-right">{t('customers.detail.colBalance')}</th>
                  <th className="py-2 pr-3">{t('customers.detail.colStatus')}</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((o) => (
                  <tr key={o.id} onClick={() => navigate(`/orders/${o.id}`)}
                      className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                    <td className="py-2 pr-3 font-medium">{o.code}</td>
                    <td className="py-2 pr-3">{formatDate(o.order_date)}</td>
                    <td className="py-2 pr-3 text-right">{formatUZS(o.items_total_uzs)}</td>
                    <td className="py-2 pr-3 text-right text-success">{formatUZS(o.paid_uzs)}</td>
                    <td className={'py-2 pr-3 text-right ' + (n(o.balance_uzs) > 0 ? 'text-danger font-medium' : 'text-ink-soft')}>
                      {formatUZS(o.balance_uzs)}
                    </td>
                    <td className="py-2 pr-3"><StatusBadge status={o.status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {editing && <CustomerModal customer={c} onClose={() => setEditing(false)} onSaved={refresh} />}
    </div>
  );
}

function Kpi({ icon, label, value, accent }: {
  icon: React.ReactNode; label: string; value: string; accent?: string;
}) {
  return (
    <div className="card !p-4">
      <div className="flex items-center gap-2 text-ink-soft text-xs">
        <span className="text-primary">{icon}</span> {label}
      </div>
      <div className={'text-xl font-bold mt-1 ' + (accent ?? 'text-ink')}>{value}</div>
    </div>
  );
}
