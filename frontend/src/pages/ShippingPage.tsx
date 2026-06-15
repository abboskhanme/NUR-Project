import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Plus, Trash2, Truck } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatUZS, formatDate, formatNumberInput, parseNumberInput, formatPhoneInput, formatCardInput } from '@/lib/format';

export interface Shipment {
  id: string;
  date?: string | null;
  qty: number;
  destination?: string | null;
  kvm?: number | null;
  direction?: string | null;
  driver_phone?: string | null;
  freight?: string | number | null;
  kimdan?: string | null;
  card_number?: string | null;
  card_holder?: string | null;
  paid?: string | null;
  pause?: string | null;
  reason?: string | null;
  order_id?: string | null;
}

type ColType = 'date' | 'int' | 'money' | 'text';
// lock: avtomatik (buyurtmadan) yaratilgan qatorlarda bu ustun tahrirlanmaydi
// fmt: matnni yozilayotganda formatlash (telefon, karta raqami)
interface Col {
  key: keyof Shipment; label: string; type: ColType; w: string;
  align?: string; lock?: boolean; fmt?: (s: string | number | null | undefined) => string;
}

const COLS: Col[] = [
  { key: 'date', label: 'colDate', type: 'date', w: 'w-32', lock: true },
  { key: 'qty', label: 'colQty', type: 'int', w: 'w-14', align: 'text-right', lock: true },
  { key: 'destination', label: 'colDestination', type: 'text', w: 'w-44', lock: true },
  { key: 'kvm', label: 'colKvm', type: 'int', w: 'w-16', align: 'text-right', lock: true },
  { key: 'direction', label: 'colDirection', type: 'text', w: 'w-24', lock: true },
  { key: 'driver_phone', label: 'colDriverPhone', type: 'text', w: 'w-32', fmt: formatPhoneInput },
  { key: 'freight', label: 'colFreight', type: 'money', w: 'w-28', align: 'text-right' },
  { key: 'kimdan', label: 'colKimdan', type: 'text', w: 'w-16' },
  { key: 'card_number', label: 'colCardNumber', type: 'text', w: 'w-40', fmt: formatCardInput },
  { key: 'card_holder', label: 'colCardHolder', type: 'text', w: 'w-36' },
  { key: 'paid', label: 'colPaid', type: 'text', w: 'w-32' },
  { key: 'pause', label: 'colPause', type: 'text', w: 'w-20' },
  { key: 'reason', label: 'colReason', type: 'text', w: 'w-44' },
];

const INP = 'w-full bg-transparent outline-none px-2 py-1.5 text-sm rounded focus:bg-primary/5 focus:ring-1 focus:ring-primary/30';

