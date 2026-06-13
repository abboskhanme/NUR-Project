import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ShoppingCart, ChevronDown, ChevronUp, Truck } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';

interface Suggestion {
  id: string;
  name: string;
  unit: string;
  vendor: string | null;
  stock_qty: number;
  min_qty: number;
  suggested_qty: number;
  unit_price: number;
  estimated_cost: number;
}
interface ReorderData { count: number; total_cost_uzs: number; items: Suggestion[] }

/**
 * Zaxirasi kam mahsulotlar uchun buyurtma tavsiyalari.
 * Faqat tavsiya bo'lganda ko'rinadi — sahifa joylashuvini o'zgartirmaydi.
 * @param vendorId — tanlangan taminotchiga qarab keshni yangilash uchun
 */
export default function ReorderSuggestions({ vendorId }: { vendorId?: string }) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(true);

  const { data } = useQuery<ReorderData>({
    queryKey: ['supply-reorder', vendorId],
    queryFn: () => api.get('/supply/reorder-suggestions').then((r) => r.data),
  });

  if (!data || data.count === 0) return null;

  const fmtQty = (n: number, unit: string) => `${(+n.toFixed(2)).toLocaleString('ru-RU')} ${unit}`;

  return (
    <Card
      title={
        <span className="inline-flex items-center gap-2 text-warning">
          <ShoppingCart size={17} /> {t('supply.reorder.title')}
          <span className="badge bg-warning/10 text-warning">{data.count}</span>
        </span>
      }
      action={
        <div className="flex items-center gap-3">
          <span className="text-sm font-semibold text-ink">
            {t('supply.reorder.totalCost')}: {formatUZS(data.total_cost_uzs)}
          </span>
          <button onClick={() => setOpen((o) => !o)} className="p-1 rounded hover:bg-black/5 text-ink/50">
            {open ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </button>
        </div>
      }
    >
      {open && (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/10">
              <tr>
                <th className="py-2 pr-3">{t('supply.reorder.colName')}</th>
                <th className="py-2 pr-3">{t('supply.reorder.colVendor')}</th>
                <th className="py-2 pr-3 text-right">{t('supply.reorder.colStock')}</th>
                <th className="py-2 pr-3 text-right">{t('supply.reorder.colMin')}</th>
                <th className="py-2 pr-3 text-right">{t('supply.reorder.colSuggested')}</th>
                <th className="py-2 pr-3 text-right">{t('supply.reorder.colCost')}</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((it) => (
                <tr key={it.id} className="border-b border-black/5">
                  <td className="py-2 pr-3 font-medium">{it.name}</td>
                  <td className="py-2 pr-3 text-ink-soft">
                    {it.vendor ? (
                      <span className="inline-flex items-center gap-1.5"><Truck size={13} className="text-ink/40" /> {it.vendor}</span>
                    ) : '—'}
                  </td>
                  <td className="py-2 pr-3 text-right text-danger">{fmtQty(it.stock_qty, it.unit)}</td>
                  <td className="py-2 pr-3 text-right text-ink-soft">{fmtQty(it.min_qty, it.unit)}</td>
                  <td className="py-2 pr-3 text-right font-semibold text-primary">{fmtQty(it.suggested_qty, it.unit)}</td>
                  <td className="py-2 pr-3 text-right">{formatUZS(it.estimated_cost)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
