import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import {
  Plus, Wallet, ArrowDownLeft, ArrowUpRight, Trash2,
  TrendingUp, TrendingDown, Banknote, RefreshCw,
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

type Tab = 'overview' | 'categories' | 'rates';

interface Tx {
  id: string; date: string; type: string; amount: string; currency: string;
  note?: string | null; category_name?: string | null; status?: string;
}
interface Category { id: string; name: string; kind: string }
interface Rate { id: string; date: string; usd_to_uzs: string; source: string }

const fmtMoney = (amount: string, currency: string) =>
  currency === 'USD' ? formatUSD(amount) : formatUZS(amount);

function TypeBadge({ type }: { type: string }) {
  const { t } = useTranslation();
  if (type === 'income')
    return <span className="badge bg-success/10 text-success"><ArrowDownLeft size={12} /> {t('finance.type.income')}</span>;
  return <span className="badge bg-danger/10 text-danger"><ArrowUpRight size={12} /> {t('finance.type.expense')}</span>;
}

export default function FinancePage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const [tab, setTab] = useState<Tab>('overview');

  const [txModal, setTxModal] = useState(false);
  const [catModal, setCatModal] = useState(false);
  const [catKind, setCatKind] = useState<'income' | 'expense'>('expense');
  const [rateModal, setRateModal] = useState(false);

  const [delTx, setDelTx] = useState<Tx | null>(null);
  const [delCat, setDelCat] = useState<Category | null>(null);
  const [deleting, setDeleting] = useState(false);

  const [fType, setFType] = useState(''); // '', 'income', 'expense'

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
  const tx = useQuery({
    queryKey: ['finance-transactions', fType, year, month],
    queryFn: () => {
      const mm = String(month).padStart(2, '0');
      const lastDay = new Date(year, month, 0).getDate();
      return api.get('/finance/transactions', {
        params: {
          page_size: 50,
          type: fType || undefined,
          date_from: `${year}-${mm}-01`,
          date_to: `${year}-${mm}-${String(lastDay).padStart(2, '0')}`,
        },
      }).then((r) => r.data);
    },
  });

  const txItems: Tx[] = tx.data?.items ?? [];
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
      toast.success(t('finance.transactions.voidedToast'));
      setDelTx(null);
      refreshAll();
    } catch (e: any) { toast.error(e?.response?.data?.detail || t('finance.error')); }
    finally { setDeleting(false); }
  }
  async function confirmDelCat() {
    if (!delCat) return;
    setDeleting(true);
    try {
      await api.delete(`/finance/categories/${delCat.id}`);
      toast.success(t('common.deleted'));
      setDelCat(null);
      qc.invalidateQueries({ queryKey: ['categories'] });
    } catch (e: any) { toast.error(e?.response?.data?.detail || t('finance.error')); }
    finally { setDeleting(false); }
  }

  const TABS: Array<{ key: Tab; labelKey: string }> = [
    { key: 'overview', labelKey: 'finance.tabs.overview' },
    { key: 'categories', labelKey: 'finance.tabs.categories' },
    { key: 'rates', labelKey: 'finance.tabs.rates' },
  ];

  const MONTH_KEYS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const;

  const TYPE_FILTERS = [
    { key: '', labelKey: 'finance.filter.all' },
    { key: 'income', labelKey: 'finance.filter.income' },
    { key: 'expense', labelKey: 'finance.filter.expense' },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('finance.title')}</h1>
          <p className="text-sm text-ink-soft">{t('finance.subtitle')}</p>
        </div>
        <button className="btn-primary" onClick={() => setTxModal(true)}>
          <Plus size={16} /> {t('finance.newTransaction')}
        </button>
      </div>

      {/* Balance cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <BalanceCard title={t('finance.balance.uzs')} value={formatUZS(balance.data?.uzs ?? 0)} icon={<Wallet size={18} />} accent="primary" />
        <BalanceCard title={t('finance.balance.usd')} value={formatUSD(balance.data?.usd ?? 0)} icon={<Wallet size={18} />} accent="success" />
        <BalanceCard title={t('finance.balance.gazna')} value={formatUSD(balance.data?.gazna ?? 0)} icon={<Banknote size={18} />} accent="warning" />
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5 overflow-x-auto">
        {TABS.map((tb) => (
          <button key={tb.key} onClick={() => setTab(tb.key)}
            className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px whitespace-nowrap transition ${
              tab === tb.key ? 'border-primary text-primary' : 'border-transparent text-ink-soft hover:text-ink'}`}>
            {t(tb.labelKey)}
          </button>
        ))}
      </div>

      {/* === OVERVIEW === */}
      {tab === 'overview' && (
        <div className="space-y-4">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-sm text-ink-soft">{t('finance.period')}:</span>
            <select className="input w-auto" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
              {MONTH_KEYS.map((m) => (
                <option key={m} value={m}>{t(`finance.months.${m}`)}</option>
              ))}
            </select>
            <select className="input w-auto" value={year} onChange={(e) => setYear(Number(e.target.value))}>
              {[now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2].map((y) =>
                <option key={y} value={y}>{y}</option>)}
            </select>
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <BalanceCard title={t('finance.kpi.incomeUZS')} value={formatUZS(summary.data?.income_total ?? 0)}
                         icon={<TrendingUp size={18} />} accent="success" />
            <BalanceCard title={t('finance.kpi.expenseUZS')} value={formatUZS(summary.data?.expense_total ?? 0)}
                         icon={<TrendingDown size={18} />} accent="warning" />
            <BalanceCard title={t('finance.kpi.incomeUSD')} value={formatUSD(summary.data?.usd_income_total ?? 0)}
                         icon={<TrendingUp size={18} />} accent="success" />
            <BalanceCard title={t('finance.kpi.expenseUSD')} value={formatUSD(summary.data?.usd_expense_total ?? 0)}
                         icon={<TrendingDown size={18} />} accent="warning" />
          </div>

          {/* Transactions list */}
          <Card>
            <div className="flex items-center justify-between gap-3 mb-4 flex-wrap">
              <h3 className="font-semibold text-base">{t('finance.transactions.title')}</h3>
              <div className="flex gap-1 bg-black/5 rounded-button p-0.5">
                {TYPE_FILTERS.map((f) => (
                  <button key={f.key} onClick={() => setFType(f.key)}
                    className={`px-3 py-1 text-sm rounded-[6px] transition ${
                      fType === f.key ? 'bg-card shadow-sm font-medium' : 'text-ink-soft hover:text-ink'}`}>
                    {t(f.labelKey)}
                  </button>
                ))}
              </div>
            </div>

            {txItems.length === 0 ? (
              <EmptyState title={t('finance.transactions.empty')} description={t('finance.transactions.emptyDesc')} />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="text-left text-ink-soft border-b border-black/5">
                    <tr>
                      <th className="py-2 pr-3 whitespace-nowrap">{t('finance.transactions.colDate')}</th>
                      <th className="py-2 pr-3 whitespace-nowrap">{t('finance.transactions.colType')}</th>
                      <th className="py-2 pr-[3.75rem] whitespace-nowrap">{t('finance.transactions.colCategory')}</th>
                      <th className="py-2 pr-[3.75rem] whitespace-nowrap">{t('finance.transactions.colAmount')}</th>
                      <th className="py-2 pl-2 w-full">{t('finance.transactions.colNote')}</th>
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
                        <td className="py-2 pr-[3.75rem] text-ink-soft whitespace-nowrap">{txItem.category_name || '—'}</td>
                        <td className={`py-2 pr-[3.75rem] font-semibold whitespace-nowrap ${voided ? 'line-through text-ink-soft' :
                          txItem.type === 'income' ? 'text-success' : 'text-danger'}`}>
                          {txItem.type === 'income' ? '+' : '−'}{fmtMoney(txItem.amount, txItem.currency)}
                        </td>
                        <td className="py-2 pl-2 w-full text-ink-soft">
                          {voided && <span className="badge bg-danger/10 text-danger mr-2">{t('finance.transactions.voided')}</span>}
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
          </Card>
        </div>
      )}

      {/* === CATEGORIES === */}
      {tab === 'categories' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <Card title={t('finance.categories.incomeTitle')} action={
            <button className="btn-primary !py-1.5 !text-sm"
                    onClick={() => { setCatKind('income'); setCatModal(true); }}>
              <Plus size={15} /> {t('common.add')}
            </button>
          }>
            <CatList items={incomeCats} onDelete={setDelCat} />
          </Card>
          <Card title={t('finance.categories.expenseTitle')} action={
            <button className="btn-primary !py-1.5 !text-sm"
                    onClick={() => { setCatKind('expense'); setCatModal(true); }}>
              <Plus size={15} /> {t('common.add')}
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
            <BalanceCard title={t('finance.rates.latestRate')}
              value={latestRate ? formatUZS(latestRate.usd_to_uzs) : '—'}
              icon={<RefreshCw size={18} />} accent="primary" />
          </div>
          <Card title={t('finance.rates.historyTitle')} action={
            <button className="btn-primary !py-1.5 !text-sm" onClick={() => setRateModal(true)}>
              <Plus size={15} /> {t('finance.rates.addButton')}
            </button>
          }>
            {rates.length === 0 ? (
              <EmptyState title={t('finance.rates.empty')} />
            ) : (
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">{t('finance.rates.colDate')}</th>
                    <th className="py-2 pr-3">{t('finance.rates.colRate')}</th>
                    <th className="py-2 pr-3">{t('finance.rates.colSource')}</th>
                  </tr>
                </thead>
                <tbody>
                  {rates.map((r) => (
                    <tr key={r.id} className="border-b border-black/5">
                      <td className="py-2 pr-3">{formatDate(r.date)}</td>
                      <td className="py-2 pr-3 font-semibold">{formatUZS(r.usd_to_uzs)}</td>
                      <td className="py-2 pr-3">
                        <span className={`badge ${r.source === 'cbu' ? 'bg-primary/10 text-primary' : 'bg-black/5 text-ink-soft'}`}>
                          {r.source === 'cbu' ? t('finance.rates.sourceCbu') : t('finance.rates.sourceManual')}
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

      <ConfirmModal open={!!delTx} title={t('finance.txModal.deleteTitle')}
        message={t('finance.txModal.deleteMessage')}
        loading={deleting} onConfirm={confirmDelTx} onCancel={() => setDelTx(null)} />
      <ConfirmModal open={!!delCat} title={t('finance.categories.deleteTitle')}
        message={t('finance.categories.deleteMessage', { name: delCat?.name ?? '' })}
        loading={deleting} onConfirm={confirmDelCat} onCancel={() => setDelCat(null)} />
    </div>
  );
}

function CatList({ items, onDelete }: { items: Category[]; onDelete: (c: Category) => void }) {
  const { t } = useTranslation();
  if (items.length === 0) return <EmptyState title={t('finance.categories.empty')} />;
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
