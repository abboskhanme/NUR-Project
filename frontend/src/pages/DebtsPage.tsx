import { useEffect, useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Search, Wallet, PackagePlus, Pencil, Trash2, ChevronRight, Coins,
  Building2, Globe, Eye,
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

/** Ta'minot bo'limidagi yetkazib beruvchi qarzi — bu yerda FAQAT KO'RINADI. */
interface TaminotDebt {
  supplier_id: string;
  scope: string;
  name: string;
  phone?: string | null;
  product_count: number;
  totals: {
    currency: string;
    total_purchased: number;
    total_paid: number;
    balance: number;
    stock_value: number;
  }[];
  last_purchase_at?: string | null;
}

const DEBTS_TYPES: Record<string, string> = {
  product: 'Mahsulot',
  credit: 'Kredit',
  loan: 'Qarz (shaxsdan)',
};
const DEBTS_TABS: Record<string, string> = {
  debts: 'Qarzlar',
  products: 'Ehtiyot qismlar',
};
/** Ta'minot bo'limlarining ko'rinishi (faqat belgi sifatida). */
const SCOPE_BADGE: Record<string, { label: string; icon: typeof Building2; cls: string }> = {
  ichki: { label: "Ichki ta'minot", icon: Building2, cls: 'bg-primary/10 text-primary' },
  tashqi: { label: "Tashqi ta'minot", icon: Globe, cls: 'bg-warning/15 text-warning' },
};
const DEBTS_CURRENCY: Record<string, string> = {
  UZS: "so'm",
  USD: 'dollar',
};
const DEBTS_UNITS: Record<string, string> = {
  dona: 'dona',
  kg: 'kg',
  metr: 'metr',
  list: 'list',
};

export default function DebtsPage() {
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
  // Ta'minot qarzlari — qarzlar ro'yxatining oxirida FAQAT KO'RISH uchun
  // chiqadi. Hech qanday amal yo'q: to'lov, kirim va tahrir Ta'minot bo'limida.
  // KPI kartalarida ham hisobga olingani uchun har doim so'raladi.
  const taminotQ = useQuery<TaminotDebt[]>({
    queryKey: ['debts-taminot-suppliers'],
    queryFn: () => api.get('/debts/taminot-suppliers').then((r) => r.data),
  });
  const products = productsQ.data ?? [];
  const s = summaryQ.data;

  /**
   * KPI kartalari uchun umumiy hisob: qarzlar moduli + ta'minot bo'limi.
   * Valyutalar hech qachon qo'shilmaydi — har biri alohida qator bo'lib chiqadi.
   * Filtrlar (qidiruv, «faqat qarzi borlar») bu yerga ta'sir qilmaydi: kartalar
   * doim to'liq manzarani ko'rsatadi.
   */
  const currencyTotals = useMemo(() => {
    const acc = new Map<string, CurrencyTotal>();
    const slotOf = (currency: string) => {
      let slot = acc.get(currency);
      if (!slot) {
        slot = { currency, total_purchased: 0, total_paid: 0, total_balance: 0, with_debt_count: 0 };
        acc.set(currency, slot);
      }
      return slot;
    };
    for (const c of s?.by_currency ?? []) {
      const slot = slotOf(c.currency);
      slot.total_purchased += c.total_purchased;
      slot.total_paid += c.total_paid;
      slot.total_balance += c.total_balance;
      slot.with_debt_count += c.with_debt_count;
    }
    for (const row of taminotQ.data ?? []) {
      for (const t of row.totals) {
        const slot = slotOf(t.currency);
        slot.total_purchased += t.total_purchased;
        slot.total_paid += t.total_paid;
        slot.total_balance += t.balance;
        if (t.balance > 0) slot.with_debt_count += 1;
      }
    }
    const rows = [...acc.values()].sort((a, b) => a.currency.localeCompare(b.currency));
    return rows.length
      ? rows
      : [{ currency: 'UZS', total_purchased: 0, total_paid: 0, total_balance: 0, with_debt_count: 0 }];
  }, [s, taminotQ.data]);

  // Ta'minotdan kelgan qarz bormi — kartalar ostidagi izoh shunga qarab chiqadi
  const hasTaminotDebt = (taminotQ.data ?? []).some(
    (row) => row.totals.some((t) => t.total_purchased > 0 || t.total_paid > 0),
  );

  // Qidiruv va «faqat qarzi borlar» filtri bu qatorlarga ham qo'llanadi —
  // ro'yxat bir butun bo'lib ko'rinishi kerak
  const taminotRows = (taminotQ.data ?? []).filter((row) => {
    const q = search.trim().toLowerCase();
    if (q && !row.name.toLowerCase().includes(q)) return false;
    if (onlyDebt && !row.totals.some((t) => t.balance > 0)) return false;
    return true;
  });

  // Tur nomi: tayyor kalitlar tarjima qilinadi, ixtiyoriy nom o'zicha ko'rsatiladi
  const typeLabel = (type: string) =>
    ['product', 'credit', 'loan'].includes(type) ? DEBTS_TYPES[type] : type;

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
      toast.success("O'chirildi");
      setDelProduct(null);
      refetchAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Bizning qarzlar</h1>
          <p className="text-sm text-ink-soft">Qarzga olinadigan ehtiyot qismlar va to'lovlar</p>
        </div>
        <button className="btn-primary" onClick={() => setEditProduct(null)}>
          <Plus size={16} /> Yangi qarz
        </button>
      </div>

      {/* KPI Cards — 3 ta: olib kelingan, to'langan, qarz qoldi (har valyuta uchun).
          Summalarga ta'minot qarzlari ham qo'shilgan — pastdagi ro'yxat bilan mos. */}
      <div className="space-y-3">
        {currencyTotals.map((c) => (
          <div key={c.currency}>
            {currencyTotals.length > 1 && (
              <div className="text-xs font-medium text-ink-soft mb-1.5">
                {DEBTS_CURRENCY[c.currency] ?? c.currency}
              </div>
            )}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <KpiCard
                tone="primary"
                label="Olib kelingan"
                value={formatMoney(c.total_purchased, c.currency)}
                icon={<PackagePlus size={18} />}
              />
              <KpiCard
                tone="success"
                label="To'langan"
                value={formatMoney(c.total_paid, c.currency)}
                icon={<Wallet size={18} />}
              />
              <KpiCard
                tone="danger"
                label="Qarz qoldi"
                value={formatMoney(c.total_balance, c.currency)}
                icon={<Coins size={18} />}
              />
            </div>
          </div>
        ))}
        {/* Summalar nimadan iboratligi aniq bo'lsin */}
        {hasTaminotDebt && (
          <p className="text-[11px] text-ink-soft flex items-center gap-1.5">
            <Eye size={12} /> Summalarga ta'minot bo'limidagi yetkazib beruvchilar
            qarzi ham qo'shilgan
          </p>
        )}
      </div>

      {/* Tabs + Search */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex gap-1.5 flex-wrap">
          {(['debts', 'products'] as const).map((key) => (
            <button key={key} onClick={() => setTab(key)}
              className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                tab === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
              {DEBTS_TABS[key]}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          {tab === 'debts' && (
            <label className="flex items-center gap-1.5 text-sm text-ink-soft cursor-pointer select-none">
              <input type="checkbox" checked={onlyDebt} onChange={(e) => setOnlyDebt(e.target.checked)} />
              Faqat qarzi borlar
            </label>
          )}
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 w-56" placeholder="Qidirish..."
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
        ) : products.length === 0 && !(tab === 'debts' && taminotRows.length) ? (
          <EmptyState title="Hali ehtiyot qism qo'shilmagan" description={'"Yangi ehtiyot qism" tugmasi orqali birinchisini qo\'shing'} />
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
                    <PackagePlus size={14} /> {p.debt_type === 'product' ? 'Olib kelish' : "Qo'shish"}
                  </button>
                  <button onClick={() => setAction({ product: p, kind: 'payment' })}
                          disabled={p.balance <= 0}
                          className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-success/10 text-success hover:bg-success/20 transition disabled:opacity-40">
                    <Wallet size={14} /> Qarz to'lash
                  </button>
                  <ChevronRight size={16} className="text-ink-soft" />
                </div>
              </div>
            ))}

            {/* ===== Ta'minot qarzlari — FAQAT KO'RISH =====
                Yetkazib beruvchi bo'yicha umumiy qarz shu ro'yxatda ko'rinib
                turadi, lekin bu yerdan hech narsa o'zgartirilmaydi: to'lov,
                kirim va tahrir Ta'minot bo'limida qoladi. */}
            {taminotRows.map((row) => {
              const badge = SCOPE_BADGE[row.scope];
              const BadgeIcon = badge?.icon ?? Building2;
              const debts = row.totals.filter((t) => t.balance > 0);
              return (
                <div key={row.supplier_id} className="flex items-center gap-3 py-3">
                  <div className="min-w-0 flex-1">
                    <div className="font-medium truncate flex items-center gap-2">
                      <span className="truncate">{row.name}</span>
                      {badge && (
                        <span className={`shrink-0 badge text-[10px] font-medium inline-flex items-center gap-1 ${badge.cls}`}>
                          <BadgeIcon size={10} /> {badge.label}
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-ink-soft truncate">
                      {row.product_count} ta mahsulot
                      {row.phone ? ` · ${row.phone}` : ''}
                      {row.last_purchase_at ? ` · ${formatDate(row.last_purchase_at)}` : ''}
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    {debts.length > 0 ? debts.map((t) => (
                      <div key={t.currency} className="font-bold text-danger tabular-nums">
                        {formatMoney(t.balance, t.currency)}
                      </div>
                    )) : (
                      <div className="font-bold text-success">{formatMoney(0, 'UZS')}</div>
                    )}
                  </div>
                  {/* Amal tugmalari o'rniga — faqat ko'rish belgisi */}
                  <div className="shrink-0 flex items-center gap-1 text-ink-soft"
                       title="Faqat ko'rish — boshqarish Ta'minot bo'limida">
                    <Eye size={15} />
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          /* ===================== EHTIYOT QISMLAR ===================== */
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Mahsulot</th>
                  <th className="py-2 pr-3">Ta'minotchi</th>
                  <th className="py-2 pr-3 text-right">Birlik narxi</th>
                  <th className="py-2 pr-3 text-right">Qarz qoldig'i</th>
                  <th className="py-2 pl-3 w-20"></th>
                </tr>
              </thead>
              <tbody>
                {products.map((p) => (
                  <tr key={p.id} className="border-b border-black/5 hover:bg-black/[0.02]">
                    <td className="py-2.5 pr-3 font-medium">
                      {p.name}
                      {p.debt_type === 'product' ? (
                        <span className="text-ink-soft font-normal"> · {DEBTS_UNITS[p.unit] ?? p.unit}</span>
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
        message="Ushbu mahsulot va uning barcha tranzaksiyalari o'chiriladi. Davom etamizmi?"
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
