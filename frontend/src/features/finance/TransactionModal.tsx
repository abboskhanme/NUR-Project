import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, ArrowDownLeft, ArrowUpRight } from 'lucide-react';

import { api } from '@/api/client';

interface Account { id: string; name: string; currency: string; ledger: string }
interface Category { id: string; name: string; kind: string }

type Mode = 'income' | 'expense';

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
  const [mode, setMode] = useState<Mode>('expense');
  const [date, setDate] = useState(today());
  const [categoryId, setCategoryId] = useState('');
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('UZS');
  const [method, setMethod] = useState<'naqd' | 'karta'>('naqd');
  const [gazna, setGazna] = useState(false);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const accountsQ = useQuery<Account[]>({
    queryKey: ['accounts'],
    queryFn: () => api.get('/finance/accounts').then((r) => r.data),
  });
  const categoriesQ = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: () => api.get('/finance/categories').then((r) => r.data),
  });

  const accounts = accountsQ.data ?? [];
  const categories = useMemo(
    () => (categoriesQ.data ?? []).filter((c) => c.kind === mode),
    [categoriesQ.data, mode],
  );

  // Reset gazna if currency switches away from USD
  useEffect(() => { if (currency !== 'USD') setGazna(false); }, [currency]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const MODE_TABS: Array<{ key: Mode; label: string; icon: typeof ArrowDownLeft; cls: string }> = [
    { key: 'income', label: 'Kirim', icon: ArrowDownLeft, cls: 'border-success bg-success/10 text-success' },
    { key: 'expense', label: 'Chiqim', icon: ArrowUpRight, cls: 'border-danger bg-danger/10 text-danger' },
  ];

  async function handleSave() {
    setSaving(true);
    try {
      const amt = toNum(amount);
      if (!amt || amt <= 0) { toast.error("To'g'ri summa kiriting"); setSaving(false); return; }
      await api.post('/finance/transactions', {
        date, type: mode,
        category_id: categoryId || null,
        amount: amt, currency, amount_other_curr: 0,
        method,
        account_id: resolveAccountId(accounts, currency, gazna),
        note: note || null,
      });
      toast.success('Tranzaksiya saqlandi');
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
          {/* Mode: Income / Expense */}
          <div className="grid grid-cols-2 gap-2">
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

          <div>
            <label className="label">To'lov turi</label>
            <div className="grid grid-cols-2 gap-2">
              {(['naqd', 'karta'] as const).map((m) => (
                <button key={m} type="button" onClick={() => setMethod(m)}
                  className={`py-2 rounded-button border text-sm font-medium capitalize transition ${
                    method === m ? 'border-primary bg-primary/10 text-primary' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
                  {m === 'naqd' ? 'Naqd' : 'Karta'}
                </button>
              ))}
            </div>
          </div>

          {currency === 'USD' && (
            <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
              <input type="checkbox" checked={gazna} onChange={(e) => setGazna(e.target.checked)}
                     className="w-4 h-4 accent-warning" />
              G'aznaga (naqd dollar jamg'armasi)
            </label>
          )}

          <div>
            <label className="label">Izoh</label>
            <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">Bekor qilish</button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
