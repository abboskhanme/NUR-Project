import { useQuery } from '@tanstack/react-query';
import { Wallet, ShoppingCart, Wrench, AlertTriangle } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, BarChart, Bar, CartesianGrid } from 'recharts';

import { api } from '@/api/client';
import BalanceCard from '@/components/ui/BalanceCard';
import Card from '@/components/ui/Card';
import { formatUZS, formatUSD } from '@/lib/format';

export default function DashboardPage() {
  const balance = useQuery({
    queryKey: ['balance-summary'],
    queryFn: () => api.get('/finance/balance-summary').then((r) => r.data),
  });

  const kpi = useQuery({
    queryKey: ['sales-kpi'],
    queryFn: () => api.get('/reports/sales/kpi').then((r) => r.data),
  });

  // Sample trend data
  const trend = Array.from({ length: 7 }, (_, i) => ({
    name: `D${i + 1}`, uzs: Math.random() * 200_000_000, usd: Math.random() * 5000,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Bosh sahifa</h1>
        <p className="text-sm text-ink-soft">NUR TECHNO GROUP — joriy holat</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <BalanceCard
          title="UZS Balans"
          value={formatUZS(balance.data?.uzs ?? 0)}
          icon={<Wallet size={18} />}
          accent="primary"
        />
        <BalanceCard
          title="USD Balans"
          value={formatUSD(balance.data?.usd ?? 0)}
          icon={<Wallet size={18} />}
          accent="success"
        />
        <BalanceCard
          title="G'azna (naqd USD)"
          value={formatUSD(balance.data?.gazna ?? 0)}
          icon={<Wallet size={18} />}
          accent="warning"
        />
        <BalanceCard
          title="Buyurtmalar (oy)"
          value={String(kpi.data?.orders_total ?? 0)}
          icon={<ShoppingCart size={18} />}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Balans dinamikasi (7 kun)">
          <ResponsiveContainer width="100%" height={250}>
            <LineChart data={trend}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="uzs" stroke="#1E3A5F" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </Card>

        <Card title="Kirim vs Chiqim (joriy oy)">
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={[
              { name: 'Hafta 1', income: 120, expense: 80 },
              { name: 'Hafta 2', income: 95, expense: 120 },
              { name: 'Hafta 3', income: 150, expense: 90 },
              { name: 'Hafta 4', income: 200, expense: 110 },
            ]}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="income" fill="#27AE60" />
              <Bar dataKey="expense" fill="#E74C3C" />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card title="Eslatmalar">
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2 text-warning">
              <AlertTriangle size={16} />
              Kafolat tugaydigan buyurtmalar (30 kun): —
            </div>
            <div className="flex items-center gap-2 text-warning">
              <Wrench size={16} />
              Servis arizalari (yangi): —
            </div>
          </div>
        </Card>

        <Card title="So'nggi buyurtmalar"><div className="text-sm text-ink-soft">— hozircha bo'sh —</div></Card>
        <Card title="Faol xodimlar"><div className="text-sm text-ink-soft">— hozircha bo'sh —</div></Card>
      </div>
    </div>
  );
}
