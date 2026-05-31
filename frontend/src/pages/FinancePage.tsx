import { useQuery } from '@tanstack/react-query';
import { Plus, Wallet, ArrowUpRight, ArrowDownRight } from 'lucide-react';

import { api } from '@/api/client';
import BalanceCard from '@/components/ui/BalanceCard';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatUSD, formatUZS } from '@/lib/format';

interface Tx {
  id: string; date: string; type: string; amount: string; currency: string; note?: string | null;
}

export default function FinancePage() {
  const balance = useQuery({
    queryKey: ['balance-summary'],
    queryFn: () => api.get('/finance/balance-summary').then((r) => r.data),
  });
  const tx = useQuery({
    queryKey: ['finance-transactions'],
    queryFn: () => api.get('/finance/transactions', { params: { page_size: 30 } }).then((r) => r.data),
  });

  const items: Tx[] = tx.data?.items ?? [];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Moliya</h1>
          <p className="text-sm text-ink-soft">Kassa, hisobvaraqlar va tranzaksiyalar</p>
        </div>
        <div className="flex gap-2">
          <button className="btn-primary"><Plus size={16} /> Yangi tranzaksiya</button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <BalanceCard title="UZS Balans" value={formatUZS(balance.data?.uzs ?? 0)} icon={<Wallet size={18} />} accent="primary" />
        <BalanceCard title="USD Balans" value={formatUSD(balance.data?.usd ?? 0)} icon={<Wallet size={18} />} accent="success" />
        <BalanceCard title="G'azna (USD)" value={formatUSD(balance.data?.gazna ?? 0)} icon={<Wallet size={18} />} accent="warning" />
      </div>

      <Card title="So'nggi tranzaksiyalar">
        {items.length === 0 ? (
          <EmptyState title="Tranzaksiyalar yo'q" />
        ) : (
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Sana</th>
                <th className="py-2 pr-3">Tip</th>
                <th className="py-2 pr-3">Summa</th>
                <th className="py-2 pr-3">Izoh</th>
              </tr>
            </thead>
            <tbody>
              {items.map((t) => (
                <tr key={t.id} className="border-b border-black/5 hover:bg-black/5">
                  <td className="py-2 pr-3">{formatDate(t.date)}</td>
                  <td className="py-2 pr-3">
                    {t.type === 'income'
                      ? <span className="badge bg-success/10 text-success"><ArrowUpRight size={12} /> Kirim</span>
                      : <span className="badge bg-danger/10 text-danger"><ArrowDownRight size={12} /> Chiqim</span>}
                  </td>
                  <td className="py-2 pr-3 font-semibold">
                    {t.currency === 'USD' ? formatUSD(t.amount) : formatUZS(t.amount)}
                  </td>
                  <td className="py-2 pr-3">{t.note || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Card>
    </div>
  );
}
