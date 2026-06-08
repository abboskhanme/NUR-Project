import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import { X, ArrowDownLeft, ArrowUpRight, Users } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS, formatUSD } from '@/lib/format';

interface Account { id: string; name: string; currency: string; ledger: string }
interface Category { id: string; name: string; kind: string }
interface Employee { id: string; full_name: string; currency: string }

type Mode = 'income' | 'expense' | 'employee';
type PayKind = 'advance' | 'salary';

const today = () => new Date().toISOString().slice(0, 10);

// Format thousands with spaces: 2000000 -> "2 000 000"
function formatAmount(s: string): string {
  const cleaned = s.replace(/[^\d.]/g, '');
  const firstDot = cleaned.indexOf('.');
  const intPart = (firstDot === -1 ? cleaned : cleaned.slice(0, firstDot)).replace(/^0+(?=\d)/, '');
  const intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  if (firstDot === -1) return intFmt;
  const decPart = cleaned.slice(firstDot + 1).replace(/\./g, '').slice(0, 2);
  return `${intFmt || '0'}.${decPart}`;
}
const toNum = (s: string) => parseFloat(s.replace(/[^\d.]/g, '')) || 0;

// Automatically pick matching account by currency and gazna flag (hidden from user)
function resolveAccountId(accounts: Account[], currency: string, gazna: boolean): string | null {
  if (gazna) {
    const g = accounts.find((a) => a.ledger === 'gazna' && a.currency === 'USD')
           || accounts.find((a) => a.ledger === 'gazna');
    return g?.id ?? null;
  }
  const a = accounts.find((x) => x.currency === currency && x.ledger !== 'gazna');
  return a?.id ?? null;
}

