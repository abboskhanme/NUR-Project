import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  ComposedChart, Bar, Line, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer,
  CartesianGrid, BarChart, Cell, PieChart, Pie,
} from 'recharts';
import { AlertTriangle, Info } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import { cn } from '@/lib/cn';
import ReportTable, { Column } from './ReportTable';
import StatTile from './StatTile';
import type { DateRange, ProfitReport, ProfitProductRow } from './types';

/**
 * Tannarx asosidagi foyda hisoboti.
 *
 * Davr ichida sotilgan mahsulotlarga Tannarx bo'limidagi kalkulyatsiya
 * qo'llanadi: tushum − tannarx = yalpi foyda, undan moliyadagi xarajatlar
 * ayrilsa — sof foyda. Kalkulyatsiyasi kiritilmagan mahsulot ham hisobga
 * qo'shiladi — tannarxi 0 deb olinadi (100% foyda), shunda umumiy manzara
 * to'liq bo'ladi; foyda oshib ketgani ogohlantirishda aytiladi.
 */

// Ranglar CVD (rang ko'rmaslik) tekshiruvidan o'tkazilgan tartibda —
// yonma-yon tushadigan juftlar ajralib turadi.
const C_REVENUE = '#2980B9';   // tushum
const C_COST = '#E74C3C';      // tannarx
const C_PROFIT = '#27AE60';    // foyda
const C_OPEX = '#C0392B';      // operatsion xarajat
const C_NET = '#1E3A5F';       // sof foyda
// Tushum tarkibi (donut) — tekshiruvdan o'tgan tartib
const STRUCTURE_COLORS = [C_REVENUE, '#F39C12', '#8E44AD', C_PROFIT];

const compact = (n: number) => {
  const a = Math.abs(n);
  if (a >= 1e9) return `${(n / 1e9).toFixed(1)} mlrd`;
  if (a >= 1e6) return `${(n / 1e6).toFixed(0)} mln`;
  if (a >= 1e3) return `${(n / 1e3).toFixed(0)} ming`;
  return String(n);
};

const periodLabel = (iso: string, gran: 'day' | 'month') => {
  const [y, m, d] = iso.split('-');
  return gran === 'month' ? `${m}.${y}` : `${d}.${m}`;
};

const GRAN_LABELS: Record<'day' | 'month', string> = { day: 'Kunlik', month: 'Oylik' };

