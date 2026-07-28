import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Trash2, PackagePlus, Wallet, PackageMinus, ClipboardCheck } from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney, formatQty, formatDateTime } from '@/lib/format';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { cn } from '@/lib/cn';
import { STOCK_META } from '@/features/taminot/TaminotStockTab';
import type { TaminotProduct } from '@/features/taminot/TaminotProductModal';

type TxKind = 'purchase' | 'payment' | 'consume' | 'adjust';

interface Tx {
  id: string;
  kind: TxKind;
  qty: number;
  unit_price: number;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
}

const UNIT_LABEL: Record<string, string> = { dona: 'dona', kg: 'kg', metr: 'metr', list: 'list' };

/** Har bir harakat turining ko'rinishi (ikonka, rang, sarlavha). */
const TX_META: Record<TxKind, { label: string; icon: typeof PackagePlus; tone: string }> = {
  purchase: { label: 'Olib kelish', icon: PackagePlus, tone: 'bg-primary/10 text-primary' },
  payment: { label: "To'lov", icon: Wallet, tone: 'bg-success/10 text-success' },
  consume: { label: 'Sarflandi', icon: PackageMinus, tone: 'bg-warning/15 text-warning' },
  adjust: { label: "Qoldiq to'g'rilandi", icon: ClipboardCheck, tone: 'bg-black/5 text-ink-soft' },
};

/** Bitta mahsulot bo'yicha to'liq harakatlar tarixi (o'chirish mumkin). */
export default function TaminotTransactionsModal({
  product, onClose, onChanged,
}: { product: TaminotProduct; onClose: () => void; onChanged: () => void }) {
  const [delId, setDelId] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const txQ = useQuery<Tx[]>({
    queryKey: ['taminot-tx', product.id],
    queryFn: () => api.get(`/taminot/products/${product.id}/transactions`).then((r) => r.data),
  });
  const txs = txQ.data ?? [];

  const sm = STOCK_META[product.stock_status];
  const attention = product.stock_status === 'low' || product.stock_status === 'out';
  const unitLabel = UNIT_LABEL[product.unit] ?? product.unit;

  async function confirmDelete() {
    if (!delId) return;
    setDeleting(true);
    try {
      await api.delete(`/taminot/transactions/${delId}`);
      toast.success("O'chirildi");
      setDelId(null);
      txQ.refetch();
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card z-10">
          <div>
            <h3 className="font-semibold">{product.name}</h3>
            <p className="text-xs text-ink-soft">Harakatlar tarixi</p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {/* Ombor qoldig'i va qarz qoldig'i */}
        <div className="px-5 pt-4">
          <div className="grid grid-cols-2 gap-3">
            <div className={cn('rounded-button border px-4 py-3',
              attention ? 'border-danger/25 bg-danger/10' : 'border-black/10 bg-black/[0.03]')}>
              <div className="text-xs font-medium text-ink-soft">Ombor qoldig'i</div>
              <div className={cn('text-xl font-bold mt-0.5', sm.value)}>
                {formatQty(product.stock, unitLabel)}
              </div>
              <span className={cn('badge mt-1 !px-1.5 !py-0 text-[10px]', sm.badge)}>{sm.label}</span>
            </div>
            <div className="rounded-button bg-danger/10 border border-danger/20 px-4 py-3">
              <div className="text-xs font-medium text-danger/80">Qarz qoldig'i</div>
              <div className="text-xl font-bold text-danger mt-0.5">
                {formatMoney(product.balance, product.currency)}
              </div>
              {product.min_qty > 0 && (
                <div className="text-[10px] text-ink-soft mt-1.5">
                  chegara: {formatQty(product.min_qty, unitLabel)}
                </div>
              )}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3 mt-2 text-sm">
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">Olib kelingan</span>
              <span className="font-medium">{formatQty(product.in_qty, unitLabel)}</span>
            </div>
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">Sarflangan</span>
              <span className="font-medium text-warning">{formatQty(product.out_qty, unitLabel)}</span>
            </div>
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">Umumiy qiymat</span>
              <span className="font-medium">{formatMoney(product.total_purchased, product.currency)}</span>
            </div>
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">To'langan</span>
              <span className="font-medium text-success">{formatMoney(product.total_paid, product.currency)}</span>
            </div>
          </div>
        </div>

        <div className="p-5">
          {txQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : txs.length === 0 ? (
            <div className="text-sm text-ink-soft text-center py-8">Harakatlar yo'q</div>
          ) : (
            <div className="divide-y divide-black/5 border border-black/10 rounded-button overflow-hidden">
              {txs.map((tx) => {
                const m = TX_META[tx.kind];
                const Icon = m.icon;
                return (
                  <div key={tx.id} className="flex items-center gap-3 px-3 py-2.5 group">
                    <div className={`w-8 h-8 rounded-button flex items-center justify-center shrink-0 ${m.tone}`}>
                      <Icon size={15} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="text-sm font-medium">
                        {m.label}
                        {tx.kind === 'purchase' && (
                          <span className="text-ink-soft font-normal">
                            {' '}· {formatQty(tx.qty)} × {formatMoney(tx.unit_price, tx.currency)}
                          </span>
                        )}
                        {tx.kind === 'consume' && (
                          <span className="text-ink-soft font-normal"> · {formatQty(tx.qty, unitLabel)}</span>
                        )}
                        {tx.kind === 'adjust' && (
                          <span className="text-ink-soft font-normal">
                            {' '}· {tx.qty > 0 ? '+' : ''}{formatQty(tx.qty, unitLabel)}
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-ink-soft">
                        {formatDateTime(tx.created_at)}{tx.note ? ` · ${tx.note}` : ''}
                      </div>
                    </div>
                    <div className={cn('text-sm font-bold shrink-0',
                      tx.kind === 'purchase' ? 'text-danger'
                        : tx.kind === 'payment' ? 'text-success' : 'text-ink-soft')}>
                      {tx.kind === 'purchase' ? `+${formatMoney(tx.amount, tx.currency)}`
                        : tx.kind === 'payment' ? `−${formatMoney(tx.amount, tx.currency)}`
                        : '—'}
                    </div>
                    <button onClick={() => setDelId(tx.id)}
                            className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger opacity-0 group-hover:opacity-100 transition">
                      <Trash2 size={15} />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      <ConfirmModal
        open={!!delId}
        title="Harakatni o'chirish"
        message="Ushbu harakatni o'chirasizmi?"
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setDelId(null)}
      />
    </div>
  );
}
