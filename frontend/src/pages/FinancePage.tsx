import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Wallet, ArrowDownLeft, ArrowUpRight, Trash2,
  TrendingUp, TrendingDown, Banknote, RefreshCw, ArrowRightLeft,
  ChevronLeft, ChevronRight,
} from 'lucide-react';

import { api } from '@/api/client';
import BalanceCard from '@/components/ui/BalanceCard';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatDate, formatUSD, formatUZS } from '@/lib/format';
import TransactionModal from '@/features/finance/TransactionModal';
import CategoryModal from '@/features/finance/CategoryModal';
import ExchangeRateModal from '@/features/finance/ExchangeRateModal';
import GaznaTransferModal from '@/features/finance/GaznaTransferModal';
import DailyReport from '@/features/finance/DailyReport';

type Tab = 'overview' | 'daily' | 'categories' | 'rates';

interface Tx {
  id: string; date: string; type: string; amount: string; currency: string;
  note?: string | null; category_name?: string | null; status?: string;
  method?: string | null;
}
interface Category { id: string; name: string; kind: string }
interface Rate { id: string; date: string; usd_to_uzs: string; source: string }

const fmtMoney = (amount: string, currency: string) =>
  currency === 'USD' ? formatUSD(amount) : formatUZS(amount);

const MONTH_LABELS: Record<string, string> = {
  '1': 'Yanvar',
  '2': 'Fevral',
  '3': 'Mart',
  '4': 'Aprel',
  '5': 'May',
  '6': 'Iyun',
  '7': 'Iyul',
  '8': 'Avgust',
  '9': 'Sentabr',
  '10': 'Oktabr',
  '11': 'Noyabr',
  '12': 'Dekabr',
};

function TypeBadge({ type }: { type: string }) {
  if (type === 'income')
    return <span className="badge bg-success/10 text-success"><ArrowDownLeft size={12} /> Kirim</span>;
  return <span className="badge bg-danger/10 text-danger"><ArrowUpRight size={12} /> Chiqim</span>;
}

