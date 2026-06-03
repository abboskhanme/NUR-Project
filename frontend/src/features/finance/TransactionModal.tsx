import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, ArrowDownLeft, ArrowUpRight, Users } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS, formatUSD } from '@/lib/format';

interface Account { id: string; name: string; currency: string; ledger: string }
interface Category { id: string; name: string; kind: string }
interface Employee { id: string; full_name: string; currency: string }

type Mode = 'income' | 'expense' | 'employee';
type PayKind = 'advance' | 'salary';

const today = () => new Date().toISOString().slice(0, 10);

// Mingliklarni bo'shliq bilan ko'rsatamiz: 2000000 -> "2 000 000"
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

// Valyuta + G'azna bo'yicha mos hisobvaraqni avtomatik tanlaymiz (foydalanuvchiga ko'rinmaydi)
function resolveAccountId(accounts: Account[], currency: string, gazna: boolean): string | null {
  if (gazna) {
    const g = accounts.find((a) => a.ledger === 'gazna' && a.currency === 'USD')
           || accounts.find((a) => a.ledger === 'gazna');
    return g?.id ?? null;
  }
  const a = accounts.find((x) => x.currency === currency && x.ledger !== 'gazna');
  return a?.id ?? null;
}

const MODE_TABS: Array<{ key: Mode; label: string; icon: typeof Users; cls: string }> = [
  { key: 'income', label: 'Kirim', icon: ArrowDownLeft, cls: 'border-success bg-success/10 text-success' },
  { key: 'expense', label: 'Chiqim', icon: ArrowUpRight, cls: 'border-danger bg-danger/10 text-danger' },
  { key: 'employee', label: 'Xodim', icon: Users, cls: 'border-primary bg-primary/10 text-primary' },
];

const MONTHS = ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];

