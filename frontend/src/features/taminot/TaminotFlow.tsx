import { useMemo, useState } from 'react';
import {
  Plus, Minus, Wallet, PackagePlus, ClipboardCheck, Pencil, Trash2,
  Building2, AlertTriangle, ChevronDown, ChevronRight, ListTree,
} from 'lucide-react';

import EmptyState from '@/components/ui/EmptyState';
import { formatMoney, formatQty } from '@/lib/format';
import { cn } from '@/lib/cn';
import { STOCK_META } from '@/features/taminot/stockMeta';
import { UNIT_LABEL, type TaminotProduct, type TaminotSupplier } from '@/features/taminot/types';
import type { ActionKind } from '@/features/taminot/TaminotActionModal';

/**
 * YETKAZIB BERUVCHI → MAHSULOT oqimi (flow).
 *
 * Har bir yetkazib beruvchi — tugun; undan pastga chiziq tushadi va shu
 * chiziqqa uning mahsulotlari ulanadi. Shu bilan «qaysi joydan nima olinadi»
 * bir qarashda ko'rinadi va ikkalasi ham SHU YERDA boshqariladi: joyga to'lov
 * va kirim, mahsulotga esa ombor amallari.
 *
 * Chiziqlar oddiy CSS bilan chiziladi (tashqi kutubxona yo'q): chapdagi
 * vertikal ustun + har qatorga tirsak (elbow) va tugun nuqtasi.
 */
