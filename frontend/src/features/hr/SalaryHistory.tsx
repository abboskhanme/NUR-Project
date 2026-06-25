import { useQuery } from '@tanstack/react-query';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';

const HR_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentyabr', '10': 'Oktyabr', '11': 'Noyabr', '12': 'Dekabr',
};

function num(v: string | number | null | undefined): string {
  const n = typeof v === 'string' ? parseFloat(v) : (v ?? 0);
  if (!n || Number.isNaN(n)) return '0';
  return n.toLocaleString('uz-UZ', { maximumFractionDigits: 0 }).replace(/,/g, ' ');
}

interface HistItem {
  year: number;
  month: number;
  present_days: number;
  total_hours: string;
  gross: string;
  advance: string;
  net: string;
}

export default function SalaryHistory({ employeeId }: { employeeId: string }) {
  const { data, isLoading } = useQuery<HistItem[]>({
    queryKey: ['hr', 'history', employeeId],
    queryFn: () => api.get(`/hr/employees/${employeeId}/history`, { params: { months: 12 } }).then((r) => r.data),
  });

  const items = (data ?? []).filter((h) => parseFloat(h.gross) > 0 || h.present_days > 0);

  return (
    <Card title="Oylik tarixi">
      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <EmptyState title="Tarix yo'q" description="Hozircha hisoblangan oylik yo'q." />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Oy</th>
                <th className="py-2 pr-3 text-right">Ish kuni</th>
                <th className="py-2 pr-3 text-right">Soat</th>
                <th className="py-2 pr-3 text-right">Hisoblangan</th>
                <th className="py-2 pr-3 text-right">Avans</th>
                <th className="py-2 pr-3 text-right">Qoldiq</th>
              </tr>
            </thead>
            <tbody>
              {items.map((h) => (
                <tr key={`${h.year}-${h.month}`} className="border-b border-black/5 hover:bg-black/[0.02]">
                  <td className="py-2 pr-3 font-medium">{HR_MONTHS[String(h.month)]} {h.year}</td>
                  <td className="py-2 pr-3 text-right tabular-nums">{h.present_days}</td>
                  <td className="py-2 pr-3 text-right tabular-nums">{parseFloat(h.total_hours).toFixed(1)}</td>
                  <td className="py-2 pr-3 text-right tabular-nums">{num(h.gross)}</td>
                  <td className="py-2 pr-3 text-right tabular-nums text-warn">{num(h.advance)}</td>
                  <td className="py-2 pr-3 text-right tabular-nums font-semibold text-success">{num(h.net)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
