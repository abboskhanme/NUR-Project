import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ChevronDown, ChevronRight, Wallet } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatUZS } from '@/lib/format';

interface EmployeeDebt {
  employee_id: string;
  full_name: string;
  department_type: string;
  gross: string;
  paid: string;
  debt: string;
}
interface MonthDebts {
  year: number;
  month: number;
  total: string;
  items: EmployeeDebt[];
}

// Bo'lim rangi (xodimlar tabidagidek): ofis — qizil, yig'uv — ko'k, ishlab chiqarish — yashil
const DEPT_DOT: Record<string, string> = {
  office: 'bg-red-500',
  assembly: 'bg-blue-500',
  production: 'bg-green-600',
};

/**
 * Xodimlar oldidagi oylik qarzlarimiz — har oy uchun alohida bo'lim (yangi → eski).
 * Bir oy qarzi = hisoblangan oylik − berilgan summa (avans + oylik to'lovlari).
 */
export default function SalaryDebtsSection() {
  const { t } = useTranslation();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const yearOptions = [now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2];

  const { data, isLoading } = useQuery<MonthDebts[]>({
    queryKey: ['hr', 'salary-debts', year],
    queryFn: () => api.get('/hr/salary-debts', { params: { year } }).then((r) => r.data),
  });
  const months = data ?? [];
  const grandTotal = months.reduce((s, m) => s + (parseFloat(m.total) || 0), 0);

  return (
    <div className="space-y-4">
      <div className="rounded-card border border-primary/20 bg-primary/5 p-4">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-2 font-semibold text-primary">
            <Wallet size={18} /> {t('hr.debts.grandTitle')}
          </div>
          <select
            className="input !w-auto"
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
          >
            {yearOptions.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>
        <div className="mt-2 text-2xl font-bold tabular-nums text-primary">{formatUZS(grandTotal)}</div>
        <p className="text-xs text-ink-soft mt-1">{t('hr.debts.grandHint')}</p>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-16 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : months.length === 0 ? (
        <EmptyState title={t('hr.debts.empty')} />
      ) : (
        months.map((m) => <MonthBlock key={`${m.year}-${m.month}`} m={m} />)
      )}
    </div>
  );
}

function MonthBlock({ m }: { m: MonthDebts }) {
  const { t } = useTranslation();
  const hasDebt = m.items.length > 0;
  const [open, setOpen] = useState(hasDebt);

  return (
    <Card className="!p-0 overflow-hidden">
      <button
        onClick={() => hasDebt && setOpen(!open)}
        className={
          'w-full flex items-center justify-between gap-3 px-4 py-3 ' +
          (hasDebt ? 'hover:bg-black/[0.02]' : 'cursor-default')
        }
      >
        <div className="flex items-center gap-2 font-semibold">
          {hasDebt
            ? (open ? <ChevronDown size={16} /> : <ChevronRight size={16} />)
            : <span className="inline-block w-4" />}
          {t(`hr.months.${m.month}`)} {m.year}
          {hasDebt && (
            <span className="text-xs px-2 py-0.5 rounded-full bg-black/5 text-ink-soft">
              {m.items.length} {t('hr.deptCard.people')}
            </span>
          )}
        </div>
        <span className={'tabular-nums font-bold ' + (hasDebt ? 'text-danger' : 'text-ink/30')}>
          {hasDebt ? formatUZS(m.total) : t('hr.debts.noDebt')}
        </span>
      </button>

      {open && hasDebt && (
        <div className="border-t border-black/5 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pl-4 pr-3">{t('hr.debts.colName')}</th>
                <th className="py-2 px-3 text-right">{t('hr.debts.colGross')}</th>
                <th className="py-2 px-3 text-right">{t('hr.debts.colPaid')}</th>
                <th className="py-2 px-3 text-right pr-4">{t('hr.debts.colDebt')}</th>
              </tr>
            </thead>
            <tbody>
              {m.items.map((it) => (
                <tr key={it.employee_id} className="border-b border-black/5 last:border-0">
                  <td className="py-2 pl-4 pr-3 font-medium">
                    <span className="flex items-center gap-2">
                      <span className={`inline-block w-2 h-2 rounded-full ${DEPT_DOT[it.department_type] ?? 'bg-gray-400'}`} />
                      {it.full_name}
                    </span>
                  </td>
                  <td className="py-2 px-3 text-right tabular-nums">{formatUZS(it.gross)}</td>
                  <td className="py-2 px-3 text-right tabular-nums text-warning">{formatUZS(it.paid)}</td>
                  <td className="py-2 px-3 text-right tabular-nums font-semibold text-danger pr-4">{formatUZS(it.debt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
