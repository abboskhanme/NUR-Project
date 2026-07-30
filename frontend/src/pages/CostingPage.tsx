import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Calculator, Search, TrendingUp, TrendingDown, Percent, AlertTriangle,
  ChevronRight, PackageSearch,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatMoney } from '@/lib/format';
import { cn } from '@/lib/cn';
import type { CostRow, CostingSummary } from '@/features/costing/types';
import { marginTone } from '@/features/costing/types';

/**
 * Tannarx bo'limi — asosiy mahsulotlar ro'yxati va ularning tannarxi/foydasi.
 *
 * Tannarx mahsulot tarkibidan (ichki ta'minot materiallari + qo'shimcha
 * xarajatlar + ustama) hisoblanadi. Material narxi ta'minotdan JONLI olinadi,
 * shuning uchun ta'minotda narx o'zgarsa bu jadval o'zi yangilanadi.
 */
export default function CostingPage() {
  const [type, setType] = useState<'main' | 'additional'>('main');
  const [search, setSearch] = useState('');
  const [onlyMissing, setOnlyMissing] = useState(false);

  const summaryQ = useQuery<CostingSummary>({
    queryKey: ['costing-summary', type],
    queryFn: () => api.get('/costing/summary', { params: { product_type: type } }).then((r) => r.data),
  });
  const rowsQ = useQuery<CostRow[]>({
    queryKey: ['costing-products', type, search, onlyMissing],
    queryFn: () => api.get('/costing/products', {
      params: {
        product_type: type,
        search: search.trim() || undefined,
        only_missing: onlyMissing || undefined,
      },
    }).then((r) => r.data),
  });

  const rows = rowsQ.data ?? [];
  const s = summaryQ.data;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-button bg-primary/10 text-primary flex items-center justify-center">
            <Calculator size={20} />
          </div>
          <div className="min-w-0">
            <h1 className="text-xl sm:text-2xl font-bold">Tannarx va foyda</h1>
            <p className="text-xs sm:text-sm text-ink-soft">
              Mahsulot tarkibiga (ichki materiallar) qarab tannarx va foyda hisobi
            </p>
          </div>
        </div>
      </div>

      {/* Kurs kiritilmagan bo'lsa — hisob to'liq bo'lmaydi */}
      {s && s.usd_rate <= 0 && (
        <div className="rounded-card border border-warning/30 bg-warning/10 px-4 py-3 flex items-center gap-3">
          <AlertTriangle size={18} className="text-warning shrink-0" />
          <div className="text-sm text-warning">
            USD kursi kiritilmagan — dollarda kiritilgan narxlar so'mga o'girilmaydi.
            Moliya bo'limida kursni kiriting.
          </div>
        </div>
      )}

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-2 sm:gap-3">
        <Kpi tone="primary" icon={<PackageSearch size={16} />} label="Kalkulyatsiya kiritilgan"
             value={s ? `${s.with_recipe} / ${s.product_count}` : '—'} />
        <Kpi tone={s?.without_recipe ? 'warning' : 'muted'} icon={<AlertTriangle size={16} />}
             label="Kiritilmagan" value={s ? `${s.without_recipe} ta` : '—'} />
        <Kpi tone="success" icon={<Percent size={16} />} label="O'rtacha marja"
             value={s?.avg_margin_percent != null ? `${s.avg_margin_percent}%` : '—'} />
        <Kpi tone={s?.loss_count ? 'danger' : 'muted'} icon={<TrendingDown size={16} />}
             label="Zarariga" value={s ? `${s.loss_count} ta` : '—'} />
      </div>

      {/* Eng foydali / eng kam foydali */}
      {s?.best_name && s?.worst_name && s.best_name !== s.worst_name && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div className="rounded-card border border-success/25 bg-success/[0.06] px-4 py-3 flex items-center gap-3">
            <TrendingUp size={18} className="text-success shrink-0" />
            <div className="min-w-0">
              <div className="text-xs text-ink-soft">Eng foydali</div>
              <div className="font-semibold truncate">{s.best_name}</div>
            </div>
            <div className="ml-auto font-bold text-success shrink-0">{s.best_margin_percent}%</div>
          </div>
          <div className="rounded-card border border-danger/25 bg-danger/[0.06] px-4 py-3 flex items-center gap-3">
            <TrendingDown size={18} className="text-danger shrink-0" />
            <div className="min-w-0">
              <div className="text-xs text-ink-soft">Eng kam foydali</div>
              <div className="font-semibold truncate">{s.worst_name}</div>
            </div>
            <div className="ml-auto font-bold text-danger shrink-0">{s.worst_margin_percent}%</div>
          </div>
        </div>
      )}

      {/* Filtrlar */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex gap-1.5">
          {([['main', 'Asosiy mahsulotlar'], ['additional', "Qo'shimcha"]] as const).map(([key, label]) => (
            <button key={key} onClick={() => setType(key)}
              className={cn('px-2.5 sm:px-3 py-1.5 rounded-button text-xs sm:text-sm font-medium transition',
                type === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
              {label}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <label className="flex items-center gap-1.5 text-xs sm:text-sm text-ink-soft cursor-pointer select-none shrink-0">
            <input type="checkbox" checked={onlyMissing} onChange={(e) => setOnlyMissing(e.target.checked)} />
            Faqat kiritilmaganlar
          </label>
          <div className="relative flex-1 sm:flex-none">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 w-full sm:w-56" placeholder="Qidirish..."
                   value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>
      </div>

      <Card>
        {rowsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : rows.length === 0 ? (
          <EmptyState
            title={onlyMissing ? 'Hammasiga kalkulyatsiya kiritilgan' : 'Mahsulot topilmadi'}
            description={onlyMissing
              ? 'Barcha mahsulotlar tannarxi hisoblangan'
              : 'Mahsulotlar bo\'limida mahsulot qo\'shilgach shu yerda paydo bo\'ladi'}
          />
        ) : (
          <>
            {/* Katta ekran — jadval */}
            <div className="hidden md:block overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Mahsulot</th>
                    <th className="py-2 pr-3 text-right">Tannarx</th>
                    <th className="py-2 pr-3 text-right">Sotish narxi</th>
                    <th className="py-2 pr-3 text-right">Foyda</th>
                    <th className="py-2 pr-3 text-right">Marja</th>
                    <th className="py-2 pr-3 text-right">Sotilgan</th>
                    <th className="py-2 pl-3 w-[1%]"></th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r) => (
                    <tr key={r.product_id} className="border-b border-black/5 hover:bg-black/[0.02]">
                      <td className="py-2.5 pr-3">
                        <Link to={`/costing/${r.product_id}`} className="font-medium hover:text-primary">
                          {r.display_name}
                        </Link>
                        <div className="text-xs text-ink-soft">
                          {r.has_recipe
                            ? `${r.item_count} ta tarkib satri`
                            : 'kalkulyatsiya kiritilmagan'}
                        </div>
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap font-medium">
                        {r.cost_uzs != null ? formatMoney(r.cost_uzs, 'UZS') : '—'}
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap text-ink-soft">
                        {r.price_uzs ? formatMoney(r.price_uzs, 'UZS') : '—'}
                      </td>
                      <td className={cn('py-2.5 pr-3 text-right whitespace-nowrap font-bold',
                        marginTone(r.margin_percent))}>
                        {r.profit_uzs != null ? formatMoney(r.profit_uzs, 'UZS') : '—'}
                      </td>
                      <td className={cn('py-2.5 pr-3 text-right whitespace-nowrap font-semibold',
                        marginTone(r.margin_percent))}>
                        {r.margin_percent != null ? `${r.margin_percent}%` : '—'}
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap text-ink-soft">
                        {r.sold_count > 0 ? `${r.sold_count} dona` : '—'}
                        {r.avg_sold_uzs != null && (
                          <div className="text-[11px]">
                            o'rt. {formatMoney(r.avg_sold_uzs, 'UZS')}
                          </div>
                        )}
                      </td>
                      <td className="py-2.5 pl-3 text-right">
                        <Link to={`/costing/${r.product_id}`}
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-primary/10 text-primary hover:bg-primary/20 transition whitespace-nowrap">
                          {r.has_recipe ? 'Ochish' : 'Kiritish'} <ChevronRight size={13} />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Telefon — kartalar */}
            <div className="md:hidden divide-y divide-black/5">
              {rows.map((r) => (
                <Link key={r.product_id} to={`/costing/${r.product_id}`}
                      className="block py-3 -mx-2 px-2 rounded-button hover:bg-black/[0.02] transition">
                  <div className="flex items-start gap-3">
                    <div className="min-w-0 flex-1">
                      <div className="font-medium truncate">{r.display_name}</div>
                      <div className="text-xs text-ink-soft">
                        {r.has_recipe ? `${r.item_count} ta tarkib satri` : 'kalkulyatsiya kiritilmagan'}
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <div className={cn('font-bold', marginTone(r.margin_percent))}>
                        {r.margin_percent != null ? `${r.margin_percent}%` : '—'}
                      </div>
                      <div className="text-[11px] text-ink-soft">marja</div>
                    </div>
                  </div>
                  <div className="grid grid-cols-3 gap-2 mt-2 text-[11px]">
                    <div>
                      <div className="text-ink-soft">Tannarx</div>
                      <div className="font-medium">
                        {r.cost_uzs != null ? formatMoney(r.cost_uzs, 'UZS') : '—'}
                      </div>
                    </div>
                    <div>
                      <div className="text-ink-soft">Sotish</div>
                      <div className="font-medium">
                        {r.price_uzs ? formatMoney(r.price_uzs, 'UZS') : '—'}
                      </div>
                    </div>
                    <div>
                      <div className="text-ink-soft">Foyda</div>
                      <div className={cn('font-medium', marginTone(r.margin_percent))}>
                        {r.profit_uzs != null ? formatMoney(r.profit_uzs, 'UZS') : '—'}
                      </div>
                    </div>
                  </div>
                </Link>
              ))}
            </div>
          </>
        )}
        {!rowsQ.isLoading && rows.length > 0 && (
          <p className="text-[11px] text-ink-soft mt-3">
            Tannarx = materiallar + qo'shimcha xarajatlar + ustama. Material narxlari ichki
            ta'minotdan jonli olinadi. «Sotilgan» — oxirgi 180 kundagi haqiqiy sotuvlar.
          </p>
        )}
      </Card>
    </div>
  );
}

const KPI_TONES = {
  primary: 'border-primary/20 bg-primary/5 text-primary',
  success: 'border-success/25 bg-success/10 text-success',
  warning: 'border-warning/30 bg-warning/10 text-warning',
  danger: 'border-danger/30 bg-danger/10 text-danger',
  muted: 'border-black/10 bg-black/[0.03] text-ink-soft',
} as const;

function Kpi({ tone, icon, label, value }: {
  tone: keyof typeof KPI_TONES;
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className={`rounded-card border p-2.5 sm:p-3 ${KPI_TONES[tone]}`}>
      <div className="flex items-center gap-1.5 text-[11px] sm:text-xs font-medium opacity-90">
        {icon} <span className="truncate">{label}</span>
      </div>
      <div className="text-base sm:text-lg font-bold mt-1 truncate">{value}</div>
    </div>
  );
}
