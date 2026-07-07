import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Search, ShoppingCart, Wallet, AlertCircle, CalendarClock, FileSpreadsheet, PackageCheck, Clock, DollarSign, TrendingUp, TrendingDown } from 'lucide-react';

import { api } from '@/api/client';
import { downloadFile } from '@/lib/download';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatUZS, formatUSD } from '@/lib/format';
import OrderModal from '@/features/sales/OrderModal';
import PaymentModal from '@/features/sales/PaymentModal';
import OrdersTable, { OrderFull, ProductOpt } from '@/features/sales/OrdersTable';

interface SalespersonCount { salesperson_id: string | null; name: string; count: number; prev_count?: number | null; }
interface Summary {
  total_orders: number;
  status_counts: Record<string, number>;
  salesperson_counts?: SalespersonCount[];
  revenue_total: string;
  paid_total: string;
  outstanding_total: string;
  month_orders: number;
  month_revenue: string;
  month_paid: string;
  // Oldingi davr (o'tgan oy/yil) — qiyoslash uchun. null = qiyos yo'q.
  orders_prev?: number | null;
  delivered_prev?: number | null;
  pending_prev?: number | null;
  revenue_prev?: string | null;
  paid_prev?: string | null;
}

// Status options with their labels
const STATUS_OPTIONS = [
  { value: 'new', label: "Navbatda" },
  { value: 'delivered', label: "Yetkazildi" },
  { value: 'rejected', label: "Rad etildi" },
];

// Month keys (1-12)
const MONTH_NUMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;

// Oy nomlari (1-12)
const MONTH_NAMES: Record<string, string> = {
  '1': "Yanvar",
  '2': "Fevral",
  '3': "Mart",
  '4': "Aprel",
  '5': "May",
  '6': "Iyun",
  '7': "Iyul",
  '8': "Avgust",
  '9': "Sentabr",
  '10': "Oktabr",
  '11': "Noyabr",
  '12': "Dekabr",
};

const pad2 = (n: number) => String(n).padStart(2, '0');

// Sotuvchi chipi rangi — ism bo'yicha barqaror (har ism o'z rangiga ega)
const SP_COLORS = [
  'bg-primary/10 text-primary',
  'bg-emerald-100 text-emerald-700',
  'bg-amber-100 text-amber-700',
  'bg-sky-100 text-sky-700',
  'bg-violet-100 text-violet-700',
  'bg-rose-100 text-rose-700',
  'bg-teal-100 text-teal-700',
  'bg-fuchsia-100 text-fuchsia-700',
  'bg-indigo-100 text-indigo-700',
  'bg-orange-100 text-orange-700',
];

function spColor(name: string): string {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return SP_COLORS[h % SP_COLORS.length];
}

// Oldingi davrga nisbatan o'zgarish. kind: 'pct' — foizda (summa uchun),
// 'count' — sonda (... ta). invert: o'sish yomon (masalan qoldiq).
type Trend = { delta: number; kind: 'pct' | 'count'; note: string; invert?: boolean };

function moneyTrend(cur: string | number | undefined, prev: string | number | null | undefined,
                    note: string, invert = false): Trend | undefined {
  if (prev == null) return undefined;
  const c = Number(cur || 0), p = Number(prev || 0);
  if (p <= 0) return undefined; // oldingi davr 0 — foiz hisoblab bo'lmaydi
  return { delta: Math.round(((c - p) / p) * 100), kind: 'pct', note, invert };
}
function countTrend(cur: number | undefined, prev: number | null | undefined,
                    note: string, invert = false): Trend | undefined {
  if (prev == null) return undefined;
  return { delta: (cur || 0) - prev, kind: 'count', note, invert };
}

function TrendBadge({ t }: { t: Trend }) {
  const { delta, kind, note, invert } = t;
  const unit = kind === 'count' ? ' ta' : '%';
  if (delta === 0) {
    return <div className="text-xs text-ink-soft mt-1">0{unit} · {note}</div>;
  }
  const up = delta > 0;
  const good = invert ? delta < 0 : delta > 0;
  const Icon = up ? TrendingUp : TrendingDown;
  return (
    <div className={'text-xs mt-1 flex items-center gap-1 ' + (good ? 'text-success' : 'text-danger')}>
      <Icon size={13} /> {up ? '+' : ''}{delta}{unit} <span className="text-ink-soft">{note}</span>
    </div>
  );
}

