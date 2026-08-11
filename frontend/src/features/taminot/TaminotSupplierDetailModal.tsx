import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  X, Plus, Minus, Wallet, PackagePlus, ClipboardCheck, ClipboardList, Pencil, Trash2,
  Phone, AlertTriangle, PackageMinus, RotateCcw,
} from 'lucide-react';

import { api } from '@/api/client';
import ConfirmModal from '@/components/ui/ConfirmModal';
import EmptyState from '@/components/ui/EmptyState';
import { formatMoney, formatQty, formatDateTime } from '@/lib/format';
import { cn } from '@/lib/cn';

import { STOCK_META } from '@/features/taminot/stockMeta';
import { UNIT_LABEL, type TaminotProduct, type TaminotSupplier } from '@/features/taminot/types';
import TaminotProductModal from '@/features/taminot/TaminotProductModal';
import TaminotActionModal, { type ActionKind } from '@/features/taminot/TaminotActionModal';
import TaminotSupplierPaymentModal from '@/features/taminot/TaminotSupplierPaymentModal';
import TaminotPurchaseDocModal from '@/features/taminot/TaminotPurchaseDocModal';
import TaminotListModal from '@/features/taminot/TaminotListModal';
import TaminotListsPanel from '@/features/taminot/TaminotListsTab';

type TxKind = 'purchase' | 'payment' | 'consume' | 'adjust';

interface Tx {
  id: string;
  supplier_id: string;
  product_id?: string | null;
  product_name?: string | null;
  unit: string;
  kind: TxKind;
  qty: number;
  unit_price: number;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
  /** To'ldirilgan bo'lsa — arxivda: hisobga qo'shilmaydi, chizib ko'rsatiladi */
  deleted_at?: string | null;
}

const TX_META: Record<TxKind, { label: string; icon: typeof PackagePlus; tone: string }> = {
  purchase: { label: 'Olib kelish', icon: PackagePlus, tone: 'bg-primary/10 text-primary' },
  payment: { label: "To'lov", icon: Wallet, tone: 'bg-success/10 text-success' },
  consume: { label: 'Sarflandi', icon: PackageMinus, tone: 'bg-warning/15 text-warning' },
  adjust: { label: "Qoldiq to'g'rilandi", icon: ClipboardCheck, tone: 'bg-black/5 text-ink-soft' },
};

/**
 * Yetkazib beruvchi kartochkasi — guruhning ichi.
 *
 * Bu yerda: umumiy qarz (valyuta bo'yicha), guruhning mahsulotlari va butun
 * harakatlar tarixi. To'lov, olib kelish va spiska — hammasi guruh darajasida;
 * mahsulot qatorida esa faqat ombor amallari qoladi.
 */