export default function CostingReport({ range }: { range: DateRange }) {
  // Sukut bo'yicha davr uzunligiga qarab: uzun davr — oylik, qisqasi — kunlik.
  // Foydalanuvchi tugma bilan o'zgartirsa, o'sha tanlovi ustun turadi.
  const [granPick, setGranPick] = useState<'day' | 'month' | null>(null);
  const days = Math.round(
    (new Date(range.to).getTime() - new Date(range.from).getTime()) / 864e5,
  );
  const gran = granPick ?? (days > 62 ? 'month' : 'day');
  const setGran = setGranPick;

  const q = useQuery<ProfitReport>({
    queryKey: ['rep-costing-profit', range, gran],
    queryFn: () => api.get('/costing/profit-report', {
      params: { date_from: range.from, date_to: range.to, granularity: gran },
    }).then((r) => r.data),
  });

  const d = q.data;
  const products = d?.products ?? [];
  const withRecipe = products.filter((p) => p.has_recipe);
  // Grafik/jami — BARCHA sotilgan mahsulot (tannarxsizlari 100% foyda sifatida)

  // Kalkulyatsiyasi yo'q mahsulot tannarxi 0 deb olinadi (100% foyda), shuning
  // uchun foyda BARCHA sotuvdan hisoblanadi va xarajat bilan bir xil bazada
  // bo'ladi. Lekin bunday mahsulotlar foydani sun'iy oshiradi — ogohlantiramiz.
  const inflated = !!d && d.uncovered_count > 0;

  // Foyda bo'yicha eng yaxshi 12 ta (grafik o'qilishi uchun cheklangan)
  const topProducts = [...products]
    .sort((a, b) => (b.profit_uzs ?? 0) - (a.profit_uzs ?? 0))
    .slice(0, 12);

  const structure = d ? [
    { name: 'Materiallar', value: d.structure.materials_uzs },
    { name: 'Qo\'shimcha xarajat', value: d.structure.expenses_uzs },
    { name: 'Ustama', value: d.structure.overhead_uzs },
    { name: 'Yalpi foyda', value: Math.max(0, d.structure.profit_uzs) },
  ].filter((s) => s.value > 0) : [];

  const cols: Column<ProfitProductRow>[] = [
    { key: 'display_name', label: 'Mahsulot',
      render: (r) => (
        <span className="inline-flex items-center gap-1.5">
          {r.display_name}
          {!r.has_recipe && (
            <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-warning/15 text-warning whitespace-nowrap">
              tannarx yo'q
            </span>
          )}
        </span>
      ) },
    { key: 'units', label: 'Sotildi', align: 'right', render: (r) => `${r.units} ta` },
    { key: 'avg_price_uzs', label: "O'rtacha narx", align: 'right', render: (r) => formatUZS(r.avg_price_uzs) },
    { key: 'unit_cost_uzs', label: 'Birlik tannarxi', align: 'right',
      value: (r) => r.unit_cost_uzs ?? 0,
      render: (r) => (r.unit_cost_uzs != null ? formatUZS(r.unit_cost_uzs) : '—') },
    { key: 'revenue_uzs', label: 'Tushum', align: 'right', render: (r) => formatUZS(r.revenue_uzs) },
    { key: 'cogs_uzs', label: 'Tannarx', align: 'right',
      value: (r) => r.cogs_uzs ?? 0,
      render: (r) => (r.cogs_uzs != null ? formatUZS(r.cogs_uzs) : '—') },
    { key: 'profit_uzs', label: 'Foyda', align: 'right',
      value: (r) => r.profit_uzs ?? 0,
      render: (r) => (
        <span className={cn('font-semibold',
          (r.profit_uzs ?? 0) >= 0 ? 'text-success' : 'text-danger')}>
          {formatUZS(r.profit_uzs ?? 0)}
        </span>
      ) },
    { key: 'margin_percent', label: 'Marja', align: 'right',
      value: (r) => r.margin_percent ?? 0,
      render: (r) => (r.margin_percent != null ? `${r.margin_percent}%` : '—') },
  ];

  const totals = products.reduce(
    (acc, r) => ({
      units: acc.units + r.units,
      revenue: acc.revenue + r.revenue_uzs,
      cogs: acc.cogs + (r.cogs_uzs ?? 0),
      profit: acc.profit + (r.profit_uzs ?? 0),
    }),
    { units: 0, revenue: 0, cogs: 0, profit: 0 },
  );

  if (q.isLoading) {
    return (
      <div className="space-y-3">
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="h-20 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
        <div className="h-72 rounded-card bg-black/5 animate-pulse" />
      </div>
    );
  }

  if (d && d.units_sold === 0) {
    return (
      <Card>
        <div className="py-12 text-center text-sm text-ink-soft">
          Bu davrda asosiy mahsulot sotilmagan — foyda hisoblanmadi
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
        <StatTile label="Sotuv tushumi" value={d ? formatUZS(d.revenue_uzs) : '—'}
          tone="primary"
          sub={d ? `${d.units_sold} dona sotilgan` : undefined} />
        <StatTile label="Tannarx" value={d ? formatUZS(d.cogs_uzs) : '—'} tone="danger"
          sub="sotilgan mahsulotlar" />
        <StatTile label="Yalpi foyda" value={d ? formatUZS(d.gross_profit_uzs) : '—'}
          tone={d && d.gross_profit_uzs >= 0 ? 'success' : 'danger'}
          sub={d?.gross_margin_percent != null ? `marja ${d.gross_margin_percent}%` : undefined} />
        <StatTile label="Operatsion xarajat" value={d ? formatUZS(d.opex_uzs) : '—'} tone="warning"
          sub="moliya bo'limidan" />
        <StatTile label="Sof foyda" value={d ? formatUZS(d.net_profit_uzs) : '—'}
          tone={d && d.net_profit_uzs >= 0 ? 'primary' : 'danger'}
          sub={!d ? undefined
            : inflated ? `qamrov ${d.coverage_percent}% — haqiqiydan yuqori`
            : d.net_margin_percent != null ? `marja ${d.net_margin_percent}%` : undefined} />
      </div>

      {/* Sotuv bo'limi bilan farqni ochib berish — «nega raqamlar mos emas» */}
      {d && d.excluded_additional_uzs > 0 && (
        <p className="text-xs text-ink-soft">
          Sotuv bo'limidagi «Savdo» — {formatUZS(d.sales_total_uzs)}. Bundan
          qo'shimcha mahsulotlar ({formatUZS(d.excluded_additional_uzs)}) chiqarib
          tashlangan — qolgani {formatUZS(d.revenue_uzs)}.
          {d.excluded_rejected_uzs > 0 && <> Rad etilgan buyurtmalar
            ({formatUZS(d.excluded_rejected_uzs)}) ikkala joyda ham hisoblanmaydi.</>}
        </p>
      )}

      {/* Kalkulyatsiyasi yo'q mahsulotlar — hisob to'liq emas */}
      {d && d.uncovered_count > 0 && (
        <div className="rounded-card border border-warning/30 bg-warning/10 px-4 py-3 flex items-start gap-3">
          <AlertTriangle size={18} className="text-warning shrink-0 mt-0.5" />
          <div className="text-sm text-warning">
            {d.uncovered_count} ta asosiy mahsulot ({d.uncovered_units} dona,
            {' '}{formatUZS(d.uncovered_revenue_uzs)}) kalkulyatsiyasiz sotilgan —
            ularning tannarxi <b>0 deb olindi</b>, ya'ni to'liq foyda sifatida
            hisoblandi. Shuning uchun yuqoridagi foyda haqiqiydan{' '}
            <b>yuqori</b> ko'rinadi. Tushumning faqat {d.coverage_percent}% qismida
            haqiqiy tannarx bor — qolganiga Tannarx bo'limidan kalkulyatsiya kiriting.
          </div>
        </div>
      )}

      {/* Foyda qanday shakllandi — waterfall */}
      <Card title="Sof foyda qanday shakllandi">
        {d && <Waterfall data={d} />}

        {/* Xarajat nimalardan iborat — moliyaga kiritilmagani ko'rinmasligi uchun */}
        {d && d.opex_by_category.length > 0 && (
          <div className="mt-3 pt-3 border-t border-black/5">
            <div className="text-xs text-ink-soft mb-1.5">
              Operatsion xarajat tarkibi ({d.opex_count} ta yozuv):
            </div>
            <div className="flex flex-wrap gap-1.5">
              {d.opex_by_category.map((c) => (
                <span key={c.category}
                      className="inline-flex items-center gap-1.5 px-2 py-1 rounded-button bg-black/[0.04] text-xs">
                  <span className="text-ink-soft">{c.category}</span>
                  <span className="font-medium">{formatUZS(c.amount_uzs)}</span>
                </span>
              ))}
            </div>
          </div>
        )}

        <p className="text-[11px] text-ink-soft mt-3 flex items-start gap-1.5">
          <Info size={13} className="shrink-0 mt-0.5" />
          Faqat ASOSIY mahsulotlar hisoblanadi — qo'shimcha mahsulotlar (ehtiyot
          qismlar) bu hisobotga kirmaydi. Manbalar: tushum — Sotuv bo'limidan
          (buyurtmalar), tannarx — Tannarx bo'limidan, xarajat — Moliya bo'limidan.
          Moliyadagi KIRIM ishlatilmaydi (u faqat kassadagi naqd oqim). Moliyaga
          kiritilmagan chiqim bu yerda ham hisoblanmaydi — yuqoridagi ro'yxatdan
          to'liqligini tekshiring.
        </p>
      </Card>

      {/* Dinamika */}
      <Card
        title="Tushum, tannarx va foyda dinamikasi"
        action={
          <div className="flex gap-1">
            {(['day', 'month'] as const).map((g) => (
              <button
                key={g}
                onClick={() => setGran(g)}
                className={`px-2.5 py-1 rounded-button text-xs border ${
                  gran === g ? 'bg-primary text-white border-primary' : 'bg-white border-black/10'
                }`}
              >
                {GRAN_LABELS[g]}
              </button>
            ))}
          </div>
        }
      >
        {d && d.trend.some((p) => p.revenue_uzs !== 0) ? (
          <ResponsiveContainer width="100%" height={300}>
            <ComposedChart data={d.trend} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}
              barGap={2} barCategoryGap="28%">
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="date" fontSize={11} tickMargin={6}
                tickFormatter={(v) => periodLabel(String(v), gran)} />
              <YAxis fontSize={11} width={62} tickFormatter={compact} />
              <Tooltip
                formatter={(v: number, n) => [formatUZS(v), n]}
                labelFormatter={(l) => periodLabel(String(l), gran)}
              />
              <Legend wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
              <Bar dataKey="revenue_uzs" name="Tushum" fill={C_REVENUE} radius={[4, 4, 0, 0]} maxBarSize={34} />
              <Bar dataKey="cogs_uzs" name="Tannarx" fill={C_COST} radius={[4, 4, 0, 0]} maxBarSize={34} />
              <Line type="monotone" dataKey="profit_uzs" name="Yalpi foyda"
                stroke={C_PROFIT} strokeWidth={2} dot={{ r: 3 }} />
            </ComposedChart>
          </ResponsiveContainer>
        ) : (
          <div className="text-sm text-ink-soft py-12 text-center">Bu davrda ma'lumot yo'q</div>
        )}
        <p className="text-[11px] text-ink-soft mt-2">
          Faqat kalkulyatsiyasi kiritilgan mahsulotlar — shuning uchun «Sotuv» hisobotidagi
          tushumdan farq qilishi mumkin.
        </p>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Tushum tarkibi */}
        <Card title={d && d.gross_profit_uzs < 0 ? 'Tannarx tarkibi (zarar)' : 'Tushum tarkibi'}>
          {structure.length > 0 ? (
            <>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie data={structure} dataKey="value" nameKey="name"
                       innerRadius={58} outerRadius={92} paddingAngle={2} stroke="none">
                    {structure.map((_, i) => (
                      <Cell key={i} fill={STRUCTURE_COLORS[i % STRUCTURE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v: number) => formatUZS(v)} />
                </PieChart>
              </ResponsiveContainer>
              <ul className="mt-2 space-y-1.5">
                {structure.map((s, i) => {
                  const total = structure.reduce((a, x) => a + x.value, 0);
                  return (
                    <li key={s.name} className="flex items-center gap-2 text-sm">
                      <span className="w-2.5 h-2.5 rounded-full shrink-0"
                            style={{ background: STRUCTURE_COLORS[i % STRUCTURE_COLORS.length] }} />
                      <span className="text-ink-soft">{s.name}</span>
                      <span className="ml-auto font-medium">{formatUZS(s.value)}</span>
                      <span className="text-ink-soft w-12 text-right">
                        {total > 0 ? `${Math.round((s.value / total) * 100)}%` : '—'}
                      </span>
                    </li>
                  );
                })}
              </ul>
            </>
          ) : (
            <div className="text-sm text-ink-soft py-12 text-center">Ma'lumot yo'q</div>
          )}
        </Card>

        {/* Mahsulot bo'yicha foyda */}
        <Card title="Mahsulot bo'yicha foyda">
          {topProducts.length > 0 ? (
            <ResponsiveContainer width="100%" height={Math.max(240, topProducts.length * 34)}>
              <BarChart data={topProducts} layout="vertical" margin={{ left: 8, right: 16 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                <XAxis type="number" fontSize={11} tickFormatter={compact} />
                <YAxis type="category" dataKey="display_name" fontSize={11} width={130} interval={0} />
                <Tooltip formatter={(v: number) => [formatUZS(v), 'Foyda']} />
                <Bar dataKey="profit_uzs" radius={[0, 4, 4, 0]}>
                  {topProducts.map((p, i) => (
                    <Cell key={i} fill={(p.profit_uzs ?? 0) >= 0 ? C_PROFIT : C_COST} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="text-sm text-ink-soft py-12 text-center">
              Kalkulyatsiyali mahsulot sotilmagan
            </div>
          )}
        </Card>
      </div>

      {/* To'liq jadval */}
      <Card title="Asosiy mahsulotlar kesimida">
        <ReportTable
          rows={products}
          columns={cols}
          filename="tannarx-foyda"
          emptyText="Bu davrda sotuv yo'q"
          footer={
            <>
              <td className="py-2 px-2">Jami</td>
              <td className="py-2 px-2 text-right">{totals.units} ta</td>
              <td className="py-2 px-2" />
              <td className="py-2 px-2" />
              <td className="py-2 px-2 text-right">{formatUZS(totals.revenue)}</td>
              <td className="py-2 px-2 text-right">{formatUZS(totals.cogs)}</td>
              <td className={cn('py-2 px-2 text-right',
                totals.profit >= 0 ? 'text-success' : 'text-danger')}>
                {formatUZS(totals.profit)}
              </td>
              <td className="py-2 px-2 text-right">
                {totals.revenue > 0 ? `${Math.round((totals.profit / totals.revenue) * 100)}%` : '—'}
              </td>
            </>
          }
        />
        <p className="text-[11px] text-ink-soft mt-3">
          Tannarx JORIY narxlar bo'yicha hisoblanadi (Tannarx bo'limidagi kalkulyatsiya va
          material katalogi) — o'tmishdagi narx tarixi saqlanmaydi. Rad etilgan buyurtmalar
          hisobga olinmaydi.
        </p>
      </Card>
    </div>
  );
}

/**
 * Foydaning shakllanishi (waterfall): har bir qadam qayerdan boshlanib
 * qayerda tugashini ko'rsatadi — manfiy sof foyda ham to'g'ri chiziladi.
 */
function Waterfall({ data, showNet = true }: { data: ProfitReport; showNet?: boolean }) {
  const gross = data.gross_profit_uzs;
  const net = data.net_profit_uzs;
  const steps = [
    { label: 'Tushum', from: 0, to: data.revenue_uzs, value: data.revenue_uzs, color: C_REVENUE },
    { label: 'Tannarx', from: gross, to: data.revenue_uzs, value: -data.cogs_uzs, color: C_COST },
    { label: 'Yalpi foyda', from: Math.min(0, gross), to: Math.max(0, gross), value: gross, color: C_PROFIT },
    // Qamrov past bo'lsa xarajat/sof foyda qadamlari ko'rsatilmaydi — davr
    // xarajatini tushumning bir qismidan ayirish yolg'on "zarar" beradi
    ...(showNet ? [
      { label: 'Operatsion xarajat', from: Math.min(net, gross), to: Math.max(net, gross), value: -data.opex_uzs, color: C_OPEX },
      { label: 'Sof foyda', from: Math.min(0, net), to: Math.max(0, net), value: net, color: net >= 0 ? C_NET : C_COST },
    ] : []),
  ];

  const lo = Math.min(0, ...steps.map((s) => s.from));
  const hi = Math.max(0, ...steps.map((s) => s.to));
  const span = hi - lo || 1;
  const pct = (v: number) => ((v - lo) / span) * 100;

  return (
    <div className="space-y-2.5">
      {steps.map((s) => (
        <div key={s.label} className="flex items-center gap-2 sm:gap-3">
          <div className="w-20 sm:w-36 shrink-0 text-[11px] sm:text-sm text-ink-soft truncate">{s.label}</div>
          <div className="flex-1 min-w-[60px] h-6 rounded-button bg-black/[0.04] relative overflow-hidden">
            <div
              className="absolute top-0 bottom-0 rounded-[4px]"
              style={{
                left: `${pct(s.from)}%`,
                width: `${Math.max(0.5, pct(s.to) - pct(s.from))}%`,
                background: s.color,
              }}
            />
            {lo < 0 && (
              <div className="absolute top-0 bottom-0 w-px bg-black/20" style={{ left: `${pct(0)}%` }} />
            )}
          </div>
          <div className={cn('w-24 sm:w-40 shrink-0 text-right text-[11px] sm:text-sm font-semibold tabular-nums whitespace-nowrap',
            s.value < 0 ? 'text-danger' : 'text-ink')}>
            {s.value < 0 ? `− ${formatUZS(Math.abs(s.value))}` : formatUZS(s.value)}
          </div>
        </div>
      ))}
    </div>
  );
}
