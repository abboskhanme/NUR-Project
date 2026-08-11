import { useMemo } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Cell, Legend,
} from 'recharts';
import { PackagePlus, Wallet, ArrowLeftRight, PackageMinus } from 'lucide-react';

import Card from '@/components/ui/Card';
import { formatMoney, formatQty } from '@/lib/format';

interface TxLog {
  id: string;
  supplier_id: string;
  supplier_name?: string | null;
  // Yetkazib beruvchiga qilingan umumiy to'lovda mahsulot bo'lmaydi
  product_id?: string | null;
  product_name?: string | null;
  unit: string;
  kind: 'purchase' | 'payment' | 'consume' | 'adjust';
  qty: number;
  unit_price: number;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
  /** Arxivga o'tgan yozuv — grafiklarda hisobga olinmaydi */
  deleted_at?: string | null;
}

const CURRENCY_LABEL: Record<string, string> = { UZS: "so'm", USD: 'dollar' };

const shortDate = (iso: string) => {
  const [, m, d] = iso.slice(0, 10).split('-');
  return `${d}.${m}`;
};
const compact = (n: number) => {
  if (n >= 1_000_000_000) return `${(n / 1_000_000_000).toFixed(1)} mlrd`;
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)} mln`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(0)} ming`;
  return String(n);
};

/**
 * Hisobotlar uchun vizual qism. `log` (harakatlar jurnali) asosida grafiklarni
 * mijoz tomonda hisoblaydi — qo'shimcha so'rov yo'q. Valyutalar aralashmasligi
 * uchun eng ko'p uchragan valyuta tanlanadi (qolganiga eslatma ko'rsatiladi).
 */
