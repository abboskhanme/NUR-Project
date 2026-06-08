import { useTranslation } from 'react-i18next';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';

import { orderStatusLabel, orderStatusColor } from '@/lib/status';

interface Props {
  data?: Array<{ status: string; count: number }>;
}

export default function StatusDonut({ data }: Props) {
  const { t } = useTranslation();
  const rows = (data ?? []).filter((d) => d.count > 0);

  if (data && rows.length === 0) {
    return <div className="text-sm text-ink-soft py-12 text-center">{t('dashboard.donut.noData')}</div>;
  }

  const chartData = rows.map((r) => ({
    name: orderStatusLabel(r.status),
    value: r.count,
    color: orderStatusColor(r.status),
  }));
  const total = rows.reduce((s, r) => s + r.count, 0);

  return (
    <div className="relative">
      <ResponsiveContainer width="100%" height={220}>
        <PieChart>
          <Pie
            data={chartData}
            dataKey="value"
            nameKey="name"
            innerRadius={60}
            outerRadius={90}
            paddingAngle={2}
          >
            {chartData.map((d, i) => <Cell key={i} fill={d.color} />)}
          </Pie>
          <Tooltip formatter={(v: number) => [t('dashboard.donut.countUnit', { count: v }), t('dashboard.donut.tooltipLabel')]} />
          <Legend verticalAlign="bottom" height={32} iconType="circle" />
        </PieChart>
      </ResponsiveContainer>
      <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center -mt-4">
        <div className="text-2xl font-bold leading-none">{total}</div>
        <div className="text-xs text-ink-soft">{t('dashboard.donut.total')}</div>
      </div>
    </div>
  );
}
