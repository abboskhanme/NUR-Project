import { useEffect, useMemo, useState } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Search, Wallet, PackagePlus, Pencil, Trash2, ChevronRight, ChevronLeft, Coins,
  Building2, Globe, CalendarDays,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatMoney, formatDateTime, formatDate } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import { cn } from '@/lib/cn';

import TaminotProductModal, { type TaminotProduct } from '@/features/taminot/TaminotProductModal';
import TaminotActionModal from '@/features/taminot/TaminotActionModal';
import TaminotTransactionsModal from '@/features/taminot/TaminotTransactionsModal';
import TaminotReportCharts from '@/features/taminot/TaminotReportCharts';

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
interface TxLog {
  id: string;
  product_id: string;
  product_name: string;
  supplier?: string | null;
  kind: 'purchase' | 'payment';
  qty: number;
  unit_price: number;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
}

const CURRENCY_LABEL: Record<string, string> = { UZS: "so'm", USD: 'dollar' };
const UNIT_LABEL: Record<string, string> = { dona: 'dona', kg: 'kg', metr: 'metr', list: 'list' };
const SCOPE_META: Record<string, { title: string; icon: typeof Building2 }> = {
  ichki: { title: 'Ichki taʼminot', icon: Building2 },
  tashqi: { title: 'Tashqi taʼminot', icon: Globe },
};

