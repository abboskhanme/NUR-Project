import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Search, ShoppingCart, Wallet, AlertCircle, CalendarClock } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import DateInput from '@/components/ui/DateInput';
import { formatUZS } from '@/lib/format';
import OrderModal from '@/features/sales/OrderModal';
import PaymentModal from '@/features/sales/PaymentModal';
import OrdersTable, { OrderFull, ProductOpt } from '@/features/sales/OrdersTable';

interface Summary {
  total_orders: number;
  status_counts: Record<string, number>;
  revenue_total: string;
  paid_total: string;
  outstanding_total: string;
  month_orders: number;
  month_revenue: string;
  month_paid: string;
}

const STATUS_OPTIONS = [
  { value: 'new', label: 'Navbatda' },
  { value: 'ready', label: 'Tayyor bo\'ldi' },
  { value: 'delivered', label: 'Yetkazildi' },
  { value: 'rejected', label: 'Rad etildi' },
];

export default function OrdersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [payingId, setPayingId] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ['orders', search, statusFilter, dateFrom, dateTo],
    queryFn: () => api.get('/orders', {
      params: {
        search: search || undefined,
        status: statusFilter || undefined,
        date_from: dateFrom || undefined,
        date_to: dateTo || undefined,
        page_size: 100,
      },
    }).then((r) => r.data),
  });
  const orders: OrderFull[] = data?.items ?? [];

  const productsQ = useQuery({
    queryKey: ['products', 'order-table'],
    queryFn: () => api.get('/products', { params: { page_size: 200 } }).then((r) => r.data),
  });
  const products: ProductOpt[] = productsQ.data?.items ?? [];

  const summaryQ = useQuery<Summary>({
    queryKey: ['orders', 'summary', search, statusFilter, dateFrom, dateTo],
    queryFn: () => api.get('/orders/summary', {
      params: {
        search: search || undefined,
        status: statusFilter || undefined,
        date_from: dateFrom || undefined,
        date_to: dateTo || undefined,
      },
    }).then((r) => r.data),
  });
  const s = summaryQ.data;

  function refresh() {
    qc.invalidateQueries({ queryKey: ['orders'] });
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Buyurtmalar</h1>
          <p className="text-sm text-ink-soft">Sotuv bo'limi — barcha buyurtmalar</p>
        </div>
        <button className="btn-primary" onClick={() => setShowCreate(true)}>
          <Plus size={16} /> Yangi buyurtma
        </button>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Kpi icon={<ShoppingCart size={18} />} label="Buyurtma · bu oy" value={s ? String(s.month_orders) : '—'}
             sub={s ? `Jami: ${s.total_orders}` : undefined} />
        <Kpi icon={<Wallet size={18} />} label="Savdo · bu oy" value={s ? formatUZS(s.month_revenue) : '—'}
             sub={s ? `Jami: ${formatUZS(s.revenue_total)}` : undefined} accent="text-ink" />
        <Kpi icon={<CalendarClock size={18} />} label="To'langan · bu oy" value={s ? formatUZS(s.month_paid) : '—'}
             sub={s ? `Jami: ${formatUZS(s.paid_total)}` : undefined} accent="text-success" />
        <Kpi icon={<AlertCircle size={18} />} label="Qoldiq · bu oy"
             value={s ? formatUZS(parseFloat(s.month_revenue) - parseFloat(s.month_paid)) : '—'}
             sub={s ? `Jami qarz: ${formatUZS(s.outstanding_total)}` : undefined} accent="text-danger" />
      </div>

      <Card>
        <div className="flex flex-wrap gap-3 mb-4">
          <div className="flex items-center gap-2 flex-1 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
            <Search size={16} className="text-ink/40" />
            <input placeholder="Kod bo'yicha qidirish..." value={search}
                   onChange={(e) => setSearch(e.target.value)}
                   className="bg-transparent outline-none flex-1 text-sm" />
          </div>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="input max-w-[190px]">
            <option value="">Barcha statuslar</option>
            {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
          <DateInput value={dateFrom} onChange={setDateFrom} placeholder="Sanadan (kun.oy.yil)" className="max-w-[170px]" />
          <DateInput value={dateTo} onChange={setDateTo} placeholder="Sanagacha (kun.oy.yil)" className="max-w-[170px]" />
        </div>

        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : orders.length === 0 ? (
          <EmptyState title="Buyurtmalar yo'q" description="'Yangi buyurtma' tugmasi orqali yarating" />
        ) : (
          <>
            <p className="text-xs text-ink-soft mb-2">
              Kataklarni bevosita tahrirlash mumkin — o'zgartirish avtomatik saqlanadi. To'liq ko'rish uchun qator oxiridagi tugmani bosing.
            </p>
            <OrdersTable orders={orders} products={products} onChanged={refresh} onPay={setPayingId} />
          </>
        )}
      </Card>

      {showCreate && (
        <OrderModal order={null} onClose={() => setShowCreate(false)} onSaved={refresh} />
      )}
      {payingId && (
        <PaymentModal orderId={payingId} onClose={() => setPayingId(null)} onSaved={refresh} />
      )}
    </div>
  );
}

function Kpi({ icon, label, value, sub, accent }: {
  icon: React.ReactNode; label: string; value: string; sub?: string; accent?: string;
}) {
  return (
    <div className="card !p-4">
      <div className="flex items-center gap-2 text-ink-soft text-xs">
        <span className="text-primary">{icon}</span> {label}
      </div>
      <div className={'text-2xl font-bold mt-1 ' + (accent ?? 'text-ink')}>{value}</div>
      {sub && <div className="text-xs text-ink-soft mt-0.5">{sub}</div>}
    </div>
  );
}
