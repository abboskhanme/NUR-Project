import { useNavigate } from 'react-router-dom';

import StatusBadge from '@/components/ui/StatusBadge';
import { formatDate } from '@/lib/format';
import type { RecentOrder } from './types';

export default function RecentOrdersList({ orders }: { orders?: RecentOrder[] }) {
  const navigate = useNavigate();

  if (!orders) {
    return <div className="text-sm text-ink-soft py-4">Yuklanmoqda…</div>;
  }
  if (orders.length === 0) {
    return <div className="text-sm text-ink-soft py-4">— hozircha bo'sh —</div>;
  }

  return (
    <div className="divide-y divide-black/5">
      {orders.map((o) => (
        <button
          key={o.id}
          onClick={() => navigate(`/orders/${o.id}`)}
          className="w-full flex items-center justify-between gap-3 py-2.5 text-left hover:bg-primary/5 -mx-2 px-2 rounded-button transition"
        >
          <div className="min-w-0">
            <div className="font-medium text-sm truncate">{o.code}</div>
            <div className="text-xs text-ink-soft truncate">{o.customer}</div>
          </div>
          <div className="flex items-center gap-3 shrink-0">
            <span className="text-xs text-ink-soft">{formatDate(o.order_date)}</span>
            <StatusBadge status={o.status} />
          </div>
        </button>
      ))}
    </div>
  );
}