export default function TaminotPage() {
  const { scope = '' } = useParams();
  const valid = scope === 'ichki' || scope === 'tashqi';

  const qc = useQueryClient();
  const { can } = usePermissions();
  // Ruxsat scope bo'yicha alohida: supply_ichki:* yoki supply_tashqi:*
  const canWrite = can(`supply_${scope}:write`);
  const canDelete = can(`supply_${scope}:delete`);

  const [tab, setTab] = useState<'products' | 'reports'>('products');
  const [search, setSearch] = useState('');
  const [onlyDebt, setOnlyDebt] = useState(false);

  // Modal holatlari
  const [editProduct, setEditProduct] = useState<TaminotProduct | null | undefined>(undefined);
  const [action, setAction] = useState<{ product: TaminotProduct; kind: 'purchase' | 'payment' } | null>(null);
  const [detail, setDetail] = useState<TaminotProduct | null>(null);
  const [delProduct, setDelProduct] = useState<TaminotProduct | null>(null);
  const [deleting, setDeleting] = useState(false);

  // Hisobotlar filtri + kunlik pagination (har sahifa — bir kun)
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [repPage, setRepPage] = useState(1);
  const [delTx, setDelTx] = useState<TxLog | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['taminot-summary', scope],
    queryFn: () => api.get('/taminot/summary', { params: { scope } }).then((r) => r.data),
    enabled: valid,
  });
  const productsQ = useQuery<TaminotProduct[]>({
    queryKey: ['taminot-products', scope, search, onlyDebt],
    queryFn: () => api.get('/taminot/products', {
      params: { scope, search: search.trim() || undefined, with_debt: onlyDebt || undefined },
    }).then((r) => r.data),
    enabled: valid,
  });
  const logQ = useQuery<TxLog[]>({
    queryKey: ['taminot-log', scope, dateFrom, dateTo],
    queryFn: () => api.get('/taminot/transactions', {
      params: { scope, date_from: dateFrom || undefined, date_to: dateTo || undefined },
    }).then((r) => r.data),
    enabled: valid && tab === 'reports',
  });

  const products = productsQ.data ?? [];
  const s = summaryQ.data;

  // Ochiq tarix modalini yangilangan ma'lumot bilan sinxronlash
  useEffect(() => {
    if (!detail) return;
    const fresh = products.find((p) => p.id === detail.id);
    if (fresh && fresh !== detail) setDetail(fresh);
  }, [products]); // eslint-disable-line react-hooks/exhaustive-deps

  const refetchAll = () => {
    productsQ.refetch();
    summaryQ.refetch();
    qc.invalidateQueries({ queryKey: ['taminot-tx'] });
    qc.invalidateQueries({ queryKey: ['taminot-log', scope] });
  };

  async function confirmDeleteProduct() {
    if (!delProduct) return;
    setDeleting(true);
    try {
      await api.delete(`/taminot/products/${delProduct.id}`);
      toast.success("O'chirildi");
      setDelProduct(null);
      refetchAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  async function confirmDeleteTx() {
    if (!delTx) return;
    setDeleting(true);
    try {
      await api.delete(`/taminot/transactions/${delTx.id}`);
      toast.success("O'chirildi");
      setDelTx(null);
      logQ.refetch();
      refetchAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  const log = logQ.data ?? [];

  // Kunlik pagination: jurnal sana bo'yicha kamayuvchi (eng yangi kun birinchi)
  const dayKeys = useMemo(() => {
    const seen = new Set<string>();
    const days: string[] = [];
    for (const t of log) {
      const day = t.created_at.slice(0, 10);
      if (!seen.has(day)) { seen.add(day); days.push(day); }
    }
    return days;
  }, [log]);
  const totalDays = dayKeys.length;
  const curDay = totalDays > 0 ? dayKeys[Math.min(repPage, totalDays) - 1] : null;
  const dayRows = useMemo(
    () => log.filter((t) => t.created_at.slice(0, 10) === curDay),
    [log, curDay],
  );
  const dayTotals = useMemo(() => {
    // Valyutalar aralashmasligi uchun kun ichidagi ustun valyuta tanlanadi
    const count = new Map<string, number>();
    for (const t of dayRows) count.set(t.currency, (count.get(t.currency) ?? 0) + 1);
    const currency = [...count.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'UZS';
    let purchased = 0, paid = 0;
    for (const t of dayRows) {
      if (t.currency !== currency) continue;
      if (t.kind === 'purchase') purchased += t.amount; else paid += t.amount;
    }
    return { currency, purchased, paid, mixed: count.size > 1 };
  }, [dayRows]);
  // Filtr/scope o'zgarsa — eng yangi kunga qaytamiz
  useEffect(() => { setRepPage(1); }, [dateFrom, dateTo, scope]);

  if (!valid) return <Navigate to="/supply/ichki" replace />;
  const meta = SCOPE_META[scope];
  const Icon = meta.icon;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-button bg-primary/10 text-primary flex items-center justify-center">
            <Icon size={20} />
          </div>
          <div>
            <h1 className="text-2xl font-bold">{meta.title}</h1>
            <p className="text-sm text-ink-soft">Qarzga olib kelinadigan mahsulotlar va to'lovlar</p>
          </div>
        </div>
        {canWrite && (
          <button className="btn-primary" onClick={() => setEditProduct(null)}>
            <Plus size={16} /> Yangi mahsulot
          </button>
        )}
      </div>

      {/* KPI kartalari — har valyuta uchun: olib kelingan, to'langan, qarz qoldi */}
      <div className="space-y-3">
        {(s?.by_currency?.length ? s.by_currency : [{ currency: 'UZS', total_purchased: 0, total_paid: 0, total_balance: 0, with_debt_count: 0 }]).map((c) => (
          <div key={c.currency}>
            {(s?.by_currency?.length ?? 0) > 1 && (
              <div className="text-xs font-medium text-ink-soft mb-1.5">
                {CURRENCY_LABEL[c.currency] ?? c.currency}
              </div>
            )}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <KpiCard tone="primary" label="Olib kelingan"
                value={formatMoney(c.total_purchased, c.currency)} icon={<PackagePlus size={18} />} />
              <KpiCard tone="success" label="To'langan"
                value={formatMoney(c.total_paid, c.currency)} icon={<Wallet size={18} />} />
              <KpiCard tone="danger" label="Qarz qoldiq"
                value={formatMoney(c.total_balance, c.currency)} icon={<Coins size={18} />} />
            </div>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex gap-1.5">
          {([['products', 'Mahsulotlar'], ['reports', 'Hisobotlar']] as const).map(([key, label]) => (
            <button key={key} onClick={() => setTab(key)}
              className={cn('px-3 py-1.5 rounded-button text-sm font-medium transition',
                tab === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
              {label}
            </button>
          ))}
        </div>
        {tab === 'products' && (
          <div className="flex items-center gap-2">
            <label className="flex items-center gap-1.5 text-sm text-ink-soft cursor-pointer select-none">
              <input type="checkbox" checked={onlyDebt} onChange={(e) => setOnlyDebt(e.target.checked)} />
              Faqat qarzi borlar
            </label>
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input className="input pl-9 w-56" placeholder="Qidirish..."
                     value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
          </div>
        )}
        {tab === 'reports' && (
          <div className="flex items-center gap-2 text-sm">
            <input type="date" className="input" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} />
            <span className="text-ink-soft">—</span>
            <input type="date" className="input" value={dateTo} onChange={(e) => setDateTo(e.target.value)} />
          </div>
        )}
      </div>

      {/* ===================== MAHSULOTLAR ===================== */}
      {tab === 'products' ? (
        <Card>
          {productsQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : products.length === 0 ? (
            <EmptyState title="Hali mahsulot qo'shilmagan"
              description={canWrite ? '«Yangi mahsulot» tugmasi orqali birinchisini qo\'shing' : 'Hozircha bo\'sh'} />
          ) : (
            <div className="divide-y divide-black/5">
              {products.map((p) => (
                <div key={p.id}
                     className="flex items-center gap-3 py-3 hover:bg-black/[0.02] -mx-2 px-2 rounded-button transition cursor-pointer"
                     onClick={() => setDetail(p)}>
                  <div className="min-w-0 flex-1">
                    <div className="font-medium truncate">
                      {p.name}
                      <span className="text-ink-soft font-normal"> · {UNIT_LABEL[p.unit] ?? p.unit}</span>
                    </div>
                    <div className="text-xs text-ink-soft truncate">
                      {p.supplier ? `${p.supplier} · ` : ''}
                      {p.last_purchase_at ? `oxirgi: ${formatDateTime(p.last_purchase_at)}` : 'harakat yo\'q'}
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <div className={cn('font-bold', p.balance > 0 ? 'text-danger' : 'text-success')}>
                      {formatMoney(p.balance, p.currency)}
                    </div>
                    <div className="text-[11px] text-ink-soft">qarz qoldiq</div>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0" onClick={(e) => e.stopPropagation()}>
                    {canWrite && (
                      <button onClick={() => setAction({ product: p, kind: 'purchase' })}
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-primary/10 text-primary hover:bg-primary/20 transition">
                        <PackagePlus size={14} /> Olib kelish
                      </button>
                    )}
                    {canWrite && (
                      <button onClick={() => setAction({ product: p, kind: 'payment' })}
                              disabled={p.balance <= 0}
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-success/10 text-success hover:bg-success/20 transition disabled:opacity-40">
                        <Wallet size={14} /> To'lash
                      </button>
                    )}
                    {canWrite && (
                      <button onClick={() => setEditProduct(p)}
                              className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                        <Pencil size={15} />
                      </button>
                    )}
                    {canDelete && (
                      <button onClick={() => setDelProduct(p)}
                              className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger">
                        <Trash2 size={15} />
                      </button>
                    )}
                    <ChevronRight size={16} className="text-ink-soft" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      ) : (
        /* ===================== HISOBOTLAR ===================== */
        <div className="space-y-4">
          {!logQ.isLoading && log.length > 0 && <TaminotReportCharts log={log} />}
          <Card>
          {logQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : log.length === 0 ? (
            <EmptyState title="Harakatlar yo'q" description="Tanlangan davrda kirim yoki to'lov topilmadi" />
          ) : (
            <>
              {/* Kun sarlavhasi + shu kun yig'indisi */}
              <div className="flex items-center justify-between flex-wrap gap-2 mb-3">
                <div className="flex items-center gap-2 font-semibold">
                  <CalendarDays size={16} className="text-primary" />
                  {curDay ? formatDate(curDay) : '—'}
                  <span className="text-xs font-normal text-ink-soft">({dayRows.length} ta harakat)</span>
                </div>
                <div className="flex items-center gap-3 text-sm">
                  <span className="text-ink-soft">Kirim: <span className="font-semibold text-primary">{formatMoney(dayTotals.purchased, dayTotals.currency)}</span></span>
                  <span className="text-ink-soft">To'lov: <span className="font-semibold text-success">{formatMoney(dayTotals.paid, dayTotals.currency)}</span></span>
                </div>
              </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Vaqt</th>
                    <th className="py-2 pr-3">Mahsulot</th>
                    <th className="py-2 pr-3">Turi</th>
                    <th className="py-2 pr-3 text-right">Miqdor × narx</th>
                    <th className="py-2 pr-3 text-right">Summa</th>
                    {canDelete && <th className="py-2 pl-3 w-10"></th>}
                  </tr>
                </thead>
                <tbody>
                  {dayRows.map((tx) => {
                    const purchase = tx.kind === 'purchase';
                    return (
                      <tr key={tx.id} className="border-b border-black/5 hover:bg-black/[0.02]">
                        <td className="py-2.5 pr-3 whitespace-nowrap">{formatDateTime(tx.created_at)}</td>
                        <td className="py-2.5 pr-3 font-medium">
                          {tx.product_name}
                          {tx.supplier ? <span className="text-ink-soft font-normal"> · {tx.supplier}</span> : ''}
                          {tx.note ? <div className="text-xs text-ink-soft font-normal">{tx.note}</div> : null}
                        </td>
                        <td className="py-2.5 pr-3">
                          <span className={cn('badge', purchase ? 'bg-primary/10 text-primary' : 'bg-success/10 text-success')}>
                            {purchase ? 'Olib kelish' : "To'lov"}
                          </span>
                        </td>
                        <td className="py-2.5 pr-3 text-right text-ink-soft">
                          {purchase ? `${tx.qty} × ${formatMoney(tx.unit_price, tx.currency)}` : '—'}
                        </td>
                        <td className={cn('py-2.5 pr-3 text-right font-semibold', purchase ? 'text-danger' : 'text-success')}>
                          {purchase ? '+' : '−'}{formatMoney(tx.amount, tx.currency)}
                        </td>
                        {canDelete && (
                          <td className="py-2.5 pl-3">
                            <button onClick={() => setDelTx(tx)}
                                    className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger">
                              <Trash2 size={15} />
                            </button>
                          </td>
                        )}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Kunlik pagination — har sahifa bir kun */}
            {totalDays > 1 && (
              <div className="flex items-center justify-between mt-4 text-sm">
                <span className="text-ink-soft">{dayRows.length} ta harakat</span>
                <div className="flex items-center gap-2">
                  <button onClick={() => setRepPage((p) => Math.max(1, p - 1))} disabled={repPage <= 1}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-40 disabled:cursor-not-allowed">
                    <ChevronLeft size={15} /> Yangiroq
                  </button>
                  <span className="text-ink-soft whitespace-nowrap">{repPage} / {totalDays}-kun</span>
                  <button onClick={() => setRepPage((p) => Math.min(totalDays, p + 1))} disabled={repPage >= totalDays}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-40 disabled:cursor-not-allowed">
                    Eskiroq <ChevronRight size={15} />
                  </button>
                </div>
              </div>
            )}
            </>
          )}
          </Card>
        </div>
      )}

      {/* ===== Modallar ===== */}
      {editProduct !== undefined && (
        <TaminotProductModal scope={scope} product={editProduct}
          onClose={() => setEditProduct(undefined)} onSaved={refetchAll} />
      )}
      {action && (
        <TaminotActionModal product={action.product} kind={action.kind}
          onClose={() => setAction(null)} onSaved={refetchAll} />
      )}
      {detail && (
        <TaminotTransactionsModal product={detail}
          onClose={() => setDetail(null)} onChanged={refetchAll} />
      )}
      <ConfirmModal
        open={!!delProduct}
        title={delProduct?.name ?? ''}
        message="Ushbu mahsulot va uning barcha harakatlari o'chiriladi. Davom etamizmi?"
        confirmText="O'chirish"
        loading={deleting}
        onConfirm={confirmDeleteProduct}
        onCancel={() => setDelProduct(null)}
      />
      <ConfirmModal
        open={!!delTx}
        title="Harakatni o'chirish"
        message="Ushbu kirim/to'lov yozuvini o'chirasizmi?"
        confirmText="O'chirish"
        loading={deleting}
        onConfirm={confirmDeleteTx}
        onCancel={() => setDelTx(null)}
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
