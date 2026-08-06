import { useMemo } from 'react';
import {
  Boxes, AlertTriangle, PackageX, ClipboardCheck, PackagePlus, Search, Plus, Minus,
} from 'lucide-react';

import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatMoney, formatQty, formatDateTime } from '@/lib/format';
import { cn } from '@/lib/cn';
import type { TaminotProduct, StockStatus } from '@/features/taminot/TaminotProductModal';
import type { ActionKind } from '@/features/taminot/TaminotActionModal';

const UNIT_LABEL: Record<string, string> = { dona: 'dona', kg: 'kg', metr: 'metr', list: 'list' };
const CURRENCY_LABEL: Record<string, string> = { UZS: "so'm", USD: 'dollar' };

/** Har bir holat uchun ko'rinish: qizil — tugagan/kam qolgan. */
export const STOCK_META: Record<StockStatus, {
  label: string; badge: string; row: string; value: string;
}> = {
  out: {
    label: 'Tugadi',
    badge: 'bg-danger text-white',
    row: 'bg-danger/[0.07] hover:bg-danger/10',
    value: 'text-danger',
  },
  low: {
    label: 'Kam qoldi',
    badge: 'bg-danger/15 text-danger',
    row: 'bg-danger/[0.04] hover:bg-danger/[0.07]',
    value: 'text-danger',
  },
  ok: {
    label: 'Yetarli',
    badge: 'bg-success/15 text-success',
    row: 'hover:bg-black/[0.02]',
    value: 'text-ink',
  },
  none: {
    label: 'Harakat yo‘q',
    badge: 'bg-black/5 text-ink-soft',
    row: 'hover:bg-black/[0.02]',
    value: 'text-ink-soft',
  },
};

/**
 * "Ombor qoldiq" tabi — olib kelinadigan mahsulotlarning ombordagi aniq qoldig'i.
 * Qoldiq = olib kelingan − sarflangan + to'g'rilashlar (backendda hisoblanadi).
 * Kam qolgan va tugagan mahsulotlar tepada, qizil bilan ajratiladi.
 */
