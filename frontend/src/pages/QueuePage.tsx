import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { ChevronsUp, ChevronUp, ChevronDown, ListOrdered, Search } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import StatusBadge from '@/components/ui/StatusBadge';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatUZS } from '@/lib/format';

interface ProductMini { product_type?: string; model?: string | null; name?: string | null; kvm?: number | null; display_name?: string; }
interface Item { product?: ProductMini | null; bunker_direction?: string | null; quantity: number; }
interface QueueOrder {
  id: string; code: string; status: string; order_date: string; position: number;
  customer?: { full_name: string; phone?: string; region?: string | null } | null;
  items: Item[];
  items_total_uzs: string; balance_uzs: string;
}

function itemSummary(o: QueueOrder, dirRight: string, dirLeft: string): string {
  if (!o.items?.length) return '—';
  return o.items
    .map((i) => {
      const nm = i.product?.display_name ?? i.product?.model ?? i.product?.name ?? '?';
      const rawDir = i.product?.product_type !== 'additional' && i.bunker_direction
        ? (i.bunker_direction === 'right' ? dirRight : i.bunker_direction === 'left' ? dirLeft : '')
        : '';
      const dir = rawDir ? ` ${rawDir}` : '';
      const qty = i.quantity > 1 ? ` ×${i.quantity}` : '';
      return `${nm}${dir}${qty}`;
    })
    .join(', ');
}

