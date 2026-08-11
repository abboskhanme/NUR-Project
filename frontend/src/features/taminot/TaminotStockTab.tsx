import { useMemo, useState } from 'react';
import { Minus, AlertTriangle, PackageMinus } from 'lucide-react';

import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatQty } from '@/lib/format';
import { cn } from '@/lib/cn';
import { STOCK_META } from '@/features/taminot/stockMeta';
import { UNIT_LABEL, type StockStatus, type TaminotProduct } from '@/features/taminot/types';
import type { ActionKind } from '@/features/taminot/TaminotActionModal';

/** Holat filtri: barchasi yoki bitta aniq holat. */
type Filter = 'all' | StockStatus;

const FILTERS: { key: Filter; label: string }[] = [
  { key: 'all', label: 'Barchasi' },
  { key: 'out', label: 'Tugagan' },
  { key: 'low', label: 'Kam qoldi' },
  { key: 'ok', label: 'Yetarli' },
];

/**
 * OMBOR — shu ta'minot bo'limi orqali kelgan mahsulotlarning qoldig'i.
 *
 * DIQQAT: bu ASOSIY «Ombor» moduliga (inventory / tayyor mahsulot ombori)
 * MUTLAQO ALOQADOR EMAS. Bu yerda faqat ta'minot orqali olib kelinadigan
 * materiallar hisoblanadi va ular hech qachon asosiy ombor bilan
 * aralashtirilmaydi. Ichki va tashqi ta'minot ham o'zaro alohida (`scope`).
 *
 * Ataylab sodda: mahsulot nomi, qoldiq va sarflash tugmasi. Narx, yetkazib
 * beruvchi va qarz — «Yetkazib beruvchilar» hamda «Mahsulotlar» tabida.
 */
export default function TaminotStockTab({
  products, loading, canWrite, onAction, onOpenProduct,
}: {
  products: TaminotProduct[];
  loading: boolean;
  canWrite: boolean;
  onAction: (p: TaminotProduct, kind: ActionKind) => void;
  onOpenProduct: (p: TaminotProduct) => void;
}) {
  const [filter, setFilter] = useState<Filter>('all');

  const counts = useMemo(() => {
    const c: Record<StockStatus, number> = { out: 0, low: 0, ok: 0, none: 0 };
    for (const p of products) c[p.stock_status] += 1;
    return c;
  }, [products]);

  const rows = useMemo(() => {
    // "Harakat yo'q" mahsulotlar ham qoldig'i 0 — «Tugagan» bilan birga chiqadi
    const match = (p: TaminotProduct) =>
      filter === 'all' ? true
        : filter === 'out' ? (p.stock_status === 'out' || p.stock_status === 'none')
        : p.stock_status === filter;
    // Diqqat talab qiladiganlar tepada: tugagan → kam qoldi → yetarli
    const rank: Record<StockStatus, number> = { out: 0, none: 0, low: 1, ok: 2 };
    return products.filter(match).sort(
      (a, b) => rank[a.stock_status] - rank[b.stock_status] || a.name.localeCompare(b.name),
    );
  }, [products, filter]);

  if (loading) {
    return (
      <Card>
        <div className="space-y-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-3">
      {/* Holat bo'yicha tez filtr */}
      <div className="flex gap-1.5 flex-wrap">
        {FILTERS.map((f) => {
          const n = f.key === 'all' ? products.length
            : f.key === 'out' ? counts.out + counts.none
            : counts[f.key as StockStatus];
          const active = filter === f.key;
          return (
            <button key={f.key} onClick={() => setFilter(f.key)} disabled={n === 0 && !active}
              className={cn(
                'px-2.5 py-1.5 rounded-button text-xs sm:text-sm font-medium transition inline-flex items-center gap-1.5 disabled:opacity-40',
                active ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
              {f.label}
              <span className={cn('px-1.5 py-0.5 rounded-full text-[10px] font-bold',
                active ? 'bg-white/20'
                  : f.key === 'out' || f.key === 'low' ? 'bg-danger/15 text-danger' : 'bg-black/10')}>
                {n}
              </span>
            </button>
          );
        })}
      </div>

      <Card>
        {rows.length === 0 ? (
          <EmptyState
            title={products.length === 0 ? "Omborda mahsulot yo'q" : "Bu holatda mahsulot yo'q"}
            description={products.length === 0
              ? "Mahsulotlar «Yetkazib beruvchilar» tabi orqali qo'shiladi"
              : "Boshqa holatni tanlab ko'ring"} />
        ) : (
          <div className="divide-y divide-black/5">
            {rows.map((p) => {
              const sm = STOCK_META[p.stock_status];
              const low = p.stock_status === 'low' || p.stock_status === 'out';
              const unit = UNIT_LABEL[p.unit] ?? p.unit;
              return (
                <div key={p.id}
                     className={cn(
                       'flex items-center gap-3 py-3 -mx-2 px-2 rounded-button transition cursor-pointer',
                       low ? 'bg-danger/[0.04] hover:bg-danger/[0.08]' : 'hover:bg-black/[0.02]')}
                     onClick={() => onOpenProduct(p)}>
                  {/* Nomi */}
                  <div className="min-w-0 flex-1 font-medium flex items-center gap-1.5">
                    {low && <AlertTriangle size={14} className="text-danger shrink-0" />}
                    <span className="truncate">{p.name}</span>
                  </div>

                  {/* Ombor qoldig'i */}
                  <div className={cn(
                    'shrink-0 w-[110px] sm:w-[130px] rounded-button border px-3 py-1.5 text-center',
                    low ? 'border-danger/25 bg-danger/10' : 'border-black/[0.07] bg-black/[0.03]')}>
                    <div className={cn('font-bold leading-tight', sm.value)}>
                      {formatQty(p.stock, unit)}
                    </div>
                    <div className={cn('text-[10px]',
                      low ? cn('font-semibold uppercase tracking-wide', sm.value) : 'text-ink-soft')}>
                      {low ? sm.label : 'ombor qoldiq'}
                    </div>
                  </div>

                  {/* Sarflash */}
                  {canWrite && (
                    <button onClick={(e) => { e.stopPropagation(); onAction(p, 'consume'); }}
                            disabled={p.stock <= 0} title="Sarflash (ombordan chiqim)"
                            className="shrink-0 inline-flex items-center gap-1.5 px-3 py-2 rounded-button text-sm font-medium bg-warning/10 text-warning hover:bg-warning/20 transition disabled:opacity-40">
                      <Minus size={15} /> <span className="hidden sm:inline">Sarflash</span>
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </Card>

      <p className="text-[11px] text-ink-soft flex items-start gap-1.5">
        <PackageMinus size={12} className="mt-0.5 shrink-0" />
        <span>
          Bu yerda faqat shu ta'minot bo'limi orqali kelgan mahsulotlar hisoblanadi —
          asosiy «Ombor» bo'limiga aloqasi yo'q. Sarflash faqat qoldiqni kamaytiradi,
          yetkazib beruvchining qarziga ta'sir qilmaydi.
        </span>
      </p>
    </div>
  );
}