export default function TransactionModal({
  onClose, onSaved,
}: { onClose: () => void; onSaved: () => void }) {
  const [mode, setMode] = useState<Mode>('expense');
  const [date, setDate] = useState(today());
  const [categoryId, setCategoryId] = useState('');
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('UZS');
  const [gazna, setGazna] = useState(false);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  // Xodim rejimi
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
  // Oylik qoldig'i (net) — faqat oylik tanlanganda
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

  // UZS'ga qaytsa G'azna belgisini o'chiramiz (G'azna faqat USD)
  useEffect(() => { if (currency !== 'USD') setGazna(false); }, [currency]);
  // Xodim tanlansa valyutani moslaymiz
  useEffect(() => { if (selectedEmp) setCurrency(selectedEmp.currency || 'UZS'); }, [employeeId]); // eslint-disable-line

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const empCurrency = selectedEmp?.currency || 'UZS';
  const fmtEmp = (v: number) => empCurrency === 'USD' ? formatUSD(v) : formatUZS(v);

  async function handleSave() {
    setSaving(true);
    try {
      if (mode === 'employee') {
        if (!employeeId) { toast.error('Xodimni tanlang'); setSaving(false); return; }
        if (payKind === 'advance') {
          const amt = toNum(amount);
          if (!amt || amt <= 0) { toast.error("To'g'ri summa kiriting"); setSaving(false); return; }
          await api.post('/finance/employee-payments', {
            employee_id: employeeId, kind: 'advance', amount: amt,
            year, month, currency: empCurrency, note: note || null,
          });
        } else {
          if (netDue <= 0) { toast.error("To'lanadigan qoldiq oylik yo'q"); setSaving(false); return; }
          await api.post('/finance/employee-payments', {
            employee_id: employeeId, kind: 'salary',
            year, month, currency: empCurrency, note: note || null,
          });
        }
        toast.success('To\'lov saqlandi');
      } else {
        const amt = toNum(amount);
        if (!amt || amt <= 0) { toast.error("To'g'ri summa kiriting"); setSaving(false); return; }
        await api.post('/finance/transactions', {
          date, type: mode,
          category_id: categoryId || null,
          amount: amt, currency, amount_other_curr: 0,
          account_id: resolveAccountId(accounts, currency, gazna),
          note: note || null,
        });
        toast.success('Tranzaksiya saqlandi');
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">Yangi tranzaksiya</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-3">
          {/* Rejim: Kirim / Chiqim / Xodim */}
          <div className="grid grid-cols-3 gap-2">
            {MODE_TABS.map((tt) => {
              const Icon = tt.icon;
              const active = mode === tt.key;
              return (
                <button key={tt.key} type="button"
                  onClick={() => { setMode(tt.key); setCategoryId(''); }}
                  className={`flex flex-col items-center gap-1 py-2 rounded-button border text-sm font-medium transition ${
                    active ? tt.cls : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  <Icon size={18} /> {tt.label}
                </button>
              );
            })}
          </div>

          {/* === KIRIM / CHIQIM === */}
          {mode !== 'employee' && (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Sana</label>
                  <input type="date" className="input" value={date} onChange={(e) => setDate(e.target.value)} />
                </div>
                <div>
                  <label className="label">Kategoriya</label>
                  <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
                    <option value="">— Belgilanmagan —</option>
                    {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Summa *</label>
                  <input type="text" inputMode="decimal" className="input" placeholder="0"
                         value={amount} onChange={(e) => setAmount(formatAmount(e.target.value))} />
                </div>
                <div>
                  <label className="label">Valyuta</label>
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
                  G'aznaga (naqd dollar jamg'armasi)
                </label>
              )}
            </>
          )}

          {/* === XODIM (avans / oylik) === */}
          {mode === 'employee' && (
            <>
              <div>
                <label className="label">Xodim *</label>
                <select className="input" value={employeeId} onChange={(e) => setEmployeeId(e.target.value)}>
                  <option value="">Tanlang…</option>
                  {employees.map((e) => <option key={e.id} value={e.id}>{e.full_name}</option>)}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <button type="button" onClick={() => setPayKind('advance')}
                  className={`py-2 rounded-button border text-sm font-medium transition ${
                    payKind === 'advance' ? 'border-warning bg-warning/10 text-warning' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  Avans
                </button>
                <button type="button" onClick={() => setPayKind('salary')}
                  className={`py-2 rounded-button border text-sm font-medium transition ${
                    payKind === 'salary' ? 'border-primary bg-primary/10 text-primary' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  Oylik
                </button>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Oy</label>
                  <select className="input" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
                    {MONTHS.map((m, i) => <option key={i} value={i + 1}>{m}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Yil</label>
                  <select className="input" value={year} onChange={(e) => setYear(Number(e.target.value))}>
                    {[now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2].map((y) =>
                      <option key={y} value={y}>{y}</option>)}
                  </select>
                </div>
              </div>

              {payKind === 'advance' ? (
                <div>
                  <label className="label">Avans miqdori *</label>
                  <input type="text" inputMode="decimal" className="input" placeholder="0"
                         value={amount} onChange={(e) => setAmount(formatAmount(e.target.value))} />
                </div>
              ) : (
                <div className="p-3 rounded-button bg-primary/5 border border-primary/10">
                  <div className="text-sm text-ink-soft">To'lanadigan qoldiq oylik</div>
                  <div className="text-xl font-bold mt-0.5">
                    {!employeeId ? '—' : summaryQ.isLoading ? '…' : fmtEmp(netDue)}
                  </div>
                  {employeeId && !summaryQ.isLoading && netDue <= 0 && (
                    <div className="text-xs text-danger mt-1">Bu oy uchun qoldiq yo'q</div>
                  )}
                </div>
              )}

              <div>
                <label className="label">Izoh</label>
                <input className="input" value={note} onChange={(e) => setNote(e.target.value)}
                       placeholder={payKind === 'salary' ? "Oylik to'lovi" : 'Avans'} />
              </div>
            </>
          )}

          {mode !== 'employee' && (
            <div>
              <label className="label">Izoh</label>
              <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
            </div>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