export default function QueuePage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [search, setSearch] = useState('');

  const dirRight = t('sales.dirRight');
  const dirLeft = t('sales.dirLeft');

  const { data, isLoading } = useQuery<QueueOrder[]>({
    queryKey: ['orders', 'queue'],
    queryFn: () => api.get('/orders/queue').then((r) => r.data),
  });
  const queue = data ?? [];

  const allPending = useMemo(() => queue.filter((o) => o.status === 'new'), [queue]);
  const ready = useMemo(() => queue.filter((o) => o.status === 'ready'), [queue]);

  const searching = search.trim().length > 0;
  const pendingShown = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return allPending;
    const qDigits = q.replace(/\D/g, '');
    return allPending.filter((o) => {
      if (o.code.toLowerCase().includes(q)) return true;
      if (o.customer?.full_name?.toLowerCase().includes(q)) return true;
      if (o.customer?.region?.toLowerCase().includes(q)) return true;
      if (qDigits && (o.customer?.phone ?? '').replace(/\D/g, '').includes(qDigits)) return true;
      if (itemSummary(o, dirRight, dirLeft).toLowerCase().includes(q)) return true;
      return false;
    });
  }, [allPending, search, dirRight, dirLeft]);

  async function move(id: string, action: 'top' | 'up' | 'down', e: React.MouseEvent) {
    e.stopPropagation();
    try {
      await api.post(`/orders/${id}/queue-move`, { action });
      qc.invalidateQueries({ queryKey: ['orders', 'queue'] });
      qc.invalidateQueries({ queryKey: ['orders'] });
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || t('common.error'));
    }
  }

  function renderTable(rows: QueueOrder[], reorderable: boolean) {
    return (
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-left text-ink-soft border-b border-black/5">
            <tr>
              <th className="py-2 pr-3 w-10">#</th>
              <th className="py-2 pr-3">{t('orders.code')}</th>
              <th className="py-2 pr-3">{t('sales.colCustomer')}</th>
              <th className="py-2 pr-3">{t('sales.sectionItems')}</th>
              <th className="py-2 pr-3">{t('common.date')}</th>
              <th className="py-2 pr-3 text-right">{t('common.amount')}</th>
              <th className="py-2 pr-3">{t('common.status')}</th>
              {reorderable && <th className="py-2 pr-3 text-right">{t('sales.colQueue')}</th>}
            </tr>
          </thead>
          <tbody>
            {rows.map((o, idx) => (
              <tr key={o.id} onClick={() => navigate(`/orders/${o.id}`)}
                  className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                <td className="py-2 pr-3">
                  <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-primary/10 text-primary font-bold text-xs">
                    {o.position || idx + 1}
                  </span>
                </td>
                <td className="py-2 pr-3 font-medium">{o.code}</td>
                <td className="py-2 pr-3">
                  <div className="truncate max-w-[160px]">{o.customer?.full_name ?? '—'}</div>
                  {o.customer?.region && <div className="text-xs text-ink-soft">{o.customer.region}</div>}
                </td>
                <td className="py-2 pr-3 max-w-[220px] truncate" title={itemSummary(o, dirRight, dirLeft)}>{itemSummary(o, dirRight, dirLeft)}</td>
                <td className="py-2 pr-3">{formatDate(o.order_date)}</td>
                <td className="py-2 pr-3 text-right">{formatUZS(o.items_total_uzs)}</td>
                <td className="py-2 pr-3"><StatusBadge status={o.status} /></td>
                {reorderable && (
                  <td className="py-2 pr-3">
                    <div className="flex items-center gap-1 justify-end">
                      <button onClick={(e) => move(o.id, 'top', e)} disabled={idx === 0}
                              className="p-1.5 rounded hover:bg-primary/10 text-primary disabled:opacity-30" title={t('sales.moveTop')}>
                        <ChevronsUp size={16} />
                      </button>
                      <button onClick={(e) => move(o.id, 'up', e)} disabled={idx === 0}
                              className="p-1.5 rounded hover:bg-black/5 text-ink/60 disabled:opacity-30" title={t('sales.moveUp')}>
                        <ChevronUp size={16} />
                      </button>
                      <button onClick={(e) => move(o.id, 'down', e)} disabled={idx === rows.length - 1}
                              className="p-1.5 rounded hover:bg-black/5 text-ink/60 disabled:opacity-30" title={t('sales.moveDown')}>
                        <ChevronDown size={16} />
                      </button>
                    </div>
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-end justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('sales.queueTitle')}</h1>
          <p className="text-sm text-ink-soft">{t('sales.queueSubtitle')}</p>
        </div>
        <div className="flex items-center gap-2 w-full sm:w-72 bg-white border border-black/10 rounded-button px-3 py-1.5">
          <Search size={16} className="text-ink/40 shrink-0" />
          <input
            placeholder={t('sales.queueSearch')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="bg-transparent outline-none flex-1 text-sm min-w-0"
          />
          {searching && (
            <button onClick={() => setSearch('')} className="text-ink/40 hover:text-ink text-xs shrink-0">✕</button>
          )}
        </div>
      </div>

      {isLoading ? (
        <Card>
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        </Card>
      ) : queue.length === 0 ? (
        <Card>
          <EmptyState title={t('sales.queueEmpty')} description={t('sales.queueEmptyDesc')} />
        </Card>
      ) : (
        <>
          <Card title={searching
            ? t('sales.queueSectionSearch', { shown: pendingShown.length, total: allPending.length })
            : t('sales.queueSection', { count: allPending.length })}>
            {allPending.length === 0
              ? <EmptyState title={t('sales.queuePendingEmpty')} description={t('sales.queuePendingEmptyDesc')} />
              : pendingShown.length === 0
                ? <EmptyState title={t('sales.queueNotFound')} description={t('sales.queueNotFoundDesc')} />
                : renderTable(pendingShown, !searching)}
            {searching && pendingShown.length > 0 && (
              <p className="text-xs text-ink-soft mt-3">
                {t('sales.queueSearchMode')}
              </p>
            )}
          </Card>

          {ready.length > 0 && (
            <Card title={t('sales.readySection', { count: ready.length })}>
              <p className="text-xs text-ink-soft mb-3">{t('sales.readyDesc')}</p>
              {renderTable(ready, false)}
            </Card>
          )}
        </>
      )}

      <div className="flex items-center gap-2 text-xs text-ink-soft">
        <ListOrdered size={14} /> {t('sales.queueHint')}
      </div>
    </div>
  );
}