export default function FinancePage() {
  const qc = useQueryClient();
  const [tab, setTab] = useState<Tab>('overview');

  const [txModal, setTxModal] = useState(false);
  const [catModal, setCatModal] = useState(false);
  const [catKind, setCatKind] = useState<'income' | 'expense'>('expense');
  const [rateModal, setRateModal] = useState(false);
  const [transferModal, setTransferModal] = useState(false);

  const [delTx, setDelTx] = useState<Tx | null>(null);
  const [delCat, setDelCat] = useState<Category | null>(null);
  const [deleting, setDeleting] = useState(false);

  const [fType, setFType] = useState(''); // '', 'income', 'expense'
  const [page, setPage] = useState(1); // sahifa = kun indeksi (kunlik pagination)

  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);

  const balance = useQuery({
    queryKey: ['balance-summary'],
    queryFn: () => api.get('/finance/balance-summary').then((r) => r.data),
  });
  const summary = useQuery({
    queryKey: ['finance-summary', year, month],
    queryFn: () => api.get('/finance/summary', { params: { year, month } }).then((r) => r.data),
  });
  const categoriesQ = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: () => api.get('/finance/categories').then((r) => r.data),
  });
  const ratesQ = useQuery<Rate[]>({
    queryKey: ['exchange-rates'],
    queryFn: () => api.get('/finance/exchange-rates', { params: { limit: 30 } }).then((r) => r.data),
  });
  // Tanlangan oyning BARCHA tranzaksiyalarini bir martda olamiz, keyin kunlik guruhlaymiz.
  const tx = useQuery({
    queryKey: ['finance-transactions', fType, year, month],
    queryFn: () => {
      const mm = String(month).padStart(2, '0');
      const lastDay = new Date(year, month, 0).getDate();
      return api.get('/finance/transactions', {
        params: {
          page: 1,
          page_size: 1000,
          type: fType || undefined,
          date_from: `${year}-${mm}-01`,
          date_to: `${year}-${mm}-${String(lastDay).padStart(2, '0')}`,
        },
      }).then((r) => r.data);
    },
  });

  const allItems: Tx[] = tx.data?.items ?? [];
  // Kunlar (backend sana bo'yicha kamayuvchi tartibda qaytaradi — eng yangi kun birinchi)
  const dayKeys = useMemo(() => {
    const seen = new Set<string>();
    const days: string[] = [];
    for (const t of allItems) {
      if (!seen.has(t.date)) { seen.add(t.date); days.push(t.date); }
    }
    return days;
  }, [allItems]);
  const totalDays = dayKeys.length;
  const curDay = totalDays > 0 ? dayKeys[Math.min(page, totalDays) - 1] : null;
  const txItems: Tx[] = useMemo(
    () => allItems.filter((t) => t.date === curDay),
    [allItems, curDay],
  );
  // Filtr o'zgarsa — 1-sahifaga (eng yangi kunga) qaytamiz
  const setFilterType = (t: string) => { setFType(t); setPage(1); };
  const setFilterMonth = (m: number) => { setMonth(m); setPage(1); };
  const setFilterYear = (y: number) => { setYear(y); setPage(1); };
  const categories = categoriesQ.data ?? [];
  const rates = ratesQ.data ?? [];
  const latestRate = rates[0];

  const incomeCats = categories.filter((c) => c.kind === 'income');
  const expenseCats = categories.filter((c) => c.kind === 'expense');

  function refreshAll() {
    qc.invalidateQueries({ queryKey: ['balance-summary'] });
    qc.invalidateQueries({ queryKey: ['finance-summary'] });
    qc.invalidateQueries({ queryKey: ['finance-transactions'] });
  }

  async function confirmDelTx() {
    if (!delTx) return;
    setDeleting(true);
    try {
      await api.delete(`/finance/transactions/${delTx.id}`);
      toast.success("Tranzaksiya bekor qilindi");
      setDelTx(null);
      refreshAll();
    } catch (e: any) { toast.error(e?.response?.data?.detail || "Xatolik"); }
    finally { setDeleting(false); }
  }
  async function confirmDelCat() {
    if (!delCat) return;
    setDeleting(true);
    try {
      await api.delete(`/finance/categories/${delCat.id}`);
      toast.success("O'chirildi");
      setDelCat(null);
      qc.invalidateQueries({ queryKey: ['categories'] });
    } catch (e: any) { toast.error(e?.response?.data?.detail || "Xatolik"); }
    finally { setDeleting(false); }
  }

  const TABS: Array<{ key: Tab; label: string }> = [
    { key: 'overview', label: "Umumiy ko'rinish" },
    { key: 'daily', label: 'Kunlik hisobot' },
    { key: 'categories', label: 'Kategoriyalar' },
    { key: 'rates', label: 'Valyuta kursi' },
  ];

  const MONTH_KEYS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;

  const TYPE_FILTERS = [
    { key: '', label: 'Hammasi' },
    { key: 'income', label: 'Kirim' },
    { key: 'expense', label: 'Chiqim' },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Moliya</h1>
          <p className="text-sm text-ink-soft">Kassa va tranzaksiyalar</p>
        </div>
        <button className="btn-primary" onClick={() => setTxModal(true)}>
          <Plus size={16} /> Yangi tranzaksiya
        </button>
      </div>

      {/* Balance cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <BalanceCard title="UZS Balans" value={formatUZS(balance.data?.uzs ?? 0)} icon={<Wallet size={18} />} accent="primary" />
        <BalanceCard title="USD Balans" value={formatUSD(balance.data?.usd ?? 0)} icon={<Wallet size={18} />} accent="success"
          action={
            <button onClick={() => setTransferModal(true)}
              className="w-full flex items-center justify-center gap-1.5 text-sm border border-black/10 rounded-button py-1.5 hover:bg-black/5 transition">
              <ArrowRightLeft size={15} /> G'aznaga o'tkazish
            </button>
          } />
        <BalanceCard title="G'azna (USD)" value={formatUSD(balance.data?.gazna ?? 0)} icon={<Banknote size={18} />} accent="warning" />
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5 overflow-x-auto">
        {TABS.map((tb) => (
          <button key={tb.key} onClick={() => setTab(tb.key)}
            className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px whitespace-nowrap transition ${
              tab === tb.key ? 'border-primary text-primary' : 'border-transparent text-ink-soft hover:text-ink'}`}>
            {tb.label}
          </button>
        ))}
      </div>

      {/* === OVERVIEW === */}
      {tab === 'overview' && (
        <div className="space-y-4">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-sm text-ink-soft">Davr:</span>
            <select className="input w-auto" value={month} onChange={(e) => setFilterMonth(Number(e.target.value))}>
              {MONTH_KEYS.map((m) => (
                <option key={m} value={m}>{MONTH_LABELS[String(m)]}</option>
              ))}
            </select>
            <select className="input w-auto" value={year} onChange={(e) => setFilterYear(Number(e.target.value))}>
              {[now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2].map((y) =>
                <option key={y} value={y}>{y}</option>)}
            </select>
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <BalanceCard title="Kirim (UZS)" value={formatUZS(summary.data?.income_total ?? 0)}
                         icon={<TrendingUp size={18} />} accent="success" />
            <BalanceCard title="Chiqim (UZS)" value={formatUZS(summary.data?.expense_total ?? 0)}
                         icon={<TrendingDown size={18} />} accent="warning" />
            <BalanceCard title="Kirim (USD)" value={formatUSD(summary.data?.usd_income_total ?? 0)}
                         icon={<TrendingUp size={18} />} accent="success" />
            <BalanceCard title="Chiqim (USD)" value={formatUSD(summary.data?.usd_expense_total ?? 0)}
                         icon={<TrendingDown size={18} />} accent="warning" />
          </div>

          {/* Transactions list */}
          <Card>
            <div className="flex items-center justify-between gap-3 mb-4 flex-wrap">
              <h3 className="font-semibold text-base">
                Tranzaksiyalar
                {curDay && <span className="ml-2 text-ink-soft font-normal">— {formatDate(curDay)}</span>}
              </h3>
              <div className="flex gap-1 bg-black/5 rounded-button p-0.5">
                {TYPE_FILTERS.map((f) => (
                  <button key={f.key} onClick={() => setFilterType(f.key)}
                    className={`px-3 py-1 text-sm rounded-[6px] transition ${
                      fType === f.key ? 'bg-card shadow-sm font-medium' : 'text-ink-soft hover:text-ink'}`}>
                    {f.label}
                  </button>
                ))}
              </div>
            </div>

            {txItems.length === 0 ? (
              <EmptyState title="Tranzaksiyalar yo'q" description="Yangi tranzaksiya qo'shing" />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="text-left text-ink-soft border-b border-black/5">
                    <tr>
                      <th className="py-2 pr-3 whitespace-nowrap">Sana</th>
                      <th className="py-2 pr-3 whitespace-nowrap">Tur</th>
                      <th className="py-2 pr-[3.75rem] whitespace-nowrap">Kategoriya</th>
                      <th className="py-2 pr-[3.75rem] whitespace-nowrap">Summa</th>
                      <th className="py-2 pl-2 w-full">Izoh</th>
                      <th className="py-2 w-8"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {txItems.map((txItem) => {
                      const voided = txItem.status === 'void';
                      return (
                      <tr key={txItem.id} className={`border-b border-black/5 hover:bg-black/5 group ${voided ? 'opacity-50' : ''}`}>
                        <td className="py-2 pr-3 whitespace-nowrap">{formatDate(txItem.date)}</td>
                        <td className="py-2 pr-3"><TypeBadge type={txItem.type} /></td>
                        <td className="py-2 pr-[3.75rem] text-ink-soft whitespace-nowrap">
                          {txItem.category_name || '—'}
                          {txItem.method && (
                            <span className="ml-2 badge bg-black/5 text-ink-soft capitalize">{txItem.method}</span>
                          )}
                        </td>
                        <td className={`py-2 pr-[3.75rem] font-semibold whitespace-nowrap ${voided ? 'line-through text-ink-soft' :
                          txItem.type === 'income' ? 'text-success' : 'text-danger'}`}>
                          {txItem.type === 'income' ? '+' : '−'}{fmtMoney(txItem.amount, txItem.currency)}
                        </td>
                        <td className="py-2 pl-2 w-full text-ink-soft">
                          {voided && <span className="badge bg-danger/10 text-danger mr-2">Bekor qilingan</span>}
                          {txItem.note || (voided ? '' : '—')}
                        </td>
                        <td className="py-2">
                          {!voided && (
                            <button onClick={() => setDelTx(txItem)}
                              className="p-1 rounded text-ink-soft/40 hover:text-danger hover:bg-danger/10 opacity-0 group-hover:opacity-100 transition">
                              <Trash2 size={15} />
                            </button>
                          )}
                        </td>
                      </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}

            {/* Kunlik pagination — har sahifa bir kun */}
            {totalDays > 1 && (
              <div className="flex items-center justify-between mt-4 text-sm">
                <span className="text-ink-soft">{txItems.length} ta tranzaksiya</span>
                <div className="flex items-center gap-2">
                  <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page <= 1}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-40 disabled:cursor-not-allowed">
                    <ChevronLeft size={15} /> Yangiroq
                  </button>
                  <span className="text-ink-soft">{page} / {totalDays}-kun</span>
                  <button onClick={() => setPage((p) => Math.min(totalDays, p + 1))} disabled={page >= totalDays}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-40 disabled:cursor-not-allowed">
                    Eskiroq <ChevronRight size={15} />
                  </button>
                </div>
              </div>
            )}
          </Card>
        </div>
      )}

      {/* === DAILY REPORT === */}
      {tab === 'daily' && <DailyReport />}

      {/* === CATEGORIES === */}
      {tab === 'categories' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Card title="Kirim kategoriyalari" action={
            <button className="btn-primary !py-1.5 !text-sm"
                    onClick={() => { setCatKind('income'); setCatModal(true); }}>
              <Plus size={15} /> Qo'shish
            </button>
          }>
            <CatList items={incomeCats} onDelete={setDelCat} />
          </Card>
          <Card title="Chiqim kategoriyalari" action={
            <button className="btn-primary !py-1.5 !text-sm"
                    onClick={() => { setCatKind('expense'); setCatModal(true); }}>
              <Plus size={15} /> Qo'shish
            </button>
          }>
            <CatList items={expenseCats} onDelete={setDelCat} />
          </Card>
        </div>
      )}

      {/* === EXCHANGE RATES === */}
      {tab === 'rates' && (
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <BalanceCard title="Eng so'nggi kurs (1 USD)"
              value={latestRate ? formatUZS(latestRate.usd_to_uzs) : '—'}
              icon={<RefreshCw size={18} />} accent="primary" />
          </div>
          <Card title="Kurs tarixi" action={
            <button className="btn-primary !py-1.5 !text-sm" onClick={() => setRateModal(true)}>
              <Plus size={15} /> Kurs kiritish
            </button>
          }>
            {rates.length === 0 ? (
              <EmptyState title="Kurs ma'lumotlari yo'q" />
            ) : (
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Sana</th>
                    <th className="py-2 pr-3">1 USD = UZS</th>
                    <th className="py-2 pr-3">Manba</th>
                  </tr>
                </thead>
                <tbody>
                  {rates.map((r) => (
                    <tr key={r.id} className="border-b border-black/5">
                      <td className="py-2 pr-3">{formatDate(r.date)}</td>
                      <td className="py-2 pr-3 font-semibold">{formatUZS(r.usd_to_uzs)}</td>
                      <td className="py-2 pr-3">
                        <span className={`badge ${r.source === 'cbu' ? 'bg-primary/10 text-primary' : 'bg-black/5 text-ink-soft'}`}>
                          {r.source === 'cbu' ? 'Markaziy bank' : "Qo'lda"}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </Card>
        </div>
      )}

      {/* Modals */}
      {txModal && <TransactionModal onClose={() => setTxModal(false)} onSaved={refreshAll} />}
      {catModal && <CategoryModal defaultKind={catKind} onClose={() => setCatModal(false)}
                     onSaved={() => qc.invalidateQueries({ queryKey: ['categories'] })} />}
      {rateModal && <ExchangeRateModal onClose={() => setRateModal(false)}
                      onSaved={() => qc.invalidateQueries({ queryKey: ['exchange-rates'] })} />}
      {transferModal && <GaznaTransferModal usdBalance={Number(balance.data?.usd ?? 0)}
                          onClose={() => setTransferModal(false)} onSaved={refreshAll} />}

      <ConfirmModal open={!!delTx} title="Tranzaksiyani bekor qilish"
        message={`Bu tranzaksiya bekor qilinadi va balans qaytariladi. Yozuv tarixda "bekor qilingan" holatida qoladi. Davom etilsinmi?`}
        loading={deleting} onConfirm={confirmDelTx} onCancel={() => setDelTx(null)} />
      <ConfirmModal open={!!delCat} title="Kategoriyani o'chirish"
        message={`"${delCat?.name ?? ''}" kategoriyasi o'chiriladi. Davom etilsinmi?`}
        loading={deleting} onConfirm={confirmDelCat} onCancel={() => setDelCat(null)} />
    </div>
  );
}

function CatList({ items, onDelete }: { items: Category[]; onDelete: (c: Category) => void }) {
  if (items.length === 0) return <EmptyState title="Kategoriyalar yo'q" />;
  return (
    <div className="space-y-1">
      {items.map((c) => (
        <div key={c.id} className="flex items-center justify-between px-3 py-2 rounded-button hover:bg-black/5 group">
          <span className="text-sm">{c.name}</span>
          <button onClick={() => onDelete(c)}
            className="p-1 rounded text-ink-soft/40 hover:text-danger hover:bg-danger/10 opacity-0 group-hover:opacity-100 transition">
            <Trash2 size={15} />
          </button>
        </div>
      ))}
    </div>
  );
}
