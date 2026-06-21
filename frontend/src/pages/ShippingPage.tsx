import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import {
  Plus, Trash2, Truck, BarChart3, ClipboardList, Package, Coins,
} from 'lucide-react';
import {
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, Cell,
} from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { CENTRAL_ASIA, regionsOf } from '@/lib/centralAsia';
import {
  formatUZS, formatNumberInput, parseNumberInput, formatPhoneInput, formatCardInput,
} from '@/lib/format';

export interface Shipment {
  id: string;
  date?: string | null;
  qty: number;
  country?: string | null;
  region?: string | null;
  destination?: string | null;
  kvm?: number | null;
  direction?: string | null;
  product_name?: string | null;
  product_price?: string | number | null;
  driver_name?: string | null;
  driver_phone?: string | null;
  freight?: string | number | null;
  card_number?: string | null;
  card_holder?: string | null;
  reason?: string | null;
}

interface Driver { name: string; phone?: string | null; }
interface ShipProduct { name: string; price_usd: string | number; }

type ColType = 'date' | 'int' | 'money' | 'text' | 'country' | 'region' | 'direction' | 'driver' | 'product';
interface Col {
  key: keyof Shipment; label: string; type: ColType; px: number;
  align?: string; fmt?: (s: string | number | null | undefined) => string;
}

// Ustunlar mantiqiy guruhlarga bo'lingan (sarlavhada rangli ajratiladi).
const COLS: Col[] = [
  { key: 'date', label: 'colDate', type: 'date', px: 124 },
  { key: 'qty', label: 'colQty', type: 'int', px: 58 },
  { key: 'country', label: 'colCountry', type: 'country', px: 132 },
  { key: 'region', label: 'colRegion', type: 'region', px: 144 },
  { key: 'destination', label: 'colDestination', type: 'text', px: 188 },
  { key: 'product_name', label: 'colProduct', type: 'product', px: 180 },
  { key: 'direction', label: 'colDirection', type: 'direction', px: 104 },
  { key: 'driver_name', label: 'colDriverName', type: 'driver', px: 160 },
  { key: 'driver_phone', label: 'colDriverPhone', type: 'text', px: 152, fmt: formatPhoneInput },
  { key: 'freight', label: 'colFreight', type: 'money', px: 124 },
  { key: 'card_number', label: 'colCardNumber', type: 'text', px: 182, fmt: formatCardInput },
  { key: 'card_holder', label: 'colCardHolder', type: 'text', px: 162 },
  { key: 'reason', label: 'colReason', type: 'text', px: 220 },
];

// Sarlavha guruhlari (span — ketma-ket ustunlar soni; COLS tartibiga mos).
const GROUP_DEFS = [
  { key: 'grpCargo', span: 7, text: 'text-accent', border: 'border-accent' },
  { key: 'grpDriver', span: 2, text: 'text-warning', border: 'border-warning' },
  { key: 'grpPayment', span: 3, text: 'text-success', border: 'border-success' },
  { key: 'grpStatus', span: 1, text: 'text-danger', border: 'border-danger' },
];

const DIR_VALUES = ['right', 'left'] as const;
const DRIVER_LIST_ID = 'ship-drivers';
const INP = 'w-full bg-transparent outline-none px-2 py-1.5 text-sm rounded placeholder:text-ink-soft/40 focus:bg-accent/5 focus:ring-1 focus:ring-accent/40';
const SEL = 'w-full bg-transparent outline-none px-1.5 py-1.5 text-sm rounded cursor-pointer hover:bg-black/[0.03] focus:bg-accent/5 focus:ring-1 focus:ring-accent/40';

type Tab = 'journal' | 'stats';

export default function ShippingPage() {
  const { t } = useTranslation();
  const [tab, setTab] = useState<Tab>('journal');

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3">
        <div className="w-11 h-11 rounded-card bg-accent/10 text-accent flex items-center justify-center shrink-0">
          <Truck size={22} />
        </div>
        <div>
          <h1 className="text-2xl font-bold">{t('shipping.title')}</h1>
          <p className="text-sm text-ink-soft">{t('shipping.subtitle')}</p>
        </div>
      </div>

      <div className="flex gap-1 border-b border-black/5 overflow-x-auto">
        <TabBtn active={tab === 'journal'} onClick={() => setTab('journal')} icon={<ClipboardList size={16} />}>
          {t('shipping.tabJournal')}
        </TabBtn>
        <TabBtn active={tab === 'stats'} onClick={() => setTab('stats')} icon={<BarChart3 size={16} />}>
          {t('shipping.tabStats')}
        </TabBtn>
      </div>

      {tab === 'journal' ? <Journal /> : <Stats />}
    </div>
  );
}