export default function ShippingPage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1); // 0 = butun yil
  const [delRow, setDelRow] = useState<Shipment | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [adding, setAdding] = useState(false);

  const yearOptions = [now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2];

  const listQ = useQuery<Shipment[]>({
    queryKey: ['shipments', year, month],
    queryFn: () => api.get('/shipping', {
      params: { year, month: month || undefined },
    }).then((r) => r.data),
  });
  const rows = listQ.data ?? [];
  const totalFreight = rows.reduce((a, s) => a + Number(s.freight || 0), 0);

  const refresh = () => qc.invalidateQueries({ queryKey: ['shipments'] });

  async function addRow() {
    setAdding(true);
    try {
      // Yangi bo'sh qator — tanlangan oyning bugungi/1-sanasi bilan
      const d = new Date();
      const useY = year, useM = month || (d.getMonth() + 1);
      const day = (useY === d.getFullYear() && useM === d.getMonth() + 1) ? d.getDate() : 1;
      const iso = `${useY}-${String(useM).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      await api.post('/shipping', { date: iso, qty: 1 });
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setAdding(false);
    }
  }

  async function confirmDelete() {
    if (!delRow) return;
    setDeleting(true);
    try {
      await api.delete(`/shipping/${delRow.id}`);
      toast.success(t('shipping.deleted'));
      setDelRow(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2"><Truck size={22} /> {t('shipping.title')}</h1>
          <p className="text-sm text-ink-soft">{t('shipping.subtitle')}</p>
        </div>
        <button className="btn-primary" onClick={addRow} disabled={adding}>
          <Plus size={16} /> {t('shipping.addRow')}
        </button>
      </div>

      {/* Filter + jami */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <select className="input !w-auto" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
            <option value={0}>{t('shipping.allMonths')}</option>
            {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
              <option key={m} value={m}>{t(`shipping.months.${m}`)}</option>
            ))}
          </select>
          <select className="input !w-auto" value={year} onChange={(e) => setYear(Number(e.target.value))}>
            {yearOptions.map((y) => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>
        <div className="text-sm text-ink-soft">
          {t('shipping.count', { n: rows.length })} · {t('shipping.totalFreight')}:{' '}
          <span className="font-semibold text-ink">{formatUZS(totalFreight)}</span>
        </div>
      </div>

      <Card>
        {listQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-9 rounded bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : rows.length === 0 ? (
          <EmptyState title={t('shipping.empty')} description={t('shipping.emptyDesc')} />
        ) : (
          <div className="overflow-x-auto -mx-2">
            <table className="text-sm border-collapse" style={{ minWidth: 1500 }}>
              <thead className="text-left text-ink-soft border-b border-black/10">
                <tr className="[&>th]:py-2 [&>th]:px-2 [&>th]:font-medium [&>th]:whitespace-nowrap">
                  {COLS.map((c) => (
                    <th key={c.key} className={`${c.w} ${c.align ?? ''}`}>{t(`shipping.${c.label}`)}</th>
                  ))}
                  <th className="w-10" />
                </tr>
              </thead>
              <tbody>
                {rows.map((s) => (
                  <Row key={s.id} s={s} onChanged={refresh} onDelete={setDelRow} />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <ConfirmModal
        open={!!delRow}
        title={t('shipping.deleteTitle')}
        message={t('shipping.deleteConfirm')}
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setDelRow(null)}
      />
    </div>
  );
}

function Row({ s, onChanged, onDelete }: {
  s: Shipment; onChanged: () => void; onDelete: (s: Shipment) => void;
}) {
  const { t } = useTranslation();

  async function patchField(c: Col, raw: string) {
    const old = s[c.key];
    let value: string | number | null;
    if (c.type === 'money') value = raw.trim() ? parseNumberInput(raw) : null;
    else if (c.type === 'int') { const n = parseInt(raw.replace(/\D/g, ''), 10); value = Number.isNaN(n) ? null : n; }
    else value = raw.trim() || null;

    const changed = (c.type === 'money' || c.type === 'int')
      ? Number(value ?? 0) !== Number((old as number) ?? 0)
      : (value ?? null) !== ((old as string) ?? null);
    if (!changed) return;
    try {
      await api.patch(`/shipping/${s.id}`, { [c.key]: value });
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    }
  }

  // Buyurtmadan avtomatik tushgan qator — mahsulot/buyurtma ustunlari tahrirlanmaydi
  const fromOrder = !!s.order_id;

  function readonlyText(c: Col, v: unknown): string {
    if (v == null || v === '') return '—';
    if (c.type === 'date') return formatDate(v as string);
    if (c.type === 'money') return formatUZS(Number(v));
    return String(v);
  }

  return (
    <tr className="border-b border-black/5 hover:bg-black/[0.015] group">
      {COLS.map((c) => {
        const v = s[c.key];
        // Avtomatik qatorda mahsulot ma'lumotini faqat ko'rsatamiz (tahrirlab bo'lmaydi)
        if (fromOrder && c.lock) {
          return (
            <td key={c.key} className={c.w}>
              <span className={`block px-2 py-1.5 text-sm text-ink-soft bg-black/[0.03] rounded ${c.align ?? ''}`}
                    title={t('shipping.lockedHint')}>
                {readonlyText(c, v)}
              </span>
            </td>
          );
        }
        if (c.type === 'date') {
          return (
            <td key={c.key} className={c.w}>
              <input type="date" defaultValue={(v as string) ?? ''} key={String(v ?? '')}
                     className={INP} onBlur={(e) => patchField(c, e.target.value)} />
            </td>
          );
        }
        if (c.type === 'money') {
          const disp = v != null && v !== '' ? formatNumberInput(String(Math.round(Number(v)))) : '';
          return (
            <td key={c.key} className={c.w}>
              <input inputMode="decimal" defaultValue={disp} key={String(v ?? '')}
                     className={`${INP} text-right`}
                     onChange={(e) => { e.target.value = formatNumberInput(e.target.value); }}
                     onBlur={(e) => patchField(c, e.target.value)} />
            </td>
          );
        }
        return (
          <td key={c.key} className={c.w}>
            <input defaultValue={c.fmt ? c.fmt(v as string) : ((v as string | number) ?? '')} key={String(v ?? '')}
                   className={`${INP} ${c.align ?? ''}`}
                   inputMode={c.type === 'int' || c.fmt ? 'numeric' : undefined}
                   onChange={c.fmt ? (e) => { e.target.value = c.fmt!(e.target.value); } : undefined}
                   onBlur={(e) => patchField(c, e.target.value)} />
          </td>
        );
      })}
      <td className="w-10">
        <button onClick={() => onDelete(s)}
                className="p-1 rounded text-ink-soft/40 hover:text-danger hover:bg-danger/10 opacity-0 group-hover:opacity-100 transition">
          <Trash2 size={14} />
        </button>
      </td>
    </tr>
  );
}
