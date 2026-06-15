import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Search, Wallet, PackagePlus, Pencil, Trash2, ChevronRight, Coins,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatMoney, formatDate } from '@/lib/format';
import DebtProductModal, { type DebtProduct } from '@/features/debts/DebtProductModal';
import DebtActionModal from '@/features/debts/DebtActionModal';
import DebtTransactionsModal from '@/features/debts/DebtTransactionsModal';

interface CurrencyTotal {
  currency: string;
  total_purchased: number;
  total_paid: number;
  total_balance: number;
  with_debt_count: number;
}
interface Summary {
  by_currency: CurrencyTotal[];
  product_count: number;
}

export default function DebtsPage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const [tab, setTab] = useState<'debts' | 'products'>('debts');
  const [search, setSearch] = useState('');
  const [onlyDebt, setOnlyDebt] = useState(false);

  // Modal holatlari
  const [editProduct, setEditProduct] = useState<DebtProduct | null | undefined>(undefined);
  const [action, setAction] = useState<{ product: DebtProduct; kind: 'purchase' | 'payment' } | null>(null);
  const [detail, setDetail] = useState<DebtProduct | null>(null);
  const [delProduct, setDelProduct] = useState<DebtProduct | null>(null);
  const [deleting, setDeleting] = useState(false);

  const summaryQ = useQuery<Summary>({
    queryKey: ['debts-summary'],
    queryFn: () => api.get('/debts/summary').then((r) => r.data),
  });

  const productsQ = useQuery<DebtProduct[]>({
    queryKey: ['debts-products', search, onlyDebt],
    queryFn: () => api.get('/debts/products', {
      params: { search: search.trim() || undefined, with_debt: onlyDebt || undefined },
    }).then((r) => r.data),
  });
  const products = productsQ.data ?? [];
  const s = summaryQ.data;

  // Tur nomi: tayyor kalitlar tarjima qilinadi, ixtiyoriy nom o'zicha ko'rsatiladi
  const typeLabel = (type: string) =>
    ['product', 'credit', 'loan'].includes(type) ? t(`debts.type.${type}`) : type;

  // Ochiq tranzaksiyalar modalini yangilangan ma'lumot bilan sinxronlash
  useEffect(() => {
    if (!detail) return;
    const fresh = products.find((p) => p.id === detail.id);
    if (fresh && fresh !== detail) setDetail(fresh);
  }, [products]); // eslint-disable-line react-hooks/exhaustive-deps

  const refetchAll = () => {
    productsQ.refetch();
    summaryQ.refetch();
    qc.invalidateQueries({ queryKey: ['debt-tx'] });
  };

  async function confirmDeleteProduct() {
    if (!delProduct) return;
    setDeleting(true);
    try {
      await api.delete(`/debts/products/${delProduct.id}`);
      toast.success(t('debts.toast.deleted'));
      setDelProduct(null);
      refetchAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('debts.toast.error'));
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('debts.title')}</h1>
          <p className="text-sm text-ink-soft">{t('debts.subtitle')}</p>
        </div>
        <button className="btn-primary" onClick={() => setEditProduct(null)}>
          <Plus size={16} /> {t('debts.product.new')}
        </button>
      </div>

      {/* KPI Cards — 3 ta: olib kelingan, to'langan, qarz qoldi (har valyuta uchun) */}
      <div className="space-y-3">
        {(s?.by_currency?.length ? s.by_currency : [{ currency: 'UZS', total_purchased: 0, total_paid: 0, total_balance: 0, with_debt_count: 0 }]).map((c) => (
          <div key={c.currency}>
            {(s?.by_currency?.length ?? 0) > 1 && (
              <div className="text-xs font-medium text-ink-soft mb-1.5">
                {t(`debts.currency.${c.currency}`, { defaultValue: c.currency })}
              </div>
            )}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <KpiCard
                tone="primary"
                label={t('debts.kpi.purchased')}
                value={formatMoney(c.total_purchased, c.currency)}
                icon={<PackagePlus size={18} />}
              />
              <KpiCard
                tone="success"
                label={t('debts.kpi.paid')}
                value={formatMoney(c.total_paid, c.currency)}
                icon={<Wallet size={18} />}
              />
              <KpiCard
                tone="danger"
                label={t('debts.kpi.remaining')}
                value={formatMoney(c.total_balance, c.currency)}
                icon={<Coins size={18} />}
              />
            </div>
          </div>
        ))}
      </div>

      {/* Tabs + Search */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex gap-1.5">
          {(['debts', 'products'] as const).map((key) => (
            <button key={key} onClick={() => setTab(key)}
              className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                tab === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
              {t(`debts.tabs.${key}`)}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          {tab === 'debts' && (
            <label className="flex items-center gap-1.5 text-sm text-ink-soft cursor-pointer select-none">
              <input type="checkbox" checked={onlyDebt} onChange={(e) => setOnlyDebt(e.target.checked)} />
              {t('debts.onlyDebt')}
            </label>
          )}
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 w-56" placeholder={t('debts.search')}
                   value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>
      </div>

      {/* Content */}
      <Card>
        {productsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : products.length === 0 ? (
          <EmptyState title={t('debts.product.empty')} description={t('debts.product.emptyDesc')} />
        ) : tab === 'debts' ? (
          /* ===================== QARZLAR ===================== */
          <div className="divide-y divide-black/5">
            {products.map((p) => (
              <div key={p.id}
                   className="flex items-center gap-3 py-3 hover:bg-black/[0.02] -mx-2 px-2 rounded-button transition cursor-pointer"
                   onClick={() => setDetail(p)}>
                <div className="min-w-0 flex-1">
                  <div className="font-medium truncate flex items-center gap-2">
                    <span className="truncate">{p.name}</span>
                    {p.debt_type !== 'product' && (
                      <span className="shrink-0 badge bg-primary/10 text-primary text-[10px] font-medium">
                        {typeLabel(p.debt_type)}
                      </span>
                    )}
                  </div>
                  <div className="text-xs text-ink-soft">
                    {p.supplier ? `${p.supplier} · ` : ''}
                    {p.last_purchase_at ? formatDate(p.last_purchase_at) : '—'}
                  </div>
                </div>
                <div className="text-right shrink-0">
                  <div className={`font-bold ${p.balance > 0 ? 'text-danger' : 'text-success'}`}>
                    {formatMoney(p.balance, p.currency)}
                  </div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0" onClick={(e) => e.stopPropagation()}>
                  <button onClick={() => setAction({ product: p, kind: 'purchase' })}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-primary/10 text-primary hover:bg-primary/20 transition">
                    <PackagePlus size={14} /> {p.debt_type === 'product' ? t('debts.actions.purchase') : t('debts.actions.addDebt')}
                  </button>
                  <button onClick={() => setAction({ product: p, kind: 'payment' })}
                          disabled={p.balance <= 0}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-success/10 text-success hover:bg-success/20 transition disabled:opacity-40">
                    <Wallet size={14} /> {t('debts.actions.pay')}
                  </button>
                  <ChevronRight size={16} className="text-ink-soft" />
                </div>
              </div>
            ))}
          </div>
        ) : (
          /* ===================== EHTIYOT QISMLAR ===================== */
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">{t('debts.table.name')}</th>
                  <th className="py-2 pr-3">{t('debts.table.supplier')}</th>
                  <th className="py-2 pr-3 text-right">{t('debts.table.unitPrice')}</th>
                  <th className="py-2 pr-3 text-right">{t('debts.table.balance')}</th>
                  <th className="py-2 pl-3 w-20"></th>
                </tr>
              </thead>
              <tbody>
                {products.map((p) => (
                  <tr key={p.id} className="border-b border-black/5 hover:bg-black/[0.02]">
                    <td className="py-2.5 pr-3 font-medium">
                      {p.name}
                      {p.debt_type === 'product' ? (
                        <span className="text-ink-soft font-normal"> · {t(`debts.units.${p.unit}`, { defaultValue: p.unit })}</span>
                      ) : (
                        <span className="ml-2 badge bg-primary/10 text-primary text-[10px] font-medium">{typeLabel(p.debt_type)}</span>
                      )}
                    </td>
                    <td className="py-2.5 pr-3 text-ink-soft">{p.supplier || '—'}</td>
                    <td className="py-2.5 pr-3 text-right">{p.debt_type === 'product' ? formatMoney(p.unit_price, p.currency) : '—'}</td>
                    <td className={`py-2.5 pr-3 text-right font-medium ${p.balance > 0 ? 'text-danger' : 'text-ink-soft'}`}>
                      {formatMoney(p.balance, p.currency)}
                    </td>
                    <td className="py-2.5 pl-3">
                      <div className="flex items-center gap-1 justify-end">
                        <button onClick={() => setEditProduct(p)}
                                className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                          <Pencil size={15} />
                        </button>
                        <button onClick={() => setDelProduct(p)}
                                className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger">
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Modals */}
      {editProduct !== undefined && (
        <DebtProductModal product={editProduct} onClose={() => setEditProduct(undefined)} onSaved={refetchAll} />
      )}
      {action && (
        <DebtActionModal product={action.product} kind={action.kind}
                         onClose={() => setAction(null)} onSaved={refetchAll} />
      )}
      {detail && (
        <DebtTransactionsModal product={detail} onClose={() => setDetail(null)} onChanged={refetchAll} />
      )}
      <ConfirmModal
        open={!!delProduct}
        title={delProduct?.name ?? ''}
        message={t('debts.product.deleteConfirm')}
        loading={deleting}
        onConfirm={confirmDeleteProduct}
        onCancel={() => setDelProduct(null)}
      />
    </div>
  );
}

const KPI_TONES = {
  primary: { card: 'border-primary/20 bg-primary/5', text: 'text-primary', icon: 'bg-primary/15 text-primary' },
  success: { card: 'border-success/25 bg-success/10', text: 'text-success', icon: 'bg-success/20 text-success' },
  danger: { card: 'border-danger/25 bg-danger/10', text: 'text-danger', icon: 'bg-danger/20 text-danger' },
} as const;

function KpiCard({ tone, label, value, icon }: {
  tone: keyof typeof KPI_TONES;
  label: string;
  value: string;
  icon: React.ReactNode;
}) {
  const tn = KPI_TONES[tone];
  return (
    <div className={`rounded-card border p-4 flex items-start justify-between ${tn.card}`}>
      <div className="min-w-0">
        <div className={`text-sm font-medium ${tn.text}`}>{label}</div>
        <div className={`text-2xl font-bold mt-2 ${tn.text}`}>{value}</div>
      </div>
      <div className={`w-10 h-10 rounded-button flex items-center justify-center shrink-0 ${tn.icon}`}>
        {icon}
      </div>
    </div>
  );
}