function TabBtn({ active, onClick, icon, children }: {
  active: boolean; onClick: () => void; icon: React.ReactNode; children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-2 px-4 py-2 text-sm font-medium border-b-2 -mb-px whitespace-nowrap transition ${
        active ? 'border-accent text-accent' : 'border-transparent text-ink-soft hover:text-ink'
      }`}
    >
      {icon} {children}
    </button>
  );
}

/* ─────────────────────────── JURNAL ─────────────────────────── */

function Journal() {
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
    queryFn: () => api.get('/shipping', { params: { year, month: month || undefined } }).then((r) => r.data),
  });
  // Avtomatik to'ldirish uchun ilgari ishlatilgan shofyorlar
  const driversQ = useQuery<Driver[]>({
    queryKey: ['shipment-drivers'],
    queryFn: () => api.get('/shipping/drivers').then((r) => r.data),
  });
  const drivers = driversQ.data ?? [];

  // "Mahsulotlar" menyusidagi mahsulotlar (narxi USD'da) + joriy USD→UZS kurs
  const productsQ = useQuery<ShipProduct[]>({
    queryKey: ['shipment-products'],
    queryFn: () => api.get('/shipping/products').then((r) => r.data),
  });
  const products = productsQ.data ?? [];
  const rateQ = useQuery<number>({
    queryKey: ['usd-rate'],
    queryFn: () => api.get('/finance/exchange-rates/latest').then((r) => Number(r.data?.usd_to_uzs) || 0),
  });
  const rate = rateQ.data ?? 0;

  const rows = listQ.data ?? [];
  const totalFreight = rows.reduce((a, s) => a + Number(s.freight || 0), 0);
  const totalQty = rows.reduce((a, s) => a + Number(s.qty || 0), 0);

  const refresh = () => {
    qc.invalidateQueries({ queryKey: ['shipments'] });
    qc.invalidateQueries({ queryKey: ['shipment-drivers'] });
  };

  async function addRow() {
    setAdding(true);
    try {
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

  const tableWidth = COLS.reduce((a, c) => a + c.px, 44);

  return (
    <div className="space-y-4">
      {/* KPI chiplar */}
      <div className="grid grid-cols-2 gap-3">
        <Kpi icon={<Package size={16} />} label={t('shipping.colQty')} value={formatNumberInput(String(totalQty))} tone="warning" />
        <Kpi icon={<Coins size={16} />} label={t('shipping.totalFreight')} value={formatUZS(totalFreight)} tone="success" />
      </div>

      {/* Filter + qo'shish */}
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
        <button className="btn-primary" onClick={addRow} disabled={adding}>
          <Plus size={16} /> {t('shipping.addRow')}
        </button>
      </div>

      {/* Shofyor ismlari — avtomatik to'ldirish ro'yxati */}
      <datalist id={DRIVER_LIST_ID}>
        {drivers.map((d) => <option key={d.name} value={d.name} />)}
      </datalist>

      <Card className="!p-0 overflow-hidden">
        {listQ.isLoading ? (
          <div className="space-y-2 p-4">
            {Array.from({ length: 6 }).map((_, i) => <div key={i} className="h-9 rounded bg-black/5 animate-pulse" />)}
          </div>
        ) : rows.length === 0 ? (
          <div className="p-6"><EmptyState title={t('shipping.empty')} description={t('shipping.emptyDesc')} /></div>
        ) : (
          <div className="overflow-auto max-h-[72vh]">
            <table className="text-sm border-collapse table-fixed" style={{ width: tableWidth }}>
              <colgroup>
                {COLS.map((c) => <col key={c.key} style={{ width: c.px }} />)}
                <col style={{ width: 44 }} />
              </colgroup>
              <thead>
                <tr className="sticky top-0 z-20">
                  {GROUP_DEFS.map((g) => (
                    <th key={g.key} colSpan={g.span}
                        className={`h-9 px-2 text-left text-[11px] font-bold uppercase tracking-wider bg-primary-50 border-b-2 ${g.border} ${g.text}`}>
                      {t(`shipping.${g.key}`)}
                    </th>
                  ))}
                  <th className="bg-primary-50 border-b-2 border-black/10" />
                </tr>
                <tr className="sticky top-9 z-20">
                  {COLS.map((c) => (
                    <th key={c.key}
                        className={`h-8 px-2 font-semibold text-[11px] uppercase tracking-wide text-ink-soft bg-bg border-b border-black/10 border-r border-black/5 whitespace-nowrap ${c.align ?? 'text-left'}`}>
                      {t(`shipping.${c.label}`)}
                    </th>
                  ))}
                  <th className="bg-bg border-b border-black/10" />
                </tr>
              </thead>
              <tbody>
                {rows.map((s, i) => (
                  <Row key={s.id} s={s} zebra={i % 2 === 1} drivers={drivers} products={products} rate={rate}
                       onChanged={refresh} onDelete={setDelRow} />
                ))}
              </tbody>
              <tfoot>
                <tr className="sticky bottom-0 z-10 font-bold bg-primary-50 [&>td]:py-2 [&>td]:px-2 [&>td]:border-t-2 [&>td]:border-black/10">
                  <td>{t('shipping.total')}</td>
                  <td className="tabular-nums">{formatNumberInput(String(totalQty))}</td>
                  <td colSpan={3} />
                  <td />
                  <td />
                  <td colSpan={2} />
                  <td className="tabular-nums text-success">{formatUZS(totalFreight)}</td>
                  <td colSpan={4} />
                </tr>
              </tfoot>
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

const TONE: Record<string, string> = {
  accent: 'bg-accent/10 text-accent',
  warning: 'bg-warning/10 text-warning',
  success: 'bg-success/10 text-success',
  ink: 'bg-ink/5 text-ink',
};

function Kpi({ icon, label, value, tone }: { icon: React.ReactNode; label: string; value: string; tone: string }) {
  return (
    <div className="rounded-card border border-black/5 bg-card p-3 flex items-center gap-3">
      <div className={`w-9 h-9 rounded-button flex items-center justify-center shrink-0 ${TONE[tone]}`}>{icon}</div>
      <div className="min-w-0">
        <div className="text-xs text-ink-soft truncate">{label}</div>
        <div className="text-lg font-bold tabular-nums leading-tight truncate">{value}</div>
      </div>
    </div>
  );
}

function Row({ s, zebra, drivers, products, rate, onChanged, onDelete }: {
  s: Shipment; zebra: boolean; drivers: Driver[]; products: ShipProduct[]; rate: number;
  onChanged: () => void; onDelete: (s: Shipment) => void;
}) {
  const { t } = useTranslation();
  const td = 'align-middle border-r border-black/5';

  async function patch(body: Record<string, unknown>) {
    try {
      await api.patch(`/shipping/${s.id}`, body);
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    }
  }

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
    await patch({ [c.key]: value });
  }

  async function patchCountry(val: string) {
    const body: Record<string, unknown> = { country: val || null };
    if (s.region && !regionsOf(val).includes(s.region)) body.region = null;
    await patch(body);
  }

  // Mahsulot tanlansa — nomini saqlaymiz va narxini avtomatik to'ldiramiz (USD × kurs = UZS)
  async function patchProduct(name: string) {
    const body: Record<string, unknown> = { product_name: name || null };
    if (name) {
      const prod = products.find((p) => p.name === name);
      if (prod && rate > 0) body.product_price = Math.round(Number(prod.price_usd) * rate);
    }
    await patch(body);
  }

  // Shofyor ismi: o'zgartirsa saqlaymiz; tanish shofyor bo'lsa va tel bo'sh bo'lsa — to'ldiramiz
  async function patchDriver(raw: string) {
    const val = raw.trim() || null;
    const body: Record<string, unknown> = {};
    if ((val ?? null) !== (s.driver_name ?? null)) body.driver_name = val;
    if (val && !s.driver_phone) {
      const found = drivers.find((d) => d.name === val);
      if (found?.phone) body.driver_phone = found.phone;
    }
    if (Object.keys(body).length) await patch(body);
  }

  return (
    <tr className={`border-b border-black/5 hover:bg-accent/[0.04] transition-colors group ${zebra ? 'bg-black/[0.015]' : ''}`}>
      {COLS.map((c) => {
        const v = s[c.key];

        if (c.type === 'country') {
          return (
            <td key={c.key} className={td}>
              <select className={SEL} value={(v as string) ?? ''} onChange={(e) => patchCountry(e.target.value)}>
                <option value="">—</option>
                {CENTRAL_ASIA.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </td>
          );
        }
        if (c.type === 'region') {
          const regions = regionsOf((s.country as string) ?? '');
          return (
            <td key={c.key} className={td}>
              <select className={SEL} value={(v as string) ?? ''} disabled={!s.country}
                      onChange={(e) => patchField(c, e.target.value)}>
                <option value="">—</option>
                {v && !regions.includes(v as string) && <option value={v as string}>{v as string}</option>}
                {regions.map((r) => <option key={r} value={r}>{r}</option>)}
              </select>
            </td>
          );
        }
        if (c.type === 'direction') {
          const cur = (v as string) ?? '';
          const known = (DIR_VALUES as readonly string[]).includes(cur);
          return (
            <td key={c.key} className={td}>
              <select className={SEL} value={cur} onChange={(e) => patchField(c, e.target.value)}>
                <option value="">—</option>
                {!known && cur && <option value={cur}>{cur}</option>}
                {DIR_VALUES.map((d) => <option key={d} value={d}>{t(`shipping.dir.${d}`)}</option>)}
              </select>
            </td>
          );
        }
        if (c.type === 'driver') {
          return (
            <td key={c.key} className={td}>
              <input defaultValue={(v as string) ?? ''} key={String(v ?? '')} list={DRIVER_LIST_ID}
                     className={INP} placeholder="—" onBlur={(e) => patchDriver(e.target.value)} />
            </td>
          );
        }
        if (c.type === 'product') {
          const cur = (v as string) ?? '';
          const known = products.some((p) => p.name === cur);
          return (
            <td key={c.key} className={td}>
              <select className={SEL} value={cur} onChange={(e) => patchProduct(e.target.value)}>
                <option value="">—</option>
                {!known && cur && <option value={cur}>{cur}</option>}
                {products.map((p) => <option key={p.name} value={p.name}>{p.name}</option>)}
              </select>
            </td>
          );
        }
        if (c.type === 'date') {
          return (
            <td key={c.key} className={td}>
              <input type="date" defaultValue={(v as string) ?? ''} key={String(v ?? '')}
                     className={INP} onBlur={(e) => patchField(c, e.target.value)} />
            </td>
          );
        }
        if (c.type === 'money') {
          const disp = v != null && v !== '' ? formatNumberInput(String(Math.round(Number(v)))) : '';
          return (
            <td key={c.key} className={td}>
              <input inputMode="decimal" defaultValue={disp} key={String(v ?? '')}
                     className={INP} placeholder="—"
                     onChange={(e) => { e.target.value = formatNumberInput(e.target.value); }}
                     onBlur={(e) => patchField(c, e.target.value)} />
            </td>
          );
        }
        return (
          <td key={c.key} className={td}>
            <input defaultValue={c.fmt ? c.fmt(v as string) : ((v as string | number) ?? '')} key={String(v ?? '')}
                   className={`${INP} ${c.align ?? ''}`} placeholder="—"
                   inputMode={c.type === 'int' || c.fmt ? 'numeric' : undefined}
                   onChange={c.fmt ? (e) => { e.target.value = c.fmt!(e.target.value); } : undefined}
                   onBlur={(e) => patchField(c, e.target.value)} />
          </td>
        );
      })}
      <td className="text-center align-middle">
        <button onClick={() => onDelete(s)}
                className="p-1 rounded text-ink-soft/40 hover:text-danger hover:bg-danger/10 opacity-0 group-hover:opacity-100 transition">
          <Trash2 size={14} />
        </button>
      </td>
    </tr>
  );
}

/* ─────────────────────────── STATISTIKA ─────────────────────────── */

type GroupBy = 'region' | 'country' | 'direction' | 'driver' | 'month' | 'year';
type Metric = 'freight' | 'count' | 'qty';

interface StatRow { key: string; count: number; qty: number; kvm: number; freight: string; }
interface StatsResp { group_by: string; total: StatRow; rows: StatRow[]; }

const GROUPS: { v: GroupBy; label: string }[] = [
  { v: 'region', label: 'gbRegion' },
  { v: 'country', label: 'gbCountry' },
  { v: 'direction', label: 'gbDirection' },
  { v: 'driver', label: 'gbDriver' },
  { v: 'month', label: 'gbMonth' },
  { v: 'year', label: 'gbYear' },
];
const METRICS: { v: Metric; key: string }[] = [
  { v: 'freight', key: 'shipping.colFreight' },
  { v: 'count', key: 'shipping.stats.count' },
  { v: 'qty', key: 'shipping.colQty' },
];
const BAR_COLORS = ['#2980B9', '#27AE60', '#F39C12', '#E74C3C', '#1E3A5F', '#8E44AD', '#16A085', '#D35400'];

function Stats() {
  const { t } = useTranslation();
  const now = new Date();
  const [groupBy, setGroupBy] = useState<GroupBy>('region');
  const [metric, setMetric] = useState<Metric>('freight');
  const [useRange, setUseRange] = useState(false);
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(0); // 0 = butun yil
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  const yearOptions = [now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2];

  const params: Record<string, unknown> = { group_by: groupBy };
  if (useRange) { if (from) params.date_from = from; if (to) params.date_to = to; }
  else { params.year = year; if (month) params.month = month; }

  const q = useQuery<StatsResp>({
    queryKey: ['shipment-stats', groupBy, useRange, year, month, from, to],
    queryFn: () => api.get('/shipping/stats', { params }).then((r) => r.data),
  });
  const data = q.data;

  function keyLabel(key: string): string {
    if (key === '—' || key === '') return t('shipping.stats.none');
    if (groupBy === 'month') return t(`shipping.months.${key}`);
    if (groupBy === 'country') return CENTRAL_ASIA.find((c) => c.value === key)?.label ?? key;
    if (groupBy === 'direction') return (key === 'right' || key === 'left') ? t(`shipping.dir.${key}`) : key;
    return key;
  }
  const grp = (n: number) => formatNumberInput(String(n || 0));
  const metricVal = (r: StatRow): number =>
    metric === 'freight' ? Number(r.freight) : metric === 'count' ? r.count : r.qty;
  const fmtMetric = (n: number) => (metric === 'freight' ? formatUZS(n) : grp(n));

  const chartData = (data?.rows ?? [])
    .map((r) => ({ name: keyLabel(r.key), value: metricVal(r) }))
    .filter((d) => d.value > 0)
    .sort((a, b) => b.value - a.value)
    .slice(0, 12);

  const curGroup = GROUPS.find((g) => g.v === groupBy)!;

  return (
    <div className="space-y-4">
      {/* Boshqaruv paneli */}
      <div className="rounded-card border border-black/5 bg-card p-3 flex flex-wrap items-center gap-x-6 gap-y-3">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-ink-soft">{t('shipping.stats.groupBy')}</span>
          <select className="input !w-auto" value={groupBy} onChange={(e) => setGroupBy(e.target.value as GroupBy)}>
            {GROUPS.map((g) => <option key={g.v} value={g.v}>{t(`shipping.stats.${g.label}`)}</option>)}
          </select>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-ink-soft">{t('shipping.stats.period')}</span>
          {!useRange ? (
            <>
              <select className="input !w-auto" value={year} onChange={(e) => setYear(Number(e.target.value))}>
                {yearOptions.map((y) => <option key={y} value={y}>{y}</option>)}
              </select>
              <select className="input !w-auto" value={month} onChange={(e) => setMonth(Number(e.target.value))}>
                <option value={0}>{t('shipping.allMonths')}</option>
                {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                  <option key={m} value={m}>{t(`shipping.months.${m}`)}</option>
                ))}
              </select>
            </>
          ) : (
            <div className="flex items-center gap-2">
              <input type="date" className="input !w-auto" value={from} onChange={(e) => setFrom(e.target.value)} />
              <span className="text-ink-soft">—</span>
              <input type="date" className="input !w-auto" value={to} onChange={(e) => setTo(e.target.value)} />
            </div>
          )}
          <button onClick={() => setUseRange((x) => !x)}
                  className={`px-3 py-1.5 text-sm rounded-button border transition ${
                    useRange ? 'border-accent text-accent bg-accent/5' : 'border-black/10 text-ink-soft hover:bg-black/5'}`}>
            {t('shipping.stats.customRange')}
          </button>
        </div>
      </div>

      {/* KPI kartalar */}
      <div className="grid grid-cols-2 gap-3">
        <Kpi icon={<Package size={16} />} label={t('shipping.colQty')} value={grp(data?.total.qty ?? 0)} tone="warning" />
        <Kpi icon={<Coins size={16} />} label={t('shipping.colFreight')} value={formatUZS(Number(data?.total.freight ?? 0))} tone="success" />
      </div>

      {q.isLoading ? (
        <Card><div className="h-64 rounded bg-black/5 animate-pulse" /></Card>
      ) : !data || data.rows.length === 0 ? (
        <Card><EmptyState title={t('shipping.stats.empty')} description={t('shipping.stats.emptyDesc')} /></Card>
      ) : (
        <div className="grid lg:grid-cols-2 gap-4">
          {/* Grafik */}
          <Card>
            <div className="flex items-center justify-between gap-2 mb-3 flex-wrap">
              <h3 className="font-semibold">{t(`shipping.stats.${curGroup.label}`)}</h3>
              <div className="flex items-center gap-1 rounded-button border border-black/10 p-0.5">
                {METRICS.map((m) => (
                  <button key={m.v} onClick={() => setMetric(m.v)}
                          className={`px-2.5 py-1 text-xs rounded transition ${metric === m.v ? 'bg-primary text-white' : 'text-ink-soft hover:bg-black/5'}`}>
                    {t(m.key)}
                  </button>
                ))}
              </div>
            </div>
            {chartData.length === 0 ? (
              <div className="h-64 flex items-center justify-center text-sm text-ink-soft">{t('shipping.stats.empty')}</div>
            ) : (
              <ResponsiveContainer width="100%" height={Math.max(240, chartData.length * 34)}>
                <BarChart layout="vertical" data={chartData} margin={{ top: 4, right: 16, bottom: 4, left: 8 }}>
                  <XAxis type="number" hide />
                  <YAxis type="category" dataKey="name" width={120}
                         tick={{ fontSize: 12, fill: '#7F8C8D' }} axisLine={false} tickLine={false} />
                  <Tooltip
                    cursor={{ fill: 'rgba(0,0,0,0.04)' }}
                    formatter={(val: number) => [fmtMetric(val), t(METRICS.find((m) => m.v === metric)!.key)]}
                  />
                  <Bar dataKey="value" radius={[0, 6, 6, 0]} barSize={20}>
                    {chartData.map((_, i) => <Cell key={i} fill={BAR_COLORS[i % BAR_COLORS.length]} />)}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </Card>

          {/* Jadval */}
          <Card className="!p-0 overflow-hidden">
            <div className="overflow-auto max-h-[70vh]">
              <table className="w-full text-sm">
                <thead className="sticky top-0 z-10 text-left text-ink-soft bg-bg">
                  <tr className="[&>th]:py-2.5 [&>th]:px-3 [&>th]:font-semibold [&>th]:text-[11px] [&>th]:uppercase [&>th]:tracking-wide [&>th]:border-b-2 [&>th]:border-black/10">
                    <th>{t(`shipping.stats.${curGroup.label}`)}</th>
                    <th className="text-right">{t('shipping.stats.count')}</th>
                    <th className="text-right">{t('shipping.colQty')}</th>
                    <th className="text-right">{t('shipping.colFreight')}</th>
                  </tr>
                </thead>
                <tbody>
                  {data.rows.map((r, i) => (
                    <tr key={`${r.key}-${i}`} className="border-b border-black/5 hover:bg-accent/[0.04]">
                      <td className="py-2 px-3 font-medium">
                        <span className="inline-flex items-center gap-2">
                          <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ background: BAR_COLORS[i % BAR_COLORS.length] }} />
                          {keyLabel(r.key)}
                        </span>
                      </td>
                      <td className="py-2 px-3 text-right tabular-nums">{grp(r.count)}</td>
                      <td className="py-2 px-3 text-right tabular-nums">{grp(r.qty)}</td>
                      <td className="py-2 px-3 text-right tabular-nums font-medium">{formatUZS(Number(r.freight))}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="sticky bottom-0 font-bold bg-primary-50 [&>td]:py-2.5 [&>td]:px-3 [&>td]:border-t-2 [&>td]:border-black/10">
                    <td>{t('shipping.total')}</td>
                    <td className="text-right tabular-nums">{grp(data.total.count)}</td>
                    <td className="text-right tabular-nums">{grp(data.total.qty)}</td>
                    <td className="text-right tabular-nums text-success">{formatUZS(Number(data.total.freight))}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}