export default function TaminotReportCharts({ log: rawLog }: { log: TxLog[] }) {
  const view = useMemo(() => {
    // Arxivdagilar grafiklarga kirmaydi — ular hisobdan chiqarilgan
    const log = rawLog.filter((t) => !t.deleted_at);
    if (!log.length) return null;

    // Eng ko'p uchragan valyutani aniqlash (aralashtirmaslik uchun)
    const curCount = new Map<string, number>();
    for (const t of log) curCount.set(t.currency, (curCount.get(t.currency) ?? 0) + 1);
    const currency = [...curCount.entries()].sort((a, b) => b[1] - a[1])[0][0];
    const otherCurrencies = [...curCount.keys()].filter((c) => c !== currency);
    const rows = log.filter((t) => t.currency === currency);

    // Davr yig'indilari (consume/adjust — pul harakati emas)
    let purchased = 0;
    let paid = 0;
    for (const t of rows) {
      if (t.kind === 'purchase') purchased += t.amount;
      else if (t.kind === 'payment') paid += t.amount;
    }

    // Kunlik dinamika
    const byDay = new Map<string, { date: string; purchase: number; payment: number }>();
    for (const t of rows) {
      const day = t.created_at.slice(0, 10);
      const slot = byDay.get(day) ?? { date: day, purchase: 0, payment: 0 };
      if (t.kind === 'purchase') slot.purchase += t.amount;
      else if (t.kind === 'payment') slot.payment += t.amount;
      byDay.set(day, slot);
    }
    const daily = [...byDay.values()].sort((a, b) => a.date.localeCompare(b.date));

    // Mahsulot bo'yicha olib kelish (top)
    const byProduct = new Map<string, number>();
    for (const t of rows) {
      if (t.kind !== 'purchase' || !t.product_name) continue;
      byProduct.set(t.product_name, (byProduct.get(t.product_name) ?? 0) + t.amount);
    }
    const topProducts = [...byProduct.entries()]
      .map(([name, value]) => ({ name, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 7);

    // Eng ko'p sarflangan mahsulotlar (miqdor bo'yicha, barcha valyutalardan)
    const byConsume = new Map<string, { name: string; unit: string; value: number }>();
    for (const t of log) {
      if (t.kind !== 'consume' || !t.product_name) continue;
      const slot = byConsume.get(t.product_name)
        ?? { name: t.product_name, unit: t.unit, value: 0 };
      slot.value += t.qty;
      byConsume.set(t.product_name, slot);
    }
    const topConsumed = [...byConsume.values()].sort((a, b) => b.value - a.value).slice(0, 7);
    const consumedCount = log.filter((t) => t.kind === 'consume').length;

    return {
      currency, otherCurrencies, rows, purchased, paid, daily, topProducts,
      topConsumed, consumedCount,
    };
  }, [rawLog]);

  if (!view) return null;
  const {
    currency, otherCurrencies, rows, purchased, paid, daily, topProducts,
    topConsumed, consumedCount,
  } = view;
  const curLabel = CURRENCY_LABEL[currency] ?? currency;

  return (
    <div className="space-y-4">
      {/* Davr bo'yicha mini-statistika */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <MiniTile tone="primary" label="Davr kirim" value={formatMoney(purchased, currency)}
          icon={<PackagePlus size={16} />} />
        <MiniTile tone="success" label="Davr to'lov" value={formatMoney(paid, currency)}
          icon={<Wallet size={16} />} />
        <MiniTile tone="warning" label="Sarflash" value={`${consumedCount} ta`}
          icon={<PackageMinus size={16} />} />
        <MiniTile tone="muted" label="Harakatlar" value={`${rows.length} ta`}
          icon={<ArrowLeftRight size={16} />} />
      </div>

      {otherCurrencies.length > 0 && (
        <div className="text-xs text-ink-soft">
          Grafiklar {curLabel} bo'yicha. Boshqa valyutalar ({otherCurrencies.map((c) => CURRENCY_LABEL[c] ?? c).join(', ')}) jadvalda ko'rinadi.
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Kunlik kirim/to'lov */}
        <Card title="Kunlik harakat">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={daily} margin={{ top: 8, right: 8, left: 0, bottom: 0 }} barGap={2}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis dataKey="date" tickFormatter={shortDate} fontSize={11} tickMargin={6} />
              <YAxis tickFormatter={compact} fontSize={11} width={56} />
              <Tooltip
                formatter={(v: number, n) => [formatMoney(v, currency), n === 'purchase' ? 'Olib kelish' : "To'lov"]}
                labelFormatter={(l) => shortDate(String(l))}
              />
              <Legend formatter={(v) => (v === 'purchase' ? 'Olib kelish' : "To'lov")} iconType="circle" />
              <Bar dataKey="purchase" fill="#1E3A5F" radius={[3, 3, 0, 0]} />
              <Bar dataKey="payment" fill="#27AE60" radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        {/* Eng ko'p olib kelingan mahsulotlar */}
        <Card title="Eng ko'p olib kelingan mahsulotlar">
          {topProducts.length > 0 ? (
            <ResponsiveContainer width="100%" height={Math.max(180, topProducts.length * 34)}>
              <BarChart data={topProducts} layout="vertical" margin={{ left: 8, right: 16 }}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
                <XAxis type="number" fontSize={11} tickFormatter={compact} />
                <YAxis type="category" dataKey="name" fontSize={11} width={120} interval={0} />
                <Tooltip formatter={(v: number) => [formatMoney(v, currency), 'Olib kelingan']} />
                <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                  {topProducts.map((_, i) => (
                    <Cell key={i} fill={i === 0 ? '#1E3A5F' : '#2980B9'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="text-sm text-ink-soft py-12 text-center">Olib kelish yo'q</div>
          )}
        </Card>
      </div>

      {/* Eng ko'p sarflangan mahsulotlar — miqdor bo'yicha (ombordan chiqim) */}
      {topConsumed.length > 0 && (
        <Card title="Eng ko'p sarflangan mahsulotlar (miqdor)">
          <ResponsiveContainer width="100%" height={Math.max(180, topConsumed.length * 34)}>
            <BarChart data={topConsumed} layout="vertical" margin={{ left: 8, right: 16 }}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
              <XAxis type="number" fontSize={11} tickFormatter={compact} />
              <YAxis type="category" dataKey="name" fontSize={11} width={120} interval={0} />
              <Tooltip
                formatter={(v: number, _n, p: any) => [formatQty(v, p?.payload?.unit), 'Sarflangan']}
              />
              <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                {topConsumed.map((_, i) => (
                  <Cell key={i} fill={i === 0 ? '#F39C12' : '#F5B461'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </Card>
      )}
    </div>
  );
}

const TILE_TONES = {
  primary: 'border-primary/20 bg-primary/5 text-primary',
  success: 'border-success/25 bg-success/10 text-success',
  warning: 'border-warning/30 bg-warning/10 text-warning',
  muted: 'border-black/10 bg-black/[0.03] text-ink',
} as const;

function MiniTile({ tone, label, value, icon }: {
  tone: keyof typeof TILE_TONES;
  label: string;
  value: string;
  icon: React.ReactNode;
}) {
  return (
    <div className={`rounded-card border p-3 ${TILE_TONES[tone]}`}>
      <div className="flex items-center gap-1.5 text-xs font-medium opacity-90">
        {icon} {label}
      </div>
      <div className="text-lg font-bold mt-1.5 truncate">{value}</div>
    </div>
  );
}
