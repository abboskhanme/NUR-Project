import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, TrendingUp } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatUZS } from '@/lib/format';

const HR_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentyabr', '10': 'Oktyabr', '11': 'Noyabr', '12': 'Dekabr',
};
const SALARY_TYPES = [
  { value: 'hourly', label: 'Soatbay' },
  { value: 'daily', label: 'Kunbay' },
  { value: 'fixed', label: 'Belgilangan (oylik)' },
  { value: 'kpi', label: 'KPI' },
];
const TYPE_LABEL: Record<string, string> = Object.fromEntries(SALARY_TYPES.map((s) => [s.value, s.label]));

interface Rate {
  id: string;
  effective_from: string;
  salary_type: string;
  amount: string;
  currency: string;
  note?: string | null;
}

function clean(raw: string) {
  return raw.replace(/[^\d]/g, '');
}
function display(raw: string) {
  if (!raw) return '';
  return raw.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}

function monthLabel(iso: string, monthNameFn: (m: number) => string): string {
  // "YYYY-MM-DD" -> "May 2026"
  const [y, m] = iso.split('-').map(Number);
  return `${monthNameFn((m || 1))} ${y}`;
}

export default function SalaryRatesCard({ employeeId }: { employeeId: string }) {
  const qc = useQueryClient();
  const now = new Date();
  const [open, setOpen] = useState(false);
  const [effYear, setEffYear] = useState(now.getFullYear());
  const [effMonth, setEffMonth] = useState(now.getMonth() + 1); // 1-12
  const [salaryType, setSalaryType] = useState('hourly');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const { data, isLoading } = useQuery<Rate[]>({
    queryKey: ['hr', 'salary-rates', employeeId],
    queryFn: () => api.get(`/hr/employees/${employeeId}/salary-rates`).then((r) => r.data),
  });
  const items = data ?? [];

  const getMonthName = (m: number) => HR_MONTHS[String(m)];

  async function handleSave() {
    if (!amount || parseInt(amount, 10) <= 0) {
      toast.error('Summani kiriting');
      return;
    }
    setSaving(true);
    try {
      const effectiveFrom = `${effYear}-${String(effMonth).padStart(2, '0')}-01`;
      await api.post(`/hr/employees/${employeeId}/salary-rates`, {
        effective_from: effectiveFrom,
        salary_type: salaryType,
        amount,
        note: note || null,
      });
      toast.success("Yangi stavka qo'shildi");
      setAmount(''); setNote(''); setOpen(false);
      qc.invalidateQueries({ queryKey: ['hr', 'salary-rates', employeeId] });
      qc.invalidateQueries({ queryKey: ['hr', 'employee', employeeId] });
      qc.invalidateQueries({ queryKey: ['hr', 'summary', employeeId] });
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card
      title="Stavka tarixi"
      action={
        <button onClick={() => setOpen((o) => !o)} className="btn-ghost">
          <Plus size={15} /> Yangi stavka
        </button>
      }
    >
      <p className="text-xs text-ink-soft mb-3">Stavka o'zgarsa, yangi sanadan boshlab amal qiladi. Eski oylar avvalgi stavka bilan saqlanadi.</p>

      {open && (
        <div className="flex items-end gap-x-6 gap-y-3 flex-wrap mb-4 p-4 bg-black/[0.02] rounded-button">
          <div className="flex flex-col gap-1">
            <label className="label !mb-0">Qaysi oydan</label>
            <div className="flex gap-2">
              <select className="input !w-32" value={effMonth} onChange={(e) => setEffMonth(Number(e.target.value))}>
                {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                  <option key={m} value={m}>{HR_MONTHS[String(m)]}</option>
                ))}
              </select>
              <select className="input !w-24" value={effYear} onChange={(e) => setEffYear(Number(e.target.value))}>
                {[now.getFullYear() + 1, now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2].map((y) => (
                  <option key={y} value={y}>{y}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="flex flex-col gap-1">
            <label className="label !mb-0">Turi</label>
            <select className="input !w-40" value={salaryType} onChange={(e) => setSalaryType(e.target.value)}>
              {SALARY_TYPES.map((s) => <option key={s.value} value={s.value}>{s.label}</option>)}
            </select>
          </div>
          <div className="flex flex-col gap-1">
            <label className="label !mb-0">Summa</label>
            <input
              className="input !w-40"
              inputMode="numeric"
              placeholder="0"
              value={display(amount)}
              onChange={(e) => setAmount(clean(e.target.value))}
            />
          </div>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? '...' : 'Saqlash'}
          </button>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 2 }).map((_, i) => (
            <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <EmptyState title="Stavka yo'q" description="Boshlang'ich stavka qo'shilmagan." />
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
