import { useQuery } from '@tanstack/react-query';
import { TrendingUp } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';

const HR_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentyabr', '10': 'Oktyabr', '11': 'Noyabr', '12': 'Dekabr',
};
const TYPE_LABEL: Record<string, string> = {
  hourly: 'Soatbay', daily: 'Kunbay', fixed: 'Belgilangan (oylik)', kpi: 'KPI',
};

interface Rate {
  id: string;
  effective_from: string;
  salary_type: string;
  amount: string;
  currency: string;
  note?: string | null;
}

function monthLabel(iso: string, monthNameFn: (m: number) => string): string {
  // "YYYY-MM-DD" -> "May 2026"
  const [y, m] = iso.split('-').map(Number);
  return `${monthNameFn((m || 1))} ${y}`;
}

export default function SalaryRatesCard({ employeeId }: { employeeId: string }) {
  const { data, isLoading } = useQuery<Rate[]>({
    queryKey: ['hr', 'salary-rates', employeeId],
    queryFn: () => api.get(`/hr/employees/${employeeId}/salary-rates`).then((r) => r.data),
  });
  const items = data ?? [];

  const getMonthName = (m: number) => HR_MONTHS[String(m)];

  // Tarix bo'sh bo'lsa (oylik hali hech qachon o'zgartirilmagan) — kartani ko'rsatmaymiz.
  if (!isLoading && items.length === 0) return null;

  return (
    <Card title="Oylik tarixi">
      <p className="text-xs text-ink-soft mb-3">
        Oylik Edit orqali o'zgartirilganda, yangi summa o'sha oydan boshlab amal qiladi.
        Eski oylar avvalgi summada saqlanadi.
      </p>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 2 }).map((_, i) => (
            <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-4">Qaysi oydan</th>
                <th className="py-2 pr-4">Turi</th>
                <th className="py-2 pl-6 text-right">Summa</th>
              </tr>
            </thead>
            <tbody>
              {items.map((r, idx) => (
                <tr key={r.id} className="border-b border-black/5">
                  <td className="py-2 pr-4 whitespace-nowrap">
                    <span className="font-medium">{monthLabel(r.effective_from, getMonthName)}</span>
                    {idx === 0 && (
                      <span className="ml-2 badge bg-success/10 text-success">
                        <TrendingUp size={11} className="mr-1" /> joriy
                      </span>
                    )}
                  </td>
                  <td className="py-2 pr-4 text-ink/70">{TYPE_LABEL[r.salary_type] ?? r.salary_type}</td>
                  <td className="py-2 pl-6 text-right tabular-nums font-medium whitespace-nowrap">
                    {formatUZS(r.amount)}{r.salary_type === 'hourly' ? '/ soat' : ''}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
