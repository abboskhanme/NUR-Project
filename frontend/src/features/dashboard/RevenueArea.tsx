import {
  AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid,
} from 'recharts';

import { formatUZS } from '@/lib/format';

interface Point { date: string; total_uzs: number; orders: number }

const shortDate = (iso: string) => {
  const [, m, d] = iso.split('-');
  return `${d}.${m}`;
};

const compact = (n: number) => {
  if (n >= 1_000_000_000) return `${(n / 1_000_000_000).toFixed(1)} mlrd`;
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(0)} mln`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(0)} ming`;
  return String(n);
};

export default function RevenueArea({ points, height = 250 }: { points?: Point[]; height?: number }) {
  if (!points) return <div className="text-sm text-ink-soft py-12 text-center">Yuklanmoqda…</div>;
  if (points.every((p) => p.total_uzs === 0)) {
    return <div className="text-sm text-ink-soft py-12 text-center">Bu davrda tushum yo'q</div>;
  }

  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={points} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="revFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#1E3A5F" stopOpacity={0.35} />
            <stop offset="100%" stopColor="#1E3A5F" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" opacity={0.15} />
        <XAxis dataKey="date" tickFormatter={shortDate} fontSize={11} tickMargin={6} />
        <YAxis tickFormatter={compact} fontSize={11} width={56} />
        <Tooltip
          formatter={(v: number) => [formatUZS(v), 'Tushum']}
          labelFormatter={(l) => shortDate(String(l))}
        />
        <Area
          type="monotone"
          dataKey="total_uzs"
          stroke="#1E3A5F"
          strokeWidth={2}
          fill="url(#revFill)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
