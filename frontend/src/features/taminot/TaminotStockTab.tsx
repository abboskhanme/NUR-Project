import { useMemo } from 'react';
import {
  Boxes, AlertTriangle, PackageX, PackageMinus, ClipboardCheck, PackagePlus, Search,
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
      <div className="flex items-center justify-between flex-wrap gap-3">
        <label className="flex items-center gap-1.5 text-sm text-ink-soft cursor-pointer select-none">
          <input type="checkbox" checked={lowOnly} onChange={(e) => onLowOnly(e.target.checked)} />
          Faqat kam qolganlar
        </label>
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-56" placeholder="Qidirish..."
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
          <div className="overflow-x-auto">
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
                      <td className={cn('py-2.5 pr-3 text-right whitespace-nowrap font-bold', m.value)}>
                        {formatQty(p.stock, unit)}
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
                          <div className="flex items-center gap-1.5 justify-end">
                            <button onClick={() => onAction(p, 'purchase')} title="Olib kelish"
                                    className="p-1.5 rounded-button bg-primary/10 text-primary hover:bg-primary/20 transition">
                              <PackagePlus size={15} />
                            </button>
                            <button onClick={() => onAction(p, 'consume')} title="Sarflash"
                                    disabled={p.stock <= 0}
                                    className="p-1.5 rounded-button bg-warning/10 text-warning hover:bg-warning/20 transition disabled:opacity-40">
                              <PackageMinus size={15} />
                            </button>
                            <button onClick={() => onAction(p, 'stock')} title="Qoldiqni to'g'rilash"
                                    className="p-1.5 rounded-button bg-black/5 text-ink-soft hover:bg-black/10 hover:text-ink transition">
                              <ClipboardCheck size={15} />
                            </button>
                          </div>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
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

const TILE_TONES = {
  primary: 'border-primary/20 bg-primary/5 text-primary',
  success: 'border-success/25 bg-success/10 text-success',
  danger: 'border-danger/30 bg-danger/10 text-danger',
  muted: 'border-black/10 bg-black/[0.03] text-ink-soft',
} as const;

function StockTile({ tone, icon, label, value }: {
  tone: keyof typeof TILE_TONES;
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className={`rounded-card border p-3 ${TILE_TONES[tone]}`}>
      <div className="flex items-center gap-1.5 text-xs font-medium opacity-90">
        {icon} {label}
      </div>
      <div className="text-lg font-bold mt-1.5 truncate">{value}</div>
    </div>
  );
}