export default function OrdersPage() {
  const qc = useQueryClient();
  const now = new Date();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  // Default: current month and year. month: 1-12, 0 = full year
  const [month, setMonth] = useState<number>(now.getMonth() + 1);
  const [year, setYear] = useState<number>(now.getFullYear());
  const [showCreate, setShowCreate] = useState(false);
  const [payingId, setPayingId] = useState<string | null>(null);

  const { dateFrom, dateTo, cmpFrom, cmpTo } = useMemo(() => {
    const iso = (y: number, m: number, d: number) => `${y}-${pad2(m)}-${pad2(d)}`;
    if (month === 0) {
      // Butun yil — o'tgan yilning TO'LIQ natijasi bilan qiyos
      return {
        dateFrom: iso(year, 1, 1), dateTo: iso(year, 12, 31),
        cmpFrom: iso(year - 1, 1, 1), cmpTo: iso(year - 1, 12, 31),
      };
    }
    const lastDay = new Date(year, month, 0).getDate();
    // Oldingi oy (month 1-based → new Date oyi month-1; oldingisi month-2)
    const pd = new Date(year, month - 2, 1);
    const py = pd.getFullYear();
    const pm = pd.getMonth() + 1;
    const pLast = new Date(py, pm, 0).getDate();
    // Har doim TO'LIQ oldingi oy bilan qiyoslaymiz (butun o'tgan oy).
    return {
      dateFrom: iso(year, month, 1), dateTo: iso(year, month, lastDay),
      cmpFrom: iso(py, pm, 1), cmpTo: iso(py, pm, pLast),
    };
  }, [month, year]);

  const cmpLabel = month === 0 ? "o'tgan yilga nisbatan" : "o'tgan oyga nisbatan";

  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  const periodLabel =
    month === 0
      ? `${year}`
      : `${MONTH_NAMES[String(month)]} ${year}`;

  const searching = search.trim().length > 0;

  const { data, isLoading } = useQuery({
    queryKey: ['orders', search, statusFilter, dateFrom, dateTo],
    queryFn: () => api.get('/orders', {
      params: {
        search: search.trim() || undefined,
        status: searching ? undefined : (statusFilter || undefined),
        date_from: searching ? undefined : (dateFrom || undefined),
        date_to: searching ? undefined : (dateTo || undefined),
        page_size: 100,
      },
    }).then((r) => r.data),
  });
  const orders: OrderFull[] = data?.items ?? [];

  const productsQ = useQuery({
    queryKey: ['products', 'order-table'],
    queryFn: () => api.get('/products', { params: { page_size: 200 } }).then((r) => r.data),
  });
  // Ombor turlari (product_type='warehouse') sotuvda ko'rsatilmaydi — aralashmasligi uchun
  const products: ProductOpt[] = (productsQ.data?.items ?? [])
    .filter((p: ProductOpt) => p.product_type !== 'warehouse');

  const summaryQ = useQuery<Summary>({
    queryKey: ['orders', 'summary', search, statusFilter, dateFrom, dateTo],
    queryFn: () => api.get('/orders/summary', {
      params: {
        search: search.trim() || undefined,
        status: searching ? undefined : (statusFilter || undefined),
        date_from: searching ? undefined : (dateFrom || undefined),
        date_to: searching ? undefined : (dateTo || undefined),
        // Qidiruvda qiyoslash mantiqsiz — faqat davr tanlanганда yuboramiz
        cmp_date_from: searching ? undefined : (cmpFrom || undefined),
        cmp_date_to: searching ? undefined : (cmpTo || undefined),
      },
    }).then((r) => r.data),
  });
  const s = summaryQ.data;

  // Joriy USD→UZS kurs — umumiy savdoni dollarda ko'rsatish uchun
  const rateQ = useQuery<number>({
    queryKey: ['usd-rate'],
    queryFn: () => api.get('/finance/exchange-rates/latest').then((r) => Number(r.data?.usd_to_uzs) || 0),
  });
  const rate = rateQ.data ?? 0;

  const [exporting, setExporting] = useState(false);

  function refresh() {
    qc.invalidateQueries({ queryKey: ['orders'] });
  }

  async function exportExcel() {
    setExporting(true);
    try {
      await downloadFile('/orders/export.xlsx', `buyurtmalar-${dateFrom}.xlsx`, {
        search: search.trim() || undefined,
        status: searching ? undefined : (statusFilter || undefined),
        date_from: searching ? undefined : (dateFrom || undefined),
        date_to: searching ? undefined : (dateTo || undefined),
      });
    } catch {
      toast.error("Xatolik yuz berdi");
    } finally {
      setExporting(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <div className="flex items-center flex-wrap gap-x-3 gap-y-1">
            <h1 className="text-2xl font-bold">Buyurtmalar</h1>
            {s?.salesperson_counts && s.salesperson_counts.length > 0 && (
              <div className="flex flex-wrap items-center gap-2" title="Sotuvchi bo‘yicha zakazlar">
                {s.salesperson_counts.map((sp) => {
                  const d = sp.prev_count != null ? sp.count - sp.prev_count : null;
                  return (
                    <span key={sp.salesperson_id ?? sp.name}
                          className={'inline-flex items-center gap-2 text-xl font-semibold rounded-full pl-4 pr-2 py-1.5 ' + spColor(sp.name)}
                          title={sp.prev_count != null ? `${cmpLabel}: ${sp.prev_count} ta` : undefined}>
                      {sp.name}
                      <span className="inline-flex items-center justify-center min-w-[30px] h-7 px-2 rounded-full bg-white/75 font-bold text-base">{sp.count}</span>
                      {d != null && d !== 0 && (
                        <span className={'inline-flex items-center text-sm font-bold ' + (d > 0 ? 'text-emerald-600' : 'text-rose-600')}>
                          {d > 0 ? <TrendingUp size={15} /> : <TrendingDown size={15} />}{Math.abs(d)}
                        </span>
                      )}
                    </span>
                  );
                })}
              </div>
            )}
          </div>
          <p className="text-sm text-ink-soft">Sotuv bo'limi — barcha buyurtmalar</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-ghost disabled:opacity-50" onClick={exportExcel} disabled={exporting}
                  title="Buyurtmalar ro'yxatini Excel ga yuklab olish">
            <FileSpreadsheet size={16} /> Excel
          </button>
          <button className="btn-primary" onClick={() => setShowCreate(true)}>
            <Plus size={16} /> Yangi buyurtma
          </button>
        </div>
      </div>

      {/* KPI — songa oid kartalar (alohida qator) */}
      <div className="grid grid-cols-3 gap-3">
        <Kpi icon={<ShoppingCart size={18} />} label={`Buyurtma · ${periodLabel}`} value={s ? String(s.total_orders) : '—'}
             trend={s ? countTrend(s.total_orders, s.orders_prev, cmpLabel) : undefined} />
        <Kpi icon={<PackageCheck size={18} />} label={`Yetkazildi · ${periodLabel}`}
             value={s ? String(s.status_counts?.delivered ?? 0) : '—'} accent="text-success"
             trend={s ? countTrend(s.status_counts?.delivered ?? 0, s.delivered_prev, cmpLabel) : undefined} />
        <Kpi icon={<Clock size={18} />} label={`Qoldi · ${periodLabel}`}
             value={s ? String((s.status_counts?.new ?? 0) + (s.status_counts?.ready ?? 0)) : '—'} accent="text-warning"
             trend={s ? countTrend((s.status_counts?.new ?? 0) + (s.status_counts?.ready ?? 0), s.pending_prev, cmpLabel) : undefined} />
      </div>

      {/* KPI — pulga oid kartalar (alohida qator) */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Kpi icon={<Wallet size={18} />} label={`Savdo · ${periodLabel}`} value={s ? formatUZS(s.revenue_total) : '—'} accent="text-ink"
             trend={s ? moneyTrend(s.revenue_total, s.revenue_prev, cmpLabel) : undefined} />
        <Kpi icon={<DollarSign size={18} />} label={`Savdo ($) · ${periodLabel}`}
             value={s && rate > 0 ? formatUSD(Number(s.revenue_total) / rate) : '—'} accent="text-ink"
             trend={s ? moneyTrend(s.revenue_total, s.revenue_prev, cmpLabel) : undefined} />
        <Kpi icon={<CalendarClock size={18} />} label={`To'langan · ${periodLabel}`} value={s ? formatUZS(s.paid_total) : '—'} accent="text-success"
             trend={s ? moneyTrend(s.paid_total, s.paid_prev, cmpLabel) : undefined} />
        <Kpi icon={<AlertCircle size={18} />} label={`Qoldiq · ${periodLabel}`}
             value={s ? formatUZS(s.outstanding_total) : '—'} accent="text-danger" />
      </div>

      <Card>
        <div className="flex flex-wrap gap-3 mb-4">
          <div className="flex items-center gap-2 flex-1 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
            <Search size={16} className="text-ink/40" />
            <input placeholder="Kod, mijoz ismi yoki telefon bo'yicha qidirish..." value={search}
                   onChange={(e) => setSearch(e.target.value)}
                   className="bg-transparent outline-none flex-1 text-sm" />
          </div>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="input max-w-[190px]">
            <option value="">Barcha statuslar</option>
            {STATUS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
          <select value={month} onChange={(e) => setMonth(Number(e.target.value))} className="input max-w-[150px]" title="Oy">
            <option value={0}>Butun yil</option>
            {MONTH_NUMS.map((m) => <option key={m} value={m}>{MONTH_NAMES[String(m)]}</option>)}
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

function Kpi({ icon, label, value, sub, accent, trend }: {
  icon: React.ReactNode; label: string; value: string; sub?: string; accent?: string; trend?: Trend;
}) {
  return (
    <div className="card !p-4">
      <div className="flex items-center gap-2 text-ink-soft text-xs">
        <span className="text-primary">{icon}</span> {label}
      </div>
      <div className={'text-2xl font-bold mt-1 ' + (accent ?? 'text-ink')}>{value}</div>
      {trend ? <TrendBadge t={trend} /> : (sub && <div className="text-xs text-ink-soft mt-0.5">{sub}</div>)}
    </div>
  );
}
