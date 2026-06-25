import { useQuery } from '@tanstack/react-query';
import {
  Wallet, ShoppingCart, TrendingUp, TrendingDown, PackageCheck, Banknote,
} from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Legend,
} from 'recharts';

import { api } from '@/api/client';
import { usePermissions } from '@/lib/permissions';
import BalanceCard from '@/components/ui/BalanceCard';
import Card from '@/components/ui/Card';
import { formatUZS, formatUSD } from '@/lib/format';
import AlertList from '@/features/dashboard/AlertList';
import RecentOrdersList from '@/features/dashboard/RecentOrdersList';
import StatusDonut from '@/features/dashboard/StatusDonut';
import RevenueArea from '@/features/dashboard/RevenueArea';
import GoalCard from '@/features/dashboard/GoalCard';
import type { DashboardData } from '@/features/dashboard/types';

interface BalanceSummary { uzs: number; usd: number; gazna: number }
interface WeekBucket { name: string; income: number; expense: number }

const compact = (n: number) => {
  if (n >= 1_000_000_000) return `${(n / 1_000_000_000).toFixed(1)} mlrd`;
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(0)} mln`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(0)} ming`;
  return String(n);
};

export default function DashboardPage() {
  const { canModule } = usePermissions();
  const canFinance = canModule('finance');
  const canReports = canModule('reports');

  const balance = useQuery<BalanceSummary>({
    queryKey: ['balance-summary'],
    queryFn: () => api.get('/finance/balance-summary').then((r) => r.data),
    enabled: canFinance,
  });

  const dash = useQuery<DashboardData>({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/reports/dashboard').then((r) => r.data),
    enabled: canReports,
  });

  const incomeExpense = useQuery<{ weeks: WeekBucket[] }>({
    queryKey: ['dashboard-income-expense'],
    queryFn: () => api.get('/reports/sales/income-expense').then((r) => r.data),
    enabled: canReports,
  });

  const kpi = dash.data?.kpi;
  const vsLast = "o'tgan oyga nisbatan";
  // Summalar uchun — foizda
  const mkTrend = (pct: number | null | undefined, invert = false) =>
    pct != null ? { value: pct, label: vsLast, invert } : undefined;
  // Sonlar uchun — o'tgan oydan nechta ko'p/kam (son farqi)
  const mkCountTrend = (cur: number | null | undefined, prev: number | null | undefined) =>
    cur != null && prev != null
      ? { value: cur - prev, label: vsLast, kind: 'count' as const }
      : undefined;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Bosh sahifa</h1>
        <p className="text-sm text-ink-soft">NUR TECHNO GROUP — joriy holat</p>
      </div>

      {!canFinance && !canReports && (
        <Card title="Xush kelibsiz">
          <p className="text-sm text-ink-soft">
            Sizga ajratilgan bo'limlar chap menyuda ko'rsatilgan.
          </p>
        </Card>
      )}

      {/* Moliya balanslari */}
      {canFinance && (
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <BalanceCard
          title="UZS balans"
          value={formatUZS(balance.data?.uzs ?? 0)}
          icon={<Wallet size={18} />}
          accent="primary"
        />
        <BalanceCard
          title="USD balans"
          value={formatUSD(balance.data?.usd ?? 0)}
          icon={<Wallet size={18} />}
          accent="success"
        />
        <BalanceCard
          title="G'azna (naqd USD)"
          value={formatUSD(balance.data?.gazna ?? 0)}
          icon={<Banknote size={18} />}
          accent="warning"
        />
      </div>
      )}

      {/* Oylik KPI */}
      {canReports && (
      <>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <BalanceCard
          title="Buyurtmalar (oy)"
          value={String(kpi?.orders_total ?? '—')}
          icon={<ShoppingCart size={18} />}
          trend={mkCountTrend(kpi?.orders_total, kpi?.orders_prev)}
        />
        <BalanceCard
          title="Yetkazilgan (oy)"
          value={String(kpi?.orders_delivered ?? '—')}
          icon={<PackageCheck size={18} />}
          accent="success"
          trend={mkCountTrend(kpi?.orders_delivered, kpi?.delivered_prev)}
        />
        <BalanceCard
          title="Tushum (oy)"
          value={formatUZS(kpi?.revenue_uzs ?? 0)}
          icon={<TrendingUp size={18} />}
          accent="primary"
          trend={mkTrend(kpi?.revenue_growth_pct)}
        />
        <BalanceCard
          title="Chiqim (oy)"
          value={formatUZS(kpi?.expense_uzs ?? 0)}
          icon={<TrendingDown size={18} />}
          accent="warning"
          trend={mkTrend(kpi?.expense_growth_pct, true)}
        />
      </div>

      {/* Oylik maqsad — sotuv va tushum (hammaga ko'rinadi, super-admin boshqaradi) */}
      <GoalCard />

      {/* Grafiklar */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card title="Tushum dinamikasi (14 kun)" className="lg:col-span-2">
          <RevenueArea points={dash.data?.revenue_sparkline} />
        </Card>

        <Card title="Buyurtmalar holati (oy)">
          <StatusDonut data={dash.data?.status_breakdown} />
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card title="Kirim vs Chiqim (joriy oy)" className="lg:col-span-2">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={incomeExpense.data?.weeks ?? []}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="name" fontSize={12} />
              <YAxis tickFormatter={compact} fontSize={11} width={56} />
              <Tooltip formatter={(v: number) => formatUZS(v)} />
              <Legend />
              <Bar dataKey="income" name="Kirim" fill="#27AE60" radius={[4, 4, 0, 0]} />
              <Bar dataKey="expense" name="Chiqim" fill="#E74C3C" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card title="Eslatmalar">
          <AlertList alerts={dash.data?.alerts} />
        </Card>
      </div>

      {/* So'nggi buyurtmalar */}
      <Card title="So'nggi buyurtmalar">
        <RecentOrdersList orders={dash.data?.recent_orders} />
      </Card>
      </>
      )}
    </div>
  );
}