export default function TransactionModal({
  onClose, onSaved,
}: { onClose: () => void; onSaved: () => void }) {
  const { t } = useTranslation();
  const [mode, setMode] = useState<Mode>('expense');
  const [date, setDate] = useState(today());
  const [categoryId, setCategoryId] = useState('');
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('UZS');
  const [gazna, setGazna] = useState(false);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  // Employee payment mode
  const [employeeId, setEmployeeId] = useState('');
  const [payKind, setPayKind] = useState<PayKind>('advance');
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);

  const accountsQ = useQuery<Account[]>({
    queryKey: ['accounts'],
    queryFn: () => api.get('/finance/accounts').then((r) => r.data),
  });
  const categoriesQ = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: () => api.get('/finance/categories').then((r) => r.data),
  });
  const employeesQ = useQuery<Employee[]>({
    queryKey: ['hr-employees-active'],
    queryFn: () => api.get('/hr/employees', { params: { page_size: 200, status: 'active' } })
      .then((r) => r.data.items ?? []),
    enabled: mode === 'employee',
  });
  // Monthly net due — only when salary mode and employee selected
  const summaryQ = useQuery({
    queryKey: ['hr-emp-summary', employeeId, year, month],
    queryFn: () => api.get(`/hr/employees/${employeeId}/summary`, { params: { year, month } })
      .then((r) => r.data),
    enabled: mode === 'employee' && payKind === 'salary' && !!employeeId,
  });

  const accounts = accountsQ.data ?? [];
  const employees = employeesQ.data ?? [];
  const categories = useMemo(
    () => (categoriesQ.data ?? []).filter((c) => c.kind === mode),
    [categoriesQ.data, mode],
  );
  const selectedEmp = employees.find((e) => e.id === employeeId);
  const netDue = Number(summaryQ.data?.net ?? 0);

  // Reset gazna if currency switches away from USD
  useEffect(() => { if (currency !== 'USD') setGazna(false); }, [currency]);
  // Sync currency when employee is selected
  useEffect(() => { if (selectedEmp) setCurrency(selectedEmp.currency || 'UZS'); }, [employeeId]); // eslint-disable-line

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const empCurrency = selectedEmp?.currency || 'UZS';
  const fmtEmp = (v: number) => empCurrency === 'USD' ? formatUSD(v) : formatUZS(v);

  const MODE_TABS: Array<{ key: Mode; labelKey: string; icon: typeof Users; cls: string }> = [
    { key: 'income', labelKey: 'finance.type.income', icon: ArrowDownLeft, cls: 'border-success bg-success/10 text-success' },
    { key: 'expense', labelKey: 'finance.type.expense', icon: ArrowUpRight, cls: 'border-danger bg-danger/10 text-danger' },
    { key: 'employee', labelKey: 'finance.type.employee', icon: Users, cls: 'border-primary bg-primary/10 text-primary' },
  ];

  const MONTH_KEYS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;

  async function handleSave() {
    setSaving(true);
    try {
      if (mode === 'employee') {
        if (!employeeId) { toast.error(t('finance.empPayment.employeeRequired')); setSaving(false); return; }
        if (payKind === 'advance') {
          const amt = toNum(amount);
          if (!amt || amt <= 0) { toast.error(t('finance.txModal.amountRequired')); setSaving(false); return; }
          await api.post('/finance/employee-payments', {
            employee_id: employeeId, kind: 'advance', amount: amt,
            year, month, currency: empCurrency, note: note || null,
          });
        } else {
          if (netDue <= 0) { toast.error(t('finance.empPayment.noBalanceError')); setSaving(false); return; }
          await api.post('/finance/employee-payments', {
            employee_id: employeeId, kind: 'salary',
            year, month, currency: empCurrency, note: note || null,
          });
        }
        toast.success(t('finance.empPayment.savedSuccess'));
      } else {
        const amt = toNum(amount);
        if (!amt || amt <= 0) { toast.error(t('finance.txModal.amountRequired')); setSaving(false); return; }
        await api.post('/finance/transactions', {
          date, type: mode,
          category_id: categoryId || null,
          amount: amt, currency, amount_other_curr: 0,
          account_id: resolveAccountId(accounts, currency, gazna),
          note: note || null,
        });
        toast.success(t('finance.txModal.savedSuccess'));
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('finance.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{t('finance.txModal.title')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          {/* Mode: Income / Expense / Employee */}
          <div className="grid grid-cols-3 gap-2">
            {MODE_TABS.map((tt) => {
              const Icon = tt.icon;
              const active = mode === tt.key;
              return (
                <button key={tt.key} type="button"
                  onClick={() => { setMode(tt.key); setCategoryId(''); }}
                  className={`flex flex-col items-center gap-1 py-2 rounded-button border text-sm font-medium transition ${
                    active ? tt.cls : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  <Icon size={18} /> {t(tt.labelKey)}
                </button>
              );
            })}
          </div>

          {/* === INCOME / EXPENSE === */}
          {mode !== 'employee' && (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">{t('finance.txModal.dateLabel')}</label>
                  <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
                </div>
                <div>
                  <label className="label">{t('finance.txModal.categoryLabel')}</label>
                  <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
                    <option value="">{t('finance.txModal.categoryNone')}</option>
                    {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">{t('finance.txModal.amountLabel')}</label>
                  <input type="text" inputMode="decimal" className="input" placeholder="0"
                         value={amount} onChange={(e) => setAmount(formatAmount(e.target.value))} />
                </div>
                <div>
                  <label className="label">{t('finance.txModal.currencyLabel')}</label>
                  <select className="input" value={currency} onChange={(e) => setCurrency(e.target.value)}>
                    <option value="UZS">UZS</option>
                    <option value="USD">USD</option>
                  </select>
                </div>
              </div>

              {currency === 'USD' && (
                <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
                  <input type="checkbox" checked={gazna} onChange={(e) => setGazna(e.target.checked)}
                         className="w-4 h-4 accent-warning" />
                  {t('finance.txModal.gaznaLabel')}
                </label>
              )}
            </>
          )}

          {/* === EMPLOYEE (advance / salary) === */}
          {mode === 'employee' && (
            <>
              <div>
                <label className="label">{t('finance.empPayment.employeeLabel')}</label>
                <select className="input" value={employeeId} onChange={(e) => setEmployeeId(e.target.value)}>
                  <option value="">{t('common.select')}…</option>
                  {employees.map((e) => <option key={e.id} value={e.id}>{e.full_name}</option>)}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <button type="button" onClick={() => setPayKind('advance')}
                  className={`py-2 rounded-button border text-sm font-medium transition ${
                    payKind === 'advance' ? 'border-warning bg-warning/10 text-warning' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  {t('finance.empPayment.advance')}
                </button>
                <button type="button" onClick={() => setPayKind('salary')}
                  className={`py-2 rounded-button border text-sm font-medium transition ${
                    payKind === 'salary' ? 'border-primary bg-primary/10 text-primary' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  {t('finance.empPayment.salary')}
                </button>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">{t('finance.empPayment.monthLabel')}</label>
                  <select className="input" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
                    {MONTH_KEYS.map((m) => (
                      <option key={m} value={m}>{t(`finance.months.${m}`)}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="label">{t('finance.empPayment.yearLabel')}</label>
                  <select className="input" value={year} onChange={(e) => setYear(Number(e.target.value))}>
                    {[now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2].map((y) =>
                      <option key={y} value={y}>{y}</option>)}
                  </select>
                </div>
              </div>

              {payKind === 'advance' ? (
                <div>
                  <label className="label">{t('finance.empPayment.advanceAmountLabel')}</label>
                  <input type="text" inputMode="decimal" className="input" placeholder="0"
                         value={amount} onChange={(e) => setAmount(formatAmount(e.target.value))} />
                </div>
              ) : (
                <div className="p-3 rounded-button bg-primary/5 border border-primary/10">
                  <div className="text-sm text-ink-soft">{t('finance.empPayment.netDueLabel')}</div>
                  <div className="text-xl font-bold mt-0.5">
                    {!employeeId ? '—' : summaryQ.isLoading ? '…' : fmtEmp(netDue)}
                  </div>
                  {employeeId && !summaryQ.isLoading && netDue <= 0 && (
                    <div className="text-xs text-danger mt-1">{t('finance.empPayment.noBalance')}</div>
                  )}
                </div>
              )}

              <div>
                <label className="label">{t('finance.txModal.noteLabel')}</label>
                <input className="input" value={note} onChange={(e) => setNote(e.target.value)}
                       placeholder={payKind === 'salary' ? t('finance.empPayment.notePlaceholderSalary') : t('finance.empPayment.notePlaceholderAdvance')} />
              </div>
            </>
          )}

          {mode !== 'employee' && (
            <div>
              <label className="label">{t('finance.txModal.noteLabel')}</label>
              <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
            </div>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">{t('actions.cancel')}</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('finance.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
