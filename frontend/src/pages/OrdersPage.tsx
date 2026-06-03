import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Search, ShoppingCart, Wallet, AlertCircle, CalendarClock } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
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

// Oy nomlari (1-12). month === 0 => butun yil
const MONTHS = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
];
const pad2 = (n: number) => String(n).padStart(2, '0');

export default function OrdersPage() {
  const qc = useQueryClient();
  const now = new Date();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  // Default: joriy oy va yil. month: 1-12, 0 = butun yil
  const [month, setMonth] = useState<number>(now.getMonth() + 1);
  const [year, setYear] = useState<number>(now.getFullYear());
  const [showCreate, setShowCreate] = useState(false);
  const [payingId, setPayingId] = useState<string | null>(null);

  // Tanlangan oy/yildan sana oralig'ini hisoblaymiz (backend date_from/date_to kutadi)
  const { dateFrom, dateTo } = useMemo(() => {
    if (month === 0) {
      return { dateFrom: `${year}-01-01`, dateTo: `${year}-12-31` };
    }
    const lastDay = new Date(year, month, 0).getDate();
    return {
      dateFrom: `${year}-${pad2(month)}-01`,
      dateTo: `${year}-${pad2(month)}-${pad2(lastDay)}`,
    };
  }, [month, year]);

  // Yil ro'yxati: joriy yildan 4 yil orqaga
  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  // KPI sarlavhasidagi davr nomi: tanlangan oy + yil (yoki butun yil)
  const periodLabel = month === 0 ? `${year}` : `${MONTHS[month - 1]} ${year}`;

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

      {/* KPI cards — tanlangan davr (oy/yil) bo'yicha */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Kpi icon={<ShoppingCart size={18} />} label={`Buyurtma · ${periodLabel}`} value={s ? String(s.total_orders) : '—'} />
        <Kpi icon={<Wallet size={18} />} label={`Savdo · ${periodLabel}`} value={s ? formatUZS(s.revenue_total) : '—'} accent="text-ink" />
        <Kpi icon={<CalendarClock size={18} />} label={`To'langan · ${periodLabel}`} value={s ? formatUZS(s.paid_total) : '—'} accent="text-success" />
        <Kpi icon={<AlertCircle size={18} />} label={`Qoldiq · ${periodLabel}`}
             value={s ? formatUZS(s.outstanding_total) : '—'} accent="text-danger" />
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
          <select value={month} onChange={(e) => setMonth(Number(e.target.value))} className="input max-w-[150px]" title="Oy">
            <option value={0}>Butun yil</option>
            {MONTHS.map((m, i) => <option key={i + 1} value={i + 1}>{m}</option>)}
          </select>
          <select value={year} onChange={(e) => setYear(Number(e.target.value))} className="input max-w-[110px]" title="Yil">
            {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
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
