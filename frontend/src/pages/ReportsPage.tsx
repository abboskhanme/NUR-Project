import { useQuery } from '@tanstack/react-query';
import { BarChart, Bar, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid, Cell } from 'recharts';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';

const COLORS = ['#1E3A5F', '#2980B9', '#27AE60', '#F39C12', '#E74C3C'];

export default function ReportsPage() {
  const byModel = useQuery({
    queryKey: ['report-by-model'],
    queryFn: () => api.get('/reports/sales/by-model').then((r) => r.data as Array<{ model: string; count: number; total_uzs: number }>),
  });
  const byRegion = useQuery({
    queryKey: ['report-by-region'],
    queryFn: () => api.get('/reports/sales/by-region').then((r) => r.data as Array<{ region: string; count: number; total_uzs: number }>),
  });
  const pnl = useQuery({
    queryKey: ['pnl'],
    queryFn: () => api.get('/reports/finance/pnl').then((r) => r.data),
  });

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold">Hisobotlar</h1>
        <p className="text-sm text-ink-soft">KPI, sotuv tahlili, P&L</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card title="Sotuv — model bo'yicha">
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={byModel.data ?? []}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
              <XAxis dataKey="model" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="count">
                {(byModel.data ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card title="Sotuv — viloyat bo'yicha">
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={byRegion.data ?? []}>
              <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
              <XAxis dataKey="region" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="count">
                {(byRegion.data ?? []).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </Card>
      </div>

      <Card title="Moliya P&L (joriy oy)">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-sm text-ink-soft">Kirim</div>
            <div className="text-2xl font-bold text-success mt-1">{pnl.data?.income?.toLocaleString() ?? 0}</div>
          </div>
          <div>
            <div className="text-sm text-ink-soft">Chiqim</div>
            <div className="text-2xl font-bold text-danger mt-1">{pnl.data?.expense?.toLocaleString() ?? 0}</div>
          </div>
          <div>
            <div className="text-sm text-ink-soft">Sof foyda</div>
            <div className="text-2xl font-bold mt-1">{pnl.data?.net?.toLocaleString() ?? 0}</div>
          </div>
        </div>
      </Card>
    </div>
  );
}
