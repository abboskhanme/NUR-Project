import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { ClipboardList, Check, Trash2, ChevronDown, ChevronUp } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { cn } from '@/lib/cn';
import { formatDate } from '@/lib/format';

interface ListItem {
  id: string; product_id: string; product_name: string; unit: string;
  qty: number; unit_price: number; currency: string; amount: number;
}
interface PurchaseList {
  id: string; scope: string; title?: string | null; status: string;
  note?: string | null; applied_at?: string | null; created_at: string;
  items: ListItem[]; totals: { currency: string; amount: number }[]; item_count: number;
}

const fmt = (v: number, currency: string) =>
  currency === 'USD'
    ? `$${Number(v).toLocaleString('en-US', { maximumFractionDigits: 2 })}`
    : `${Math.round(Number(v)).toLocaleString('ru-RU').replace(/ /g, ' ')} so'm`;

/**
 * Xarid spiskalari. Qoralama (draft) — faqat reja; «Qabul qilish» bosilganda
 * har bir qator uchun olib kelish tranzaksiyasi yaratiladi va shundagina
 * ombor qoldig'i hamda qarz hisoblanadi.
 */
export default function TaminotListsPanel({ scope, canWrite, canDelete }: {
  scope: string; canWrite: boolean; canDelete: boolean;
}) {
  const qc = useQueryClient();
  const [open, setOpen] = useState<string | null>(null);
  const [applying, setApplying] = useState<PurchaseList | null>(null);
  const [deleting, setDeleting] = useState<PurchaseList | null>(null);
  const [busy, setBusy] = useState(false);

  const q = useQuery<PurchaseList[]>({
    queryKey: ['taminot-lists', scope],
    queryFn: () => api.get('/taminot/lists', { params: { scope } }).then((r) => r.data),
  });
  // Faqat QORALAMA spiskalar ko'rsatiladi — ular ustida ish qilinadi.
  // Qabul qilinganlarning natijasi ombor qoldig'i va tranzaksiyalarda ko'rinadi.
  const lists = (q.data ?? []).filter((l) => l.status === 'draft');

  function refresh() {
    qc.invalidateQueries({ queryKey: ['taminot-lists'] });
    qc.invalidateQueries({ queryKey: ['taminot-products'] });
    qc.invalidateQueries({ queryKey: ['taminot-summary'] });
  }

  async function doApply() {
    if (!applying) return;
    setBusy(true);
    try {
      await api.post(`/taminot/lists/${applying.id}/apply`);
      toast.success('Qabul qilindi — ombor qoldig‘i yangilandi');
      setApplying(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally { setBusy(false); }
  }

  async function doDelete() {
    if (!deleting) return;
    setBusy(true);
    try {
      await api.delete(`/taminot/lists/${deleting.id}`);
      toast.success("O'chirildi");
      setDeleting(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally { setBusy(false); }
  }

  // Qoralama yo'q bo'lsa panel umuman chizilmaydi
  if (q.isLoading || !lists.length) return null;

  return (
    <div className="space-y-3">
      <div className="text-sm font-medium text-ink-soft">
        Qoralama spiskalar ({lists.length})
      </div>
      {lists.map((pl) => {
        const isDraft = pl.status === 'draft';
        const expanded = open === pl.id;
        return (
          <Card key={pl.id}>
            <div className="flex items-start justify-between gap-3 flex-wrap">
              <button onClick={() => setOpen(expanded ? null : pl.id)}
                      className="flex items-start gap-2 min-w-0 text-left flex-1">
                <ClipboardList size={18} className="text-primary shrink-0 mt-0.5" />
                <div className="min-w-0">
                  <div className="font-medium flex items-center gap-2 flex-wrap">
                    <span className="truncate">{pl.title || 'Spiska'}</span>
                    <span className={cn('badge whitespace-nowrap',
                      isDraft ? 'bg-warning/10 text-warning' : 'bg-success/10 text-success')}>
                      {isDraft ? 'Qoralama' : 'Qabul qilingan'}
                    </span>
                  </div>
                  <div className="text-xs text-ink-soft">
                    {formatDate(pl.created_at)} · {pl.item_count} ta mahsulot
                    {pl.note ? ` · ${pl.note}` : ''}
                  </div>
                </div>
                {expanded ? <ChevronUp size={16} className="shrink-0 text-ink-soft mt-1" />
                          : <ChevronDown size={16} className="shrink-0 text-ink-soft mt-1" />}
              </button>

              <div className="flex items-center gap-2 flex-wrap">
                <div className="text-right">
                  {pl.totals.map((t) => (
                    <div key={t.currency} className="font-bold tabular-nums whitespace-nowrap">
                      {fmt(t.amount, t.currency)}
                    </div>
                  ))}
                </div>
                {isDraft && canWrite && (
                  <button onClick={() => setApplying(pl)}
                          className="px-3 py-1.5 text-sm rounded-button bg-success/10 text-success hover:bg-success/20 inline-flex items-center gap-1.5">
                    <Check size={15} /> Qabul qilish
                  </button>
                )}
                {isDraft && canDelete && (
                  <button onClick={() => setDeleting(pl)}
                          className="p-2 rounded-button text-danger hover:bg-danger/10">
                    <Trash2 size={15} />
                  </button>
                )}
              </div>
            </div>

            {expanded && (
              <div className="mt-3 border-t border-black/5 pt-3 overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="text-left text-ink-soft border-b border-black/5">
                    <tr>
                      <th className="py-1.5 pr-3">Mahsulot</th>
                      <th className="py-1.5 pr-3 text-right">Miqdor</th>
                      <th className="py-1.5 pr-3 text-right">Narx</th>
                      <th className="py-1.5 text-right">Summa</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pl.items.map((it) => (
                      <tr key={it.id} className="border-b border-black/5 last:border-0">
                        <td className="py-1.5 pr-3">{it.product_name}</td>
                        <td className="py-1.5 pr-3 text-right whitespace-nowrap">
                          {Number(it.qty)} {it.unit}
                        </td>
                        <td className="py-1.5 pr-3 text-right whitespace-nowrap text-ink-soft">
                          {fmt(it.unit_price, it.currency)}
                        </td>
                        <td className="py-1.5 text-right whitespace-nowrap font-medium">
                          {fmt(it.amount, it.currency)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Card>
        );
      })}

      {applying && (
        <ConfirmModal
          open
          title="Spiskani qabul qilish"
          variant="primary"
          loading={busy}
          message={
            `«${applying.title || 'Spiska'}» bo'yicha ${applying.item_count} ta mahsulot `
            + 'omborga kiritiladi va qarz hisoblanadi ('
            + applying.totals.map((t) => fmt(t.amount, t.currency)).join(' + ')
            + '). Bu amalni orqaga qaytarib bo‘lmaydi.'
          }
          confirmText="Qabul qilish"
          onConfirm={doApply}
          onCancel={() => setApplying(null)}
        />
      )}
      {deleting && (
        <ConfirmModal
          open
          title="Spiskani o‘chirish"
          loading={busy}
          message={`«${deleting.title || 'Spiska'}» o‘chiriladi. Qoralama bo‘lgani uchun hech qanday hisobga ta’sir qilmaydi.`}
          confirmText="O'chirish"
          onConfirm={doDelete}
          onCancel={() => setDeleting(null)}
        />
      )}
    </div>
  );
}
