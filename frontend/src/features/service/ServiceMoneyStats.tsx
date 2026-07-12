import { useMemo, useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Coins } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';
import ServiceTripsList from '@/features/service/ServiceTripsList';
import ServiceExpensesList from '@/features/service/ServiceExpensesList';

interface Money {
  collected: string; spent: string; net: string; trip_count: number;
  service_expenses: string; total_expenses: string;
}

const MONTH_NUMS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;
const pad2 = (n: number) => String(n).padStart(2, '0');

const SALES_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentabr', '10': 'Oktabr', '11': 'Noyabr', '12': 'Dekabr',
};

/** Servis safari moliyaviy statistikasi (olingan/sarflangan/sof) — oy/yil filtri. */
export default function ServiceMoneyStats() {
  const now = new Date();
  const [month, setMonth] = useState<number>(now.getMonth() + 1); // 0 = butun yil
  const [year, setYear] = useState<number>(now.getFullYear());

  const { dateFrom, dateTo } = useMemo(() => {
    if (month === 0) return { dateFrom: `${year}-01-01`, dateTo: `${year}-12-31` };
    const lastDay = new Date(year, month, 0).getDate();
    return { dateFrom: `${year}-${pad2(month)}-01`, dateTo: `${year}-${pad2(month)}-${pad2(lastDay)}` };
  }, [month, year]);

  const YEARS = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  const q = useQuery<Money>({
    queryKey: ['service-trips-stats', dateFrom, dateTo],
    queryFn: () => api.get('/service/trips/stats', {
      params: { date_from: dateFrom, date_to: dateTo },
    }).then((r) => r.data),
  });
  const m = q.data;

  return (
    <div className="space-y-4">
      {/* Oy / yil filtri */}
      <div className="flex items-center gap-2 flex-wrap">
        <select className="input w-40" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
          <option value={0}>Butun yil</option>
          {MONTH_NUMS.map((mo) => <option key={mo} value={mo}>{SALES_MONTHS[String(mo)]}</option>)}
        </select>
        <select className="input w-28" value={year} onChange={(e) => setYear(Number(e.target.value))}>
          {YEARS.map((y) => <option key={y} value={y}>{y}</option>)}
        </select>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <MoneyCard label="Safar xarajati" value={formatUZS(m?.spent ?? 0)}
                   tone="danger" icon={<Coins size={18} />} />
        <MoneyCard label="Servis xarajati (arizalar)" value={formatUZS(m?.service_expenses ?? 0)}
                   tone="danger" icon={<Coins size={18} />} />
      </div>

      {/* Servislar uchun ketgan barcha xarajat = safar + arizalar */}
      <div className="rounded-card border border-danger/25 bg-danger/[0.06] p-4 flex items-center justify-between gap-3 flex-wrap">
        <div>
          <div className="text-sm font-medium text-danger/90">Jami servis xarajati</div>
          <div className="text-xs text-ink-soft mt-0.5">
            Safar xarajati + har bir arizadagi «Servis xarajati»
          </div>
        </div>
        <div className="text-2xl font-bold text-danger tabular-nums">
          {formatUZS(m?.total_expenses ?? 0)}
        </div>
      </div>

      {/* Har bir arizadagi "Servis xarajati" — davr yuqoridagi umumiy filtrdan */}
      <ServiceExpensesList dateFrom={dateFrom} dateTo={dateTo} />

      <div className="text-xs text-ink-soft">{`${m?.trip_count ?? 0} ta yakunlangan safar`}</div>

      {/* Tanlangan davrdagi safarlar ro'yxati (mablag balanslari pastida) */}
      <ServiceTripsList dateFrom={dateFrom} dateTo={dateTo} />
    </div>
  );
}

const TONES = {
  success: { box: 'border-success/25 bg-success/10', label: 'text-success/90', val: 'text-success', ring: 'bg-success/20 text-success' },
  danger: { box: 'border-danger/25 bg-danger/10', label: 'text-danger/90', val: 'text-danger', ring: 'bg-danger/20 text-danger' },
} as const;

function MoneyCard({ label, value, tone, icon }: {
  label: string; value: string; tone: 'success' | 'danger'; icon: ReactNode;
}) {
  const c = TONES[tone];
  return (
    <div className={'rounded-card border p-4 flex items-start justify-between ' + c.box}>
      <div>
        <div className={'text-sm font-medium ' + c.label}>{label}</div>
        <div className={'text-2xl font-bold mt-2 ' + c.val}>{value}</div>
      </div>
      <div className={'w-10 h-10 rounded-button flex items-center justify-center shrink-0 ' + c.ring}>{icon}</div>
    </div>
  );
}