export default function TaminotFlow({
  suppliers, products, canWrite, canDelete, hideEmpty = false,
  onOpenSupplier, onEditSupplier, onPay, onPurchase, onAddProduct,
  onProductAction, onEditProduct, onDeleteProduct, onOpenProduct,
}: {
  suppliers: TaminotSupplier[];
  products: TaminotProduct[];
  canWrite: boolean;
  canDelete: boolean;
  /** Qidiruv yoki filtr yoqilganda mahsuloti qolmagan tugunlar yashiriladi */
  hideEmpty?: boolean;
  onOpenSupplier: (s: TaminotSupplier) => void;
  onEditSupplier: (s: TaminotSupplier) => void;
  onPay: (s: TaminotSupplier) => void;
  onPurchase: (s: TaminotSupplier) => void;
  onAddProduct: (s: TaminotSupplier) => void;
  onProductAction: (p: TaminotProduct, kind: ActionKind) => void;
  onEditProduct: (p: TaminotProduct) => void;
  onDeleteProduct: (p: TaminotProduct) => void;
  onOpenProduct: (p: TaminotProduct) => void;
}) {
  // Yopilgan tugunlar (sukut bo'yicha hammasi ochiq)
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const toggle = (id: string) => setCollapsed((prev) => {
    const next = new Set(prev);
    next.has(id) ? next.delete(id) : next.add(id);
    return next;
  });

  // Mahsulotlarni o'z yetkazib beruvchisiga taqsimlash
  const bySupplier = useMemo(() => {
    const map = new Map<string, TaminotProduct[]>();
    for (const p of products) {
      const arr = map.get(p.supplier_id);
      if (arr) arr.push(p);
      else map.set(p.supplier_id, [p]);
    }
    return map;
  }, [products]);

  // Filtr yo'q paytda bo'sh yetkazib beruvchilar ham ko'rinadi — ularga shu
  // yerdan birinchi mahsulot qo'shiladi. Qidiruvda esa ular chalg'itadi.
  const rows = suppliers
    .map((s) => ({ supplier: s, items: bySupplier.get(s.id) ?? [] }))
    .filter((r) => !hideEmpty || r.items.length > 0);

  if (!rows.length) {
    return (
      <EmptyState
        title={hideEmpty ? 'Mos mahsulot topilmadi' : "Hali yetkazib beruvchi yo'q"}
        description={hideEmpty
          ? 'Qidiruv yoki filtrni o\'zgartirib ko\'ring'
          : 'Avval mahsulot olinadigan joyni qo\'shing — mahsulotlar shu joy ostiga ulanadi'} />
    );
  }

  return (
    <div className="space-y-5">
      {rows.map(({ supplier: sp, items }) => {
        const isOpen = !collapsed.has(sp.id);
        const debts = sp.totals.filter((t) => t.balance > 0);
        const attention = items.filter(
          (p) => p.stock_status === 'low' || p.stock_status === 'out',
        ).length;

        return (
          <div key={sp.id}>
            {/* ===== Tugun: yetkazib beruvchi ===== */}
            <div className="rounded-card border border-primary/20 bg-primary/[0.04] px-3 py-2.5">
              <div className="flex items-center gap-2 flex-wrap">
                <button onClick={() => toggle(sp.id)}
                        title={isOpen ? 'Yopish' : 'Ochish'}
                        className="w-7 h-7 shrink-0 rounded-button flex items-center justify-center text-ink-soft hover:bg-black/5">
                  {isOpen ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                </button>
                <div className="w-8 h-8 shrink-0 rounded-button bg-primary/15 text-primary flex items-center justify-center">
                  <Building2 size={16} />
                </div>
                <button onClick={() => onOpenSupplier(sp)}
                        className="min-w-0 text-left flex-1 group">
                  <div className="font-semibold truncate group-hover:text-primary transition">
                    {sp.name}
                  </div>
                  <div className="text-xs text-ink-soft truncate">
                    {items.length} ta mahsulot
                    {attention > 0 ? ` · ${attention} tasi kam qoldi` : ''}
                    {sp.phone ? ` · ${sp.phone}` : ''}
                  </div>
                </button>

                {/* Qarz — har valyuta alohida */}
                <div className="text-right shrink-0">
                  {debts.length > 0 ? debts.map((t) => (
                    <div key={t.currency} className="font-bold text-danger tabular-nums leading-tight">
                      {formatMoney(t.balance, t.currency)}
                    </div>
                  )) : (
                    <div className="font-semibold text-success text-sm">Qarz yo'q</div>
                  )}
                  <div className="text-[10px] text-ink-soft">qarz qoldiq</div>
                </div>

                {/* Joy darajasidagi amallar */}
                {canWrite && (
                  <div className="flex items-center gap-1 shrink-0 basis-full sm:basis-auto justify-end">
                    <button onClick={() => onPay(sp)} disabled={!debts.length} title="Qarz to'lash"
                            className="inline-flex items-center gap-1 px-2 py-1.5 rounded-button text-xs font-medium bg-success/10 text-success hover:bg-success/20 transition disabled:opacity-40">
                      <Wallet size={14} /> <span className="hidden xl:inline">To'lash</span>
                    </button>
                    <button onClick={() => onPurchase(sp)} title="Olib kelish (bir necha mahsulot)"
                            className="inline-flex items-center gap-1 px-2 py-1.5 rounded-button text-xs font-medium bg-primary/10 text-primary hover:bg-primary/20 transition">
                      <PackagePlus size={14} /> <span className="hidden xl:inline">Olib kelish</span>
                    </button>
                    <button onClick={() => onAddProduct(sp)} title="Shu joyga yangi mahsulot"
                            className="inline-flex items-center gap-1 px-2 py-1.5 rounded-button text-xs font-medium border border-black/10 hover:bg-black/5 transition">
                      <Plus size={14} /> <span className="hidden xl:inline">Mahsulot</span>
                    </button>
                    <button onClick={() => onEditSupplier(sp)} title="Yetkazib beruvchini tahrirlash"
                            className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                      <Pencil size={15} />
                    </button>
                  </div>
                )}
              </div>
            </div>

            {/* ===== Shoxlar: mahsulotlar ===== */}
            {isOpen && (
              items.length === 0 ? (
                <div className="relative">
                  <span className="absolute left-6 top-0 h-1/2 w-px bg-black/[0.12]" />
                  <span className="absolute left-6 top-1/2 w-5 h-px bg-black/[0.12]" />
                  <div className="ml-14 py-3 text-sm text-ink-soft">
                    Mahsulot yo'q —{' '}
                    {canWrite ? (
                      <button onClick={() => onAddProduct(sp)} className="text-primary hover:underline">
                        birinchisini qo'shing
                      </button>
                    ) : 'hozircha bo\'sh'}
                  </div>
                </div>
              ) : (
                items.map((p, i) => {
                  const last = i === items.length - 1;
                  const smeta = STOCK_META[p.stock_status];
                  const low = p.stock_status === 'low' || p.stock_status === 'out';
                  const unit = UNIT_LABEL[p.unit] ?? p.unit;
                  return (
                    <div key={p.id} className="relative">
                      {/* Vertikal ustun — oxirgi qatorda yarmigacha */}
                      <span className={cn('absolute left-6 w-px bg-black/[0.12]',
                        last ? 'top-0 h-1/2' : 'inset-y-0')} />
                      {/* Tirsak + tugun nuqtasi */}
                      <span className="absolute left-6 top-1/2 w-5 h-px bg-black/[0.12]" />
                      <span className={cn(
                        'absolute left-[42px] top-1/2 -translate-y-1/2 w-2 h-2 rounded-full ring-2 ring-card',
                        low ? 'bg-danger' : 'bg-primary/50')} />

                      <div className={cn(
                        'ml-14 my-1 rounded-button border px-3 py-2 flex flex-wrap items-center gap-x-3 gap-y-2 transition cursor-pointer',
                        low ? 'border-danger/25 bg-danger/[0.05] hover:bg-danger/[0.09]'
                            : 'border-black/[0.07] hover:bg-black/[0.02]')}
                           onClick={() => onOpenProduct(p)}>
                        <div className="min-w-0 basis-full sm:basis-0 sm:flex-1">
                          <div className="font-medium truncate flex items-center gap-1.5">
                            {low && <AlertTriangle size={13} className="text-danger shrink-0" />}
                            <span className="truncate">{p.name}</span>
                            <span className="text-ink-soft font-normal shrink-0">· {unit}</span>
                          </div>
                          <div className="text-xs text-ink-soft truncate">
                            {formatMoney(p.unit_price, p.currency)}/{unit}
                            {p.total_purchased > 0
                              ? ` · jami ${formatMoney(p.total_purchased, p.currency)}`
                              : ''}
                          </div>
                        </div>

                        {/* [−] qoldiq [+] */}
                        <div className="shrink-0 flex items-center gap-1.5"
                             onClick={(e) => e.stopPropagation()}>
                          {canWrite && (
                            <button onClick={() => onProductAction(p, 'consume')}
                                    disabled={p.stock <= 0} title="Sarflash (ombordan chiqim)"
                                    className="w-8 h-8 shrink-0 rounded-button flex items-center justify-center bg-warning/10 text-warning hover:bg-warning/20 transition disabled:opacity-40">
                              <Minus size={15} />
                            </button>
                          )}
                          <div className={cn(
                            'shrink-0 w-[100px] sm:w-[115px] rounded-button border px-2 py-1 text-center',
                            low ? 'border-danger/25 bg-danger/10' : 'border-black/[0.07] bg-black/[0.03]')}>
                            <div className={cn('font-bold leading-tight text-sm', smeta.value)}>
                              {formatQty(p.stock, unit)}
                            </div>
                            <div className={cn('text-[10px]',
                              low ? cn('font-semibold uppercase tracking-wide', smeta.value) : 'text-ink-soft')}>
                              {low ? smeta.label
                                   : `ombor${p.min_qty > 0 ? ` · min ${formatQty(p.min_qty)}` : ''}`}
                            </div>
                          </div>
                          {canWrite && (
                            <button onClick={() => onProductAction(p, 'purchase')}
                                    title="Shu mahsulotni olib kelish"
                                    className="w-8 h-8 shrink-0 rounded-button flex items-center justify-center bg-primary/10 text-primary hover:bg-primary/20 transition">
                              <Plus size={15} />
                            </button>
                          )}
                        </div>

                        <div className="flex items-center gap-1 shrink-0 ml-auto"
                             onClick={(e) => e.stopPropagation()}>
                          {canWrite && (
                            <button onClick={() => onProductAction(p, 'stock')}
                                    title="Qoldiqni to'g'rilash"
                                    className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                              <ClipboardCheck size={15} />
                            </button>
                          )}
                          {canWrite && (
                            <button onClick={() => onEditProduct(p)} title="Tahrirlash"
                                    className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                              <Pencil size={15} />
                            </button>
                          )}
                          {/* Omborda qoldiq bor mahsulot o'chirilmaydi — u
                              jismonan turibdi, avval sarflanishi kerak */}
                          {canDelete && (
                            <button onClick={() => onDeleteProduct(p)}
                                    disabled={p.stock > 0}
                                    title={p.stock > 0
                                      ? `Omborda ${formatQty(p.stock, unit)} qoldiq bor — avval sarflang`
                                      : "O'chirish (arxivga)"}
                                    className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger disabled:opacity-30 disabled:hover:bg-transparent disabled:hover:text-ink-soft disabled:cursor-not-allowed">
                              <Trash2 size={15} />
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })
              )
            )}

            {/* Yopilgan tugun — nechta mahsulot yashiringani ko'rinib tursin */}
            {!isOpen && items.length > 0 && (
              <button onClick={() => toggle(sp.id)}
                      className="ml-14 mt-1 text-xs text-ink-soft hover:text-primary inline-flex items-center gap-1">
                <ListTree size={13} /> {items.length} ta mahsulot yashirilgan
              </button>
            )}
          </div>
        );
      })}
    </div>
  );
}
