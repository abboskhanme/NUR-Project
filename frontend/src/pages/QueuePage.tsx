import { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { ChevronsUp, ChevronUp, ChevronDown, ListOrdered } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import StatusBadge from '@/components/ui/StatusBadge';
import EmptyState from '@/components/ui/EmptyState';
import { formatDate, formatUZS } from '@/lib/format';

interface ProductMini { product_type?: string; model?: string | null; name?: string | null; kvm?: number | null; display_name?: string; }
interface Item { product?: ProductMini | null; bunker_direction?: string | null; quantity: number; }
interface QueueOrder {
  id: string; code: string; status: string; order_date: string; position: number;
  customer?: { full_name: string; region?: string | null } | null;
  items: Item[];
  items_total_uzs: string; balance_uzs: string;
}

const DIR = (d?: string | null) => (d === 'right' ? "O'NG" : d === 'left' ? 'CHAP' : '');

function itemSummary(o: QueueOrder): string {
  if (!o.items?.length) return '—';
  return o.items
    .map((i) => {
      const nm = i.product?.display_name ?? i.product?.model ?? i.product?.name ?? '?';
      const dir = i.product?.product_type !== 'additional' && DIR(i.bunker_direction) ? ` ${DIR(i.bunker_direction)}` : '';
      const qty = i.quantity > 1 ? ` ×${i.quantity}` : '';
      return `${nm}${dir}${qty}`;
    })
    .join(', ');
}

export default function QueuePage() {
  const navigate = useNavigate();
  const qc = useQueryClient();

  const { data, isLoading } = useQuery<QueueOrder[]>({
    queryKey: ['orders', 'queue'],
    queryFn: () => api.get('/orders/queue').then((r) => r.data),
  });
  const queue = data ?? [];

  const QUEUE_LIMIT = 25;
  const allPending = useMemo(() => queue.filter((o) => o.status === 'new'), [queue]);
  const pending = useMemo(() => allPending.slice(0, QUEUE_LIMIT), [allPending]);
  const pendingHidden = Math.max(0, allPending.length - QUEUE_LIMIT);
  const ready = useMemo(() => queue.filter((o) => o.status === 'ready'), [queue]);

  async function move(id: string, action: 'top' | 'up' | 'down', e: React.MouseEvent) {
    e.stopPropagation();
    try {
      await api.post(`/orders/${id}/queue-move`, { action });
      qc.invalidateQueries({ queryKey: ['orders', 'queue'] });
      qc.invalidateQueries({ queryKey: ['orders'] });
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || 'Xatolik');
    }
  }

  function renderTable(rows: QueueOrder[], reorderable: boolean) {
    return (
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-left text-ink-soft border-b border-black/5">
            <tr>
              <th className="py-2 pr-3 w-10">#</th>
              <th className="py-2 pr-3">Kod</th>
              <th className="py-2 pr-3">Mijoz</th>
              <th className="py-2 pr-3">Mahsulot(lar)</th>
              <th className="py-2 pr-3">Sana</th>
              <th className="py-2 pr-3 text-right">Summa</th>
              <th className="py-2 pr-3">Status</th>
              {reorderable && <th className="py-2 pr-3 text-right">Navbat</th>}
            </tr>
          </thead>
          <tbody>
            {rows.map((o, idx) => (
              <tr key={o.id} onClick={() => navigate(`/orders/${o.id}`)}
                  className="border-b border-black/5 hover:bg-black/5 cursor-pointer">
                <td className="py-2 pr-3">
                  <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-primary/10 text-primary font-bold text-xs">
                    {idx + 1}
                  </span>
                </td>
                <td className="py-2 pr-3 font-medium">{o.code}</td>
                <td className="py-2 pr-3">
                  <div className="truncate max-w-[160px]">{o.customer?.full_name ?? '—'}</div>
                  {o.customer?.region && <div className="text-xs text-ink-soft">{o.customer.region}</div>}
                </td>
                <td className="py-2 pr-3 max-w-[220px] truncate" title={itemSummary(o)}>{itemSummary(o)}</td>
                <td className="py-2 pr-3">{formatDate(o.order_date)}</td>
                <td className="py-2 pr-3 text-right">{formatUZS(o.items_total_uzs)}</td>
                <td className="py-2 pr-3"><StatusBadge status={o.status} /></td>
                {reorderable && (
                  <td className="py-2 pr-3">
                    <div className="flex items-center gap-1 justify-end">
                      <button onClick={(e) => move(o.id, 'top', e)} disabled={idx === 0}
                              className="p-1.5 rounded hover:bg-primary/10 text-primary disabled:opacity-30" title="Eng yuqoriga">
                        <ChevronsUp size={16} />
                      </button>
                      <button onClick={(e) => move(o.id, 'up', e)} disabled={idx === 0}
                              className="p-1.5 rounded hover:bg-black/5 text-ink/60 disabled:opacity-30" title="Yuqoriga">
                        <ChevronUp size={16} />
                      </button>
                      <button onClick={(e) => move(o.id, 'down', e)} disabled={idx === rows.length - 1}
                              className="p-1.5 rounded hover:bg-black/5 text-ink/60 disabled:opacity-30" title="Pastga">
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
      <div>
        <h1 className="text-2xl font-bold">Navbat</h1>
        <p className="text-sm text-ink-soft">
          Ishlab chiqarish navbati — yuqorida turgan buyurtmalar oldin bajariladi.
          Shoshilinch buyurtmani strelka tugmalari bilan yuqoriga ko'taring.
        </p>
      </div>

      {isLoading ? (
        <Card>
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        </Card>
      ) : queue.length === 0 ? (
        <Card>
          <EmptyState title="Navbat bo'sh" description="Faol (yetkazilmagan) buyurtmalar shu yerda navbat bo'yicha ko'rinadi" />
        </Card>
      ) : (
        <>
          <Card title={`Navbatda (${allPending.length})`}>
            {allPending.length === 0
              ? <EmptyState title="Navbatda buyurtma yo'q" description="Yangi buyurtmalar shu yerda ko'rinadi" />
              : renderTable(pending, true)}
            {pendingHidden > 0 && (
              <p className="text-xs text-ink-soft mt-3 text-center">
                Eng oldindagi {QUEUE_LIMIT} ta ko'rsatilyapti — yana {pendingHidden} ta navbatda.
              </p>
            )}
          </Card>

          {ready.length > 0 && (
            <Card title={`Tayyor bo'ldi (${ready.length})`}>
              <p className="text-xs text-ink-soft mb-3">Ishlab chiqarilgan, yetkazishni kutayotgan buyurtmalar.</p>
              {renderTable(ready, false)}
            </Card>
          )}
        </>
      )}

      <div className="flex items-center gap-2 text-xs text-ink-soft">
        <ListOrdered size={14} /> Navbatga faqat faol buyurtmalar kiradi: Navbatda va Tayyor bo'ldi. Tartib har guruh ichida alohida.
      </div>
    </div>
  );
}
