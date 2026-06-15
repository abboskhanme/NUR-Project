import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Trash2, PackagePlus, Wallet } from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney, formatDateTime } from '@/lib/format';
import ConfirmModal from '@/components/ui/ConfirmModal';
import type { DebtProduct } from '@/features/debts/DebtProductModal';

interface Tx {
  id: string;
  kind: 'purchase' | 'payment';
  qty: number;
  unit_price: number;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
}

export default function DebtTransactionsModal({
  product, onClose, onChanged,
}: { product: DebtProduct; onClose: () => void; onChanged: () => void }) {
  const { t } = useTranslation();
  const [delId, setDelId] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const txQ = useQuery<Tx[]>({
    queryKey: ['debt-tx', product.id],
    queryFn: () => api.get(`/debts/products/${product.id}/transactions`).then((r) => r.data),
  });
  const txs = txQ.data ?? [];

  async function confirmDelete() {
    if (!delId) return;
    setDeleting(true);
    try {
      await api.delete(`/debts/transactions/${delId}`);
      toast.success(t('debts.toast.deleted'));
      setDelId(null);
      txQ.refetch();
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('debts.toast.error'));
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
            <p className="text-xs text-ink-soft">{t('debts.tx.title')}</p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {/* Qarz qoldig'i */}
        <div className="px-5 pt-4">
          <div className="rounded-button bg-danger/10 border border-danger/20 px-4 py-3 flex items-center justify-between">
            <span className="text-sm font-medium text-danger/90">{t('debts.table.balance')}</span>
            <span className="text-xl font-bold text-danger">{formatMoney(product.balance, product.currency)}</span>
          </div>
          <div className="grid grid-cols-2 gap-3 mt-2 text-sm">
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">{t('debts.kpi.purchased')}</span>
              <span className="font-medium">{formatMoney(product.total_purchased, product.currency)}</span>
            </div>
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">{t('debts.kpi.paid')}</span>
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
            <div className="text-sm text-ink-soft text-center py-8">{t('debts.tx.empty')}</div>
          ) : (
            <div className="divide-y divide-black/5 border border-black/10 rounded-button overflow-hidden">
              {txs.map((tx) => {
                const purchase = tx.kind === 'purchase';
                return (
                  <div key={tx.id} className="flex items-center gap-3 px-3 py-2.5 group">
                    <div className={`w-8 h-8 rounded-button flex items-center justify-center shrink-0 ${
                      purchase ? 'bg-primary/10 text-primary' : 'bg-success/10 text-success'}`}>
                      {purchase ? <PackagePlus size={15} /> : <Wallet size={15} />}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="text-sm font-medium">
                        {purchase
                          ? (product.debt_type === 'product' ? t('debts.tx.purchase') : t('debts.tx.addDebt'))
                          : t('debts.tx.payment')}
                        {purchase && product.debt_type === 'product' && (
                          <span className="text-ink-soft font-normal">
                            {' '}· {tx.qty} × {formatMoney(tx.unit_price, tx.currency)}
                          </span>
                        )}
                      </div>
                      <div className="text-xs text-ink-soft">
                        {formatDateTime(tx.created_at)}{tx.note ? ` · ${tx.note}` : ''}
                      </div>
                    </div>
                    <div className={`text-sm font-bold shrink-0 ${purchase ? 'text-danger' : 'text-success'}`}>
                      {purchase ? '+' : '−'}{formatMoney(tx.amount, tx.currency)}
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
        title={t('debts.tx.title')}
        message={t('debts.tx.deleteConfirm')}
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setDelId(null)}
      />
    </div>
  );
}