export default function TaminotStockTab({
  products, stats, loading, canWrite, search, onSearch, lowOnly, onLowOnly, onAction, onOpenDetail,
}: {
  products: TaminotProduct[];
  /** Umumiy hisob (filtrga bog'liq emas) — kartalar doim to'liq holatni ko'rsatadi */
  stats: {
    low: number;
    out: number;
    ok: number;
    stockValue: Array<{ currency: string; value: number }>;
  };
  loading: boolean;
  canWrite: boolean;
  search: string;
  onSearch: (v: string) => void;
  lowOnly: boolean;
  onLowOnly: (v: boolean) => void;
  onAction: (product: TaminotProduct, kind: ActionKind) => void;
  onOpenDetail: (product: TaminotProduct) => void;
}) {
  // Diqqat talab qiladiganlar tepada: tugagan → kam qoldi → yetarli → harakatsiz
  const rows = useMemo(() => {
    const rank: Record<StockStatus, number> = { out: 0, low: 1, ok: 2, none: 3 };
    return [...products].sort(
      (a, b) => rank[a.stock_status] - rank[b.stock_status] ||
        a.name.localeCompare(b.name, 'uz'),
    );
  }, [products]);

  return (
    <div className="space-y-4">
      {/* Ombor holati bo'yicha tez ko'rsatkichlar */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StockTile
          tone={stats.out > 0 ? 'danger' : 'muted'}
          icon={<PackageX size={16} />}
          label="Tugagan"
          value={`${stats.out} ta`}
        />
        <StockTile
          tone={stats.low > 0 ? 'danger' : 'muted'}
          icon={<AlertTriangle size={16} />}
          label="Kam qolgan"
          value={`${stats.low} ta`}
        />
        <StockTile
          tone="success"
          icon={<Boxes size={16} />}
          label="Yetarli"
          value={`${stats.ok} ta`}
        />
        <StockTile
          tone="primary"
          // Valyutalar yonma-yon yozilgani uchun telefonda to'liq kenglik
          className="col-span-2 lg:col-span-1"
          icon={<PackagePlus size={16} />}
          label="Qoldiq qiymati"
          value={
            stats.stockValue.length
              ? stats.stockValue.map((s) => formatMoney(s.value, s.currency)).join(' + ')
              : formatMoney(0, 'UZS')
          }
        />
      </div>

      {/* Filtrlar */}
      <div className="flex items-center justify-between gap-3">
        <label className="flex items-center gap-1.5 text-xs sm:text-sm text-ink-soft cursor-pointer select-none shrink-0">
          <input type="checkbox" checked={lowOnly} onChange={(e) => onLowOnly(e.target.checked)} />
          Faqat kam qolganlar
        </label>
        <div className="relative flex-1 sm:flex-none">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-full sm:w-56" placeholder="Qidirish..."
                 value={search} onChange={(e) => onSearch(e.target.value)} />
        </div>
      </div>

      <Card>
        {loading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : rows.length === 0 ? (
          <EmptyState
            title={lowOnly ? 'Kam qolgan mahsulot yo‘q' : 'Mahsulot yo‘q'}
            description={lowOnly ? 'Barcha mahsulotlar yetarli miqdorda' : 'Avval mahsulot qo‘shing'}
          />
        ) : (
          <>
          {/* Katta ekran — to'liq jadval */}
          <div className="hidden md:block overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Mahsulot</th>
                  <th className="py-2 pr-3 text-right">Olib kelingan</th>
                  <th className="py-2 pr-3 text-right">Sarflangan</th>
                  <th className="py-2 pr-3 text-right">Qoldiq</th>
                  <th className="py-2 pr-3 text-right">Chegara</th>
                  <th className="py-2 pr-3 text-right">Qiymati</th>
                  <th className="py-2 pr-3">Holat</th>
                  {canWrite && <th className="py-2 pl-3 w-[1%]"></th>}
                </tr>
              </thead>
              <tbody>
                {rows.map((p) => {
                  const m = STOCK_META[p.stock_status];
                  const unit = UNIT_LABEL[p.unit] ?? p.unit;
                  const attention = p.stock_status === 'low' || p.stock_status === 'out';
                  return (
                    <tr key={p.id}
                        className={cn('border-b border-black/5 transition cursor-pointer', m.row)}
                        onClick={() => onOpenDetail(p)}>
                      <td className="py-2.5 pr-3">
                        <div className="font-medium flex items-center gap-1.5">
                          {attention && <AlertTriangle size={13} className="text-danger shrink-0" />}
                          <span className="truncate">{p.name}</span>
                        </div>
                        <div className="text-xs text-ink-soft truncate">
                          {p.supplier ? `${p.supplier} · ` : ''}
                          {p.last_purchase_at
                            ? `oxirgi kirim: ${formatDateTime(p.last_purchase_at)}`
                            : 'kirim yo‘q'}
                        </div>
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap text-ink-soft">
                        {formatQty(p.in_qty)}
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap text-ink-soft">
                        {formatQty(p.out_qty)}
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap"
                          onClick={(e) => e.stopPropagation()}>
                        <StockStepper product={p} unit={unit} valueCls={m.value}
                                      canWrite={canWrite} onAction={onAction} />
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap text-ink-soft">
                        {p.min_qty > 0 ? formatQty(p.min_qty) : '—'}
                      </td>
                      <td className="py-2.5 pr-3 text-right whitespace-nowrap">
                        {formatMoney(p.stock_value, p.currency)}
                        <div className="text-[11px] text-ink-soft">
                          {formatMoney(p.unit_price, p.currency)}/{unit}
                        </div>
                      </td>
                      <td className="py-2.5 pr-3">
                        <span className={cn('badge whitespace-nowrap', m.badge)}>{m.label}</span>
                      </td>
                      {canWrite && (
                        <td className="py-2.5 pl-3" onClick={(e) => e.stopPropagation()}>
                          <StockActions product={p} onAction={onAction} />
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Telefon — jadval o'rniga kartalar */}
          <div className="md:hidden divide-y divide-black/5">
            {rows.map((p) => {
              const m = STOCK_META[p.stock_status];
              const unit = UNIT_LABEL[p.unit] ?? p.unit;
              const attention = p.stock_status === 'low' || p.stock_status === 'out';
              return (
                <div key={p.id}
                     className={cn('py-3 -mx-2 px-2 rounded-button transition cursor-pointer', m.row)}
                     onClick={() => onOpenDetail(p)}>
                  <div className="flex items-start gap-3">
                    <div className="min-w-0 flex-1">
                      <div className="font-medium flex items-center gap-1.5">
                        {attention && <AlertTriangle size={13} className="text-danger shrink-0" />}
                        <span className="truncate">{p.name}</span>
                      </div>
                      <div className="text-xs text-ink-soft truncate">
                        {p.supplier ? `${p.supplier} · ` : ''}
                        {formatMoney(p.stock_value, p.currency)}
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <div className="leading-tight" onClick={(e) => e.stopPropagation()}>
                        <StockStepper product={p} unit={unit} valueCls={m.value}
                                      canWrite={canWrite} onAction={onAction} />
                      </div>
                      <span className={cn('badge mt-0.5 !px-1.5 !py-0 text-[10px] whitespace-nowrap', m.badge)}>
                        {m.label}
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center justify-between gap-2 mt-2">
                    <div className="text-[11px] text-ink-soft truncate">
                      kirim {formatQty(p.in_qty)} · sarf {formatQty(p.out_qty)}
                      {p.min_qty > 0 ? ` · min ${formatQty(p.min_qty)}` : ''}
                    </div>
                    {canWrite && (
                      <div className="shrink-0" onClick={(e) => e.stopPropagation()}>
                        <StockActions product={p} onAction={onAction} />
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
          </>
        )}
        {!loading && rows.length > 0 && (
          <p className="text-[11px] text-ink-soft mt-3">
            Qoldiq = olib kelingan − sarflangan ± to‘g‘rilashlar. Valyutalar aralashtirilmaydi
            ({[...new Set(rows.map((r) => CURRENCY_LABEL[r.currency] ?? r.currency))].join(', ')}).
          </p>
        )}
      </Card>
    </div>
  );
}

/**
 * Qoldiq + ikki tomonidagi amal tugmalari:
 *   [−] qoldiq [+]   — chapda sarflash, o'ngda olib kelish.
 * Tugmalar qoldiq yonida turgani uchun qaysi mahsulotga tegishli ekani aniq
 * ko'rinadi (ilgari ular alohida ustunda edi).
 */
function StockStepper({ product, unit, valueCls, onAction, canWrite }: {
  product: TaminotProduct;
  unit: string;
  valueCls: string;
  canWrite: boolean;
  onAction: (product: TaminotProduct, kind: ActionKind) => void;
}) {
  const btn = 'w-7 h-7 md:w-6 md:h-6 shrink-0 rounded-button flex items-center justify-center transition';
  return (
    <div className="inline-flex items-center gap-1.5">
      {canWrite && (
        <button onClick={(e) => { e.stopPropagation(); onAction(product, 'consume'); }}
                title="Sarflash" aria-label="Sarflash"
                disabled={product.stock <= 0}
                className={cn(btn, 'bg-warning/10 text-warning hover:bg-warning/20 disabled:opacity-40')}>
          <Minus size={14} />
        </button>
      )}
      <span className={cn('font-bold tabular-nums whitespace-nowrap min-w-[3.5rem] text-center', valueCls)}>
        {formatQty(product.stock, unit)}
      </span>
      {canWrite && (
        <button onClick={(e) => { e.stopPropagation(); onAction(product, 'purchase'); }}
                title="Olib kelish" aria-label="Olib kelish"
                className={cn(btn, 'bg-primary/10 text-primary hover:bg-primary/20')}>
          <Plus size={14} />
        </button>
      )}
    </div>
  );
}

/** Qolgan amallar (qoldiqni to'g'rilash) — alohida ustunda. */
function StockActions({ product, onAction }: {
  product: TaminotProduct;
  onAction: (product: TaminotProduct, kind: ActionKind) => void;
}) {
  return (
    <div className="flex items-center gap-1.5 justify-end">
      <button onClick={() => onAction(product, 'stock')} title="Qoldiqni to'g'rilash"
              className="p-2 md:p-1.5 rounded-button bg-black/5 text-ink-soft hover:bg-black/10 hover:text-ink transition">
        <ClipboardCheck size={15} />
      </button>
    </div>
  );
}

const TILE_TONES = {
  primary: 'border-primary/20 bg-primary/5 text-primary',
  success: 'border-success/25 bg-success/10 text-success',
  danger: 'border-danger/30 bg-danger/10 text-danger',
  muted: 'border-black/10 bg-black/[0.03] text-ink-soft',
} as const;

function StockTile({ tone, icon, label, value, className }: {
  tone: keyof typeof TILE_TONES;
  icon: React.ReactNode;
  label: string;
  value: string;
  className?: string;
}) {
  return (
    <div className={cn('rounded-card border p-2.5 sm:p-3', TILE_TONES[tone], className)}>
      <div className="flex items-center gap-1.5 text-[11px] sm:text-xs font-medium opacity-90">
        {icon} <span className="truncate">{label}</span>
      </div>
      <div className="text-base sm:text-lg font-bold mt-1 sm:mt-1.5 truncate">{value}</div>
    </div>
  );
}