export default function TaminotSupplierDetailModal({
  supplier, canWrite, canDelete, onClose, onChanged,
}: {
  supplier: TaminotSupplier;
  canWrite: boolean;
  canDelete: boolean;
  onClose: () => void;
  onChanged: () => void;
}) {
  const qc = useQueryClient();
  const [tab, setTab] = useState<'products' | 'history'>('products');

  // Bolalar modallari
  const [editProduct, setEditProduct] = useState<TaminotProduct | null | undefined>(undefined);
  const [action, setAction] = useState<{ product: TaminotProduct; kind: ActionKind } | null>(null);
  const [payment, setPayment] = useState(false);
  const [purchaseDoc, setPurchaseDoc] = useState(false);
  const [listModal, setListModal] = useState(false);
  const [delProduct, setDelProduct] = useState<TaminotProduct | null>(null);
  const [delTx, setDelTx] = useState<Tx | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const productsQ = useQuery<TaminotProduct[]>({
    queryKey: ['taminot-products', supplier.scope, supplier.id],
    queryFn: () => api.get('/taminot/products', {
      params: { scope: supplier.scope, supplier_id: supplier.id, sort: 'stock' },
    }).then((r) => r.data),
  });
  const txQ = useQuery<Tx[]>({
    queryKey: ['taminot-supplier-tx', supplier.id],
    queryFn: () => api.get(`/taminot/suppliers/${supplier.id}/transactions`).then((r) => r.data),
    enabled: tab === 'history',
  });

  const products = productsQ.data ?? [];
  const txs = txQ.data ?? [];

  /** Guruh ichidagi va tashqaridagi ma'lumotni birga yangilaydi. */
  function refresh() {
    productsQ.refetch();
    qc.invalidateQueries({ queryKey: ['taminot-supplier-tx', supplier.id] });
    qc.invalidateQueries({ queryKey: ['taminot-lists'] });
    onChanged();
  }

  async function confirmDeleteProduct() {
    if (!delProduct) return;
    setBusy(true);
    try {
      await api.delete(`/taminot/products/${delProduct.id}`);
      toast.success(delProduct.tx_count > 0 ? 'Arxivga o‘tkazildi' : "O'chirildi");
      setDelProduct(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally { setBusy(false); }
  }

  async function confirmDeleteTx() {
    if (!delTx) return;
    setBusy(true);
    try {
      await api.delete(`/taminot/transactions/${delTx.id}`);
      toast.success('Arxivga o‘tkazildi');
      setDelTx(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally { setBusy(false); }
  }

  /** Arxivdagi yozuvni tiklaydi — summa yana hisobga qo'shiladi. */
  async function restoreTx(id: string) {
    try {
      await api.post(`/taminot/transactions/${id}/restore`);
      toast.success('Tiklandi');
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    }
  }

  const attention = supplier.low_stock_count + supplier.out_of_stock_count;

  return (
    <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-3 sm:p-4"
         onClick={onClose}>
      <div className="bg-card rounded-card w-full max-w-3xl shadow-lg max-h-[94vh] flex flex-col"
           onClick={(e) => e.stopPropagation()}>

        {/* ===== Sarlavha: nom, telefon, qarz ===== */}
        <div className="px-4 sm:px-5 py-3 border-b border-black/5">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <h3 className="font-semibold text-lg truncate">{supplier.name}</h3>
              <div className="text-xs text-ink-soft flex items-center gap-3 flex-wrap">
                {supplier.phone && (
                  <a href={`tel:${supplier.phone}`}
                     className="inline-flex items-center gap-1 hover:text-primary">
                    <Phone size={12} /> {supplier.phone}
                  </a>
                )}
                <span>{supplier.product_count} ta mahsulot</span>
                {supplier.note && <span className="truncate">{supplier.note}</span>}
              </div>
            </div>
            <button onClick={onClose} className="p-1 rounded hover:bg-black/5 shrink-0">
              <X size={18} />
            </button>
          </div>

          {/* Qarz — har valyuta alohida qator */}
          <div className="mt-3 flex flex-wrap gap-2">
            {supplier.totals.map((t) => (
              <div key={t.currency}
                   className={cn('rounded-button border px-3 py-2 min-w-[150px]',
                     t.balance > 0
                       ? 'border-danger/25 bg-danger/10'
                       : 'border-success/25 bg-success/10')}>
                <div className={cn('text-[11px] font-medium',
                  t.balance > 0 ? 'text-danger/80' : 'text-success/80')}>
                  {t.balance > 0 ? 'Qarz qoldiq' : 'Qarz yo\'q'}
                </div>
                <div className={cn('text-lg font-bold',
                  t.balance > 0 ? 'text-danger' : 'text-success')}>
                  {formatMoney(t.balance, t.currency)}
                </div>
                <div className="text-[10px] text-ink-soft">
                  olib kelingan {formatMoney(t.total_purchased, t.currency)} · to'langan{' '}
                  {formatMoney(t.total_paid, t.currency)}
                </div>
              </div>
            ))}
            {attention > 0 && (
              <div className="rounded-button border border-warning/30 bg-warning/10 px-3 py-2 min-w-[150px]">
                <div className="text-[11px] font-medium text-warning flex items-center gap-1">
                  <AlertTriangle size={12} /> Ombor
                </div>
                <div className="text-lg font-bold text-warning">{attention} ta</div>
                <div className="text-[10px] text-ink-soft">kam qolgan yoki tugagan</div>
              </div>
            )}
          </div>

          {/* Amallar — hammasi guruh darajasida */}
          {canWrite && (
            <div className="mt-3 flex flex-wrap gap-2">
              <button onClick={() => setPayment(true)}
                      className="px-3 py-1.5 text-sm rounded-button bg-success/10 text-success hover:bg-success/20 inline-flex items-center gap-1.5">
                <Wallet size={15} /> To'lash
              </button>
              <button onClick={() => setPurchaseDoc(true)}
                      className="px-3 py-1.5 text-sm rounded-button bg-primary/10 text-primary hover:bg-primary/20 inline-flex items-center gap-1.5">
                <PackagePlus size={15} /> Olib kelish
              </button>
              <button onClick={() => setListModal(true)}
                      className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5 inline-flex items-center gap-1.5">
                <ClipboardList size={15} /> Spiska qilish
              </button>
              <button onClick={() => setEditProduct(null)}
                      className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5 inline-flex items-center gap-1.5">
                <Plus size={15} /> Yangi mahsulot
              </button>
            </div>
          )}
        </div>

        {/* ===== Tablar ===== */}
        <div className="px-4 sm:px-5 pt-3 flex gap-1.5">
          {([['products', `Mahsulotlar (${products.length})`], ['history', 'Harakatlar tarixi']] as const)
            .map(([key, label]) => (
              <button key={key} onClick={() => setTab(key)}
                className={cn('px-3 py-1.5 rounded-button text-sm font-medium transition',
                  tab === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10')}>
                {label}
              </button>
            ))}
        </div>

        <div className="p-4 sm:p-5 overflow-y-auto space-y-3">
          {tab === 'products' ? (
            <>
              {/* Shu yetkazib beruvchi uchun qoralama spiskalar */}
              <TaminotListsPanel scope={supplier.scope} supplierId={supplier.id}
                                 canWrite={canWrite} canDelete={canDelete} onChanged={refresh} />

              {productsQ.isLoading ? (
                <div className="space-y-2">
                  {Array.from({ length: 4 }).map((_, i) => (
                    <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />
                  ))}
                </div>
              ) : products.length === 0 ? (
                <EmptyState title="Hali mahsulot yo'q"
                  description={canWrite
                    ? "«Yangi mahsulot» tugmasi orqali shu joydan olinadigan mahsulotlarni qo'shing"
                    : 'Hozircha bo\'sh'} />
              ) : (
                <div className="divide-y divide-black/5">
                  {products.map((p) => {
                    const sm = STOCK_META[p.stock_status];
                    const low = p.stock_status === 'low' || p.stock_status === 'out';
                    const unit = UNIT_LABEL[p.unit] ?? p.unit;
                    return (
                      <div key={p.id}
                           className={cn('flex flex-wrap items-center gap-x-3 gap-y-2 py-3 -mx-2 px-2 rounded-button transition',
                             low ? 'bg-danger/[0.04]' : 'hover:bg-black/[0.02]')}>
                        <div className="min-w-0 basis-full sm:basis-0 sm:flex-1">
                          <div className="font-medium truncate flex items-center gap-1.5">
                            {low && <AlertTriangle size={13} className="text-danger shrink-0" />}
                            <span className="truncate">{p.name}</span>
                            <span className="text-ink-soft font-normal shrink-0">· {unit}</span>
                          </div>
                          <div className="text-xs text-ink-soft truncate">
                            {formatMoney(p.unit_price, p.currency)}/{unit}
                            {p.last_purchase_at ? ` · oxirgi: ${formatDateTime(p.last_purchase_at)}` : ''}
                          </div>
                        </div>

                        {/* [−] qoldiq [+] — chapda sarflash, o'ngda tez olib kelish */}
                        <div className="shrink-0 flex items-center gap-1.5">
                          {canWrite && (
                            <button onClick={() => setAction({ product: p, kind: 'consume' })}
                                    disabled={p.stock <= 0} title="Sarflash (ombordan chiqim)"
                                    className="w-8 h-8 shrink-0 rounded-button flex items-center justify-center bg-warning/10 text-warning hover:bg-warning/20 transition disabled:opacity-40">
                              <Minus size={15} />
                            </button>
                          )}
                          <div className={cn('shrink-0 w-[100px] sm:w-[120px] rounded-button border px-2 sm:px-3 py-1.5 text-center',
                            low ? 'border-danger/25 bg-danger/10' : 'border-black/[0.07] bg-black/[0.03]')}>
                            <div className={cn('font-bold leading-tight', sm.value)}>
                              {formatQty(p.stock, unit)}
                            </div>
                            {low ? (
                              <div className={cn('text-[10px] font-semibold uppercase tracking-wide', sm.value)}>
                                {sm.label}
                              </div>
                            ) : (
                              <div className="text-[10px] text-ink-soft">
                                ombor qoldiq{p.min_qty > 0 ? ` · min ${formatQty(p.min_qty)}` : ''}
                              </div>
                            )}
                          </div>
                          {canWrite && (
                            <button onClick={() => setAction({ product: p, kind: 'purchase' })}
                                    title="Shu mahsulotni olib kelish"
                                    className="w-8 h-8 shrink-0 rounded-button flex items-center justify-center bg-primary/10 text-primary hover:bg-primary/20 transition">
                              <Plus size={15} />
                            </button>
                          )}
                        </div>

                        <div className="flex items-center gap-1 shrink-0 ml-auto">
                          {canWrite && (
                            <button onClick={() => setAction({ product: p, kind: 'stock' })}
                                    title="Qoldiqni to'g'rilash"
                                    className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                              <ClipboardCheck size={15} />
                            </button>
                          )}
                          {canWrite && (
                            <button onClick={() => setEditProduct(p)} title="Tahrirlash"
                                    className="p-1.5 rounded hover:bg-black/5 text-ink-soft hover:text-primary">
                              <Pencil size={15} />
                            </button>
                          )}
                          {/* Omborda qoldiq bor mahsulot o'chirilmaydi */}
                          {canDelete && (
                            <button onClick={() => setDelProduct(p)}
                                    disabled={p.stock > 0}
                                    title={p.stock > 0
                                      ? `Omborda ${formatQty(p.stock, unit)} qoldiq bor — avval sarflang`
                                      : "O'chirish"}
                                    className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger disabled:opacity-30 disabled:hover:bg-transparent disabled:hover:text-ink-soft disabled:cursor-not-allowed">
                              <Trash2 size={15} />
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </>
          ) : (
            /* ===================== TARIX ===================== */
            txQ.isLoading ? (
              <div className="space-y-2">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
                ))}
              </div>
            ) : txs.length === 0 ? (
              <EmptyState title="Harakatlar yo'q" description="Hali kirim ham, to'lov ham qilinmagan" />
            ) : (
              <div className="divide-y divide-black/5 border border-black/10 rounded-button overflow-hidden">
                {txs.map((tx) => {
                  const m = TX_META[tx.kind];
                  const Icon = m.icon;
                  const unit = UNIT_LABEL[tx.unit] ?? tx.unit;
                  // Arxivdagi yozuv — hisobda yo'q, lekin tarixda chizilgan holda turadi
                  const gone = !!tx.deleted_at;
                  return (
                    <div key={tx.id} className={cn('flex items-center gap-3 px-3 py-2.5 group',
                      gone && 'bg-black/[0.02]')}>
                      <div className={cn('w-8 h-8 rounded-button flex items-center justify-center shrink-0',
                        gone ? 'bg-black/5 text-ink-soft' : m.tone)}>
                        <Icon size={15} />
                      </div>
                      <div className={cn('min-w-0 flex-1', gone && 'line-through opacity-55')}>
                        <div className="text-sm font-medium truncate">
                          {/* To'lov guruhga qilingan — mahsulot nomi bo'lmaydi */}
                          {tx.product_name ?? m.label}
                          {tx.kind === 'purchase' && (
                            <span className="text-ink-soft font-normal">
                              {' '}· {formatQty(tx.qty)} × {formatMoney(tx.unit_price, tx.currency)}
                            </span>
                          )}
                          {tx.kind === 'consume' && (
                            <span className="text-ink-soft font-normal"> · −{formatQty(tx.qty, unit)}</span>
                          )}
                          {tx.kind === 'adjust' && (
                            <span className="text-ink-soft font-normal">
                              {' '}· {tx.qty > 0 ? '+' : ''}{formatQty(tx.qty, unit)}
                            </span>
                          )}
                        </div>
                        <div className="text-xs text-ink-soft truncate">
                          {formatDateTime(tx.created_at)}
                          {tx.product_name ? ` · ${m.label}` : ''}
                          {tx.note ? ` · ${tx.note}` : ''}
                        </div>
                      </div>
                      {gone && (
                        <span className="badge bg-black/5 text-ink-soft text-[10px] shrink-0">
                          Arxiv
                        </span>
                      )}
                      <div className={cn('text-sm font-bold shrink-0',
                        gone ? 'line-through text-ink-soft opacity-55'
                          : tx.kind === 'purchase' ? 'text-danger'
                          : tx.kind === 'payment' ? 'text-success' : 'text-ink-soft')}>
                        {tx.kind === 'purchase' ? `+${formatMoney(tx.amount, tx.currency)}`
                          : tx.kind === 'payment' ? `−${formatMoney(tx.amount, tx.currency)}`
                          : '—'}
                      </div>
                      {canDelete && (
                        gone ? (
                          <button onClick={() => restoreTx(tx.id)} title="Tiklash"
                                  className="p-1.5 rounded hover:bg-primary/10 text-ink-soft hover:text-primary transition shrink-0">
                            <RotateCcw size={15} />
                          </button>
                        ) : (
                          <button onClick={() => setDelTx(tx)} title="Arxivga o'tkazish"
                                  className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition shrink-0">
                            <Trash2 size={15} />
                          </button>
                        )
                      )}
                    </div>
                  );
                })}
              </div>
            )
          )}
        </div>
      </div>

      {/* ===== Bolalar modallari ===== */}
      {editProduct !== undefined && (
        <TaminotProductModal scope={supplier.scope}
          supplierId={editProduct ? undefined : supplier.id}
          product={editProduct}
          onClose={() => setEditProduct(undefined)} onSaved={refresh} />
      )}
      {action && (
        <TaminotActionModal product={action.product} kind={action.kind}
          onClose={() => setAction(null)} onSaved={refresh} />
      )}
      {payment && (
        <TaminotSupplierPaymentModal supplier={supplier}
          onClose={() => setPayment(false)} onSaved={refresh} />
      )}
      {purchaseDoc && (
        <TaminotPurchaseDocModal supplier={supplier}
          onClose={() => setPurchaseDoc(false)} onSaved={refresh} />
      )}
      {listModal && (
        <TaminotListModal scope={supplier.scope} supplier={supplier}
          onClose={() => setListModal(false)} onSaved={refresh} />
      )}
      <ConfirmModal
        open={!!delProduct}
        title={delProduct?.name ?? ''}
        message={delProduct && delProduct.tx_count > 0
          ? "Mahsulot va uning yozuvlari ARXIVGA o'tadi: qarz hamda ombor qoldig'idan chiqadi, lekin tarixda saqlanib qoladi va keyin tiklash mumkin."
          : "Ushbu mahsulot o'chiriladi. Hech qanday harakati bo'lmagani uchun saqlanadigan tarix yo'q."}
        confirmText="O'chirish"
        loading={busy}
        onConfirm={confirmDeleteProduct}
        onCancel={() => setDelProduct(null)}
      />
      <ConfirmModal
        open={!!delTx}
        title="Harakatni arxivga o'tkazish"
        message="Yozuv hisobdan chiqadi (summa to'g'ri ayiriladi), lekin yo'qolmaydi — tarixda ustidan chizilgan holda qoladi va kerak bo'lsa tiklanadi."
        confirmText="Arxivga"
        loading={busy}
        onConfirm={confirmDeleteTx}
        onCancel={() => setDelTx(null)}
      />
    </div>
  );
}
