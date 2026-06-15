import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Plus, Search, ShoppingCart, Wallet, AlertCircle, CalendarClock, FileSpreadsheet, PackageCheck, Clock } from 'lucide-react';

import { api } from '@/api/client';
import { downloadFile } from '@/lib/download';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatUZS } from '@/lib/format';
import OrderModal from '@/features/sales/OrderModal';
import PaymentModal from '@/features/sales/PaymentModal';
import OrdersTable, { OrderFull, ProductOpt } from '@/features/sales/OrdersTable';

interface SalespersonCount { salesperson_id: string | null; name: string; count: number; }
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
}

// Status option keys — resolved with t() at render time so language switching works live
const STATUS_OPTION_KEYS = [
  { value: 'new', labelKey: 'sales.statusNew' },
  { value: 'delivered', labelKey: 'sales.statusDelivered' },
  { value: 'rejected', labelKey: 'sales.statusRejected' },
];

// Month keys (1-12)
const MONTH_NUMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;

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

export default function OrdersPage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const now = new Date();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  // Default: current month and year. month: 1-12, 0 = full year
  const [month, setMonth] = useState<number>(now.getMonth() + 1);
  const [year, setYear] = useState<number>(now.getFullYear());
  const [showCreate, setShowCreate] = useState(false);
  const [payingId, setPayingId] = useState<string | null>(null);

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

  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  const periodLabel =
    month === 0
      ? `${year}`
      : `${t(`sales.months.${month}`)} ${year}`;

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
      },
    }).then((r) => r.data),
  });
  const s = summaryQ.data;

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
      toast.error(t('common.error'));
    } finally {
      setExporting(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <div className="flex items-center flex-wrap gap-x-3 gap-y-1">
            <h1 className="text-2xl font-bold">{t('sales.pageTitle')}</h1>
            {s?.salesperson_counts && s.salesperson_counts.length > 0 && (
              <div className="flex flex-wrap items-center gap-2" title={t('sales.bySalesperson', { defaultValue: 'Sotuvchi bo‘yicha zakazlar' })}>
                {s.salesperson_counts.map((sp) => (
                  <span key={sp.salesperson_id ?? sp.name}
                        className={'inline-flex items-center gap-2 text-xl font-semibold rounded-full pl-4 pr-2 py-1.5 ' + spColor(sp.name)}>
                    {sp.name}
                    <span className="inline-flex items-center justify-center min-w-[30px] h-7 px-2 rounded-full bg-white/75 font-bold text-base">{sp.count}</span>
                  </span>
                ))}
              </div>
            )}
          </div>
          <p className="text-sm text-ink-soft">{t('sales.pageSubtitle')}</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="btn-ghost disabled:opacity-50" onClick={exportExcel} disabled={exporting}
                  title={t('sales.exportExcelTitle')}>
            <FileSpreadsheet size={16} /> {t('sales.exportExcel')}
          </button>
          <button className="btn-primary" onClick={() => setShowCreate(true)}>
            <Plus size={16} /> {t('sales.modalCreateTitle')}
          </button>
        </div>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3">
        <Kpi icon={<ShoppingCart size={18} />} label={t('sales.kpiOrders', { period: periodLabel })} value={s ? String(s.total_orders) : '—'} />
        <Kpi icon={<PackageCheck size={18} />} label={t('sales.kpiDelivered', { period: periodLabel })}
             value={s ? String(s.status_counts?.delivered ?? 0) : '—'} accent="text-success" />
        <Kpi icon={<Clock size={18} />} label={t('sales.kpiRemaining', { period: periodLabel })}
             value={s ? String((s.status_counts?.new ?? 0) + (s.status_counts?.ready ?? 0)) : '—'} accent="text-warning" />
        <Kpi icon={<Wallet size={18} />} label={t('sales.kpiRevenue', { period: periodLabel })} value={s ? formatUZS(s.revenue_total) : '—'} accent="text-ink" />
        <Kpi icon={<CalendarClock size={18} />} label={t('sales.kpiPaid', { period: periodLabel })} value={s ? formatUZS(s.paid_total) : '—'} accent="text-success" />
        <Kpi icon={<AlertCircle size={18} />} label={t('sales.kpiBalance', { period: periodLabel })}
             value={s ? formatUZS(s.outstanding_total) : '—'} accent="text-danger" />
      </div>

      <Card>
        <div className="flex flex-wrap gap-3 mb-4">
          <div className="flex items-center gap-2 flex-1 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
            <Search size={16} className="text-ink/40" />
            <input placeholder={t('sales.searchPlaceholder')} value={search}
                   onChange={(e) => setSearch(e.target.value)}
                   className="bg-transparent outline-none flex-1 text-sm" />
          </div>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="input max-w-[190px]">
            <option value="">{t('sales.statusAll')}</option>
            {STATUS_OPTION_KEYS.map((o) => <option key={o.value} value={o.value}>{t(o.labelKey)}</option>)}
          </select>
          <select value={month} onChange={(e) => setMonth(Number(e.target.value))} className="input max-w-[150px]" title={t('sales.monthTooltip')}>
            <option value={0}>{t('sales.allYear')}</option>
            {MONTH_NUMS.map((m) => <option key={m} value={m}>{t(`sales.months.${m}`)}</option>)}
          </select>
          <select value={year} onChange={(e) => setYear(Number(e.target.value))} className="input max-w-[110px]" title={t('sales.yearTooltip')}>
            {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>

        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : orders.length === 0 ? (
          <EmptyState title={t('sales.ordersEmpty')} description={t('sales.ordersEmptyDesc')} />
        ) : (
          <>
            <p className="text-xs text-ink-soft mb-2">
              {t('sales.inlineEditHint')}
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
