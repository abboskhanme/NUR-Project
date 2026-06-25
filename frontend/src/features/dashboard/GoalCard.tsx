import { useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { Target, Pencil, ShoppingCart, TrendingUp } from 'lucide-react';

import { api } from '@/api/client';
import { usePermissions } from '@/lib/permissions';
import Card from '@/components/ui/Card';
import { formatUZS } from '@/lib/format';
import type { MonthlyGoal } from '@/features/dashboard/types';
import GoalModal from '@/features/dashboard/GoalModal';

function ProgressRow({
  icon, label, actual, target, pct, accent,
}: {
  icon: ReactNode;
  label: string;
  actual: string;
  target: string | null;
  pct: number | null;
  accent: string;
}) {
  const { t } = useTranslation();
  const filled = Math.min(pct ?? 0, 100);
  const reached = (pct ?? 0) >= 100;
  return (
    <div>
      <div className="flex items-center justify-between text-sm">
        <span className="flex items-center gap-2 text-ink-soft">{icon}{label}</span>
        <span className="font-medium tabular-nums">
          {actual}{target != null && <span className="text-ink-soft"> / {target}</span>}
        </span>
      </div>
      {target != null ? (
        <div className="mt-2 flex items-center gap-2">
          <div className="flex-1 h-2.5 rounded-full bg-black/5 overflow-hidden">
            <div
              className={`h-full rounded-full transition-all ${reached ? 'bg-success' : accent}`}
              style={{ width: `${filled}%` }}
            />
          </div>
          <span className={`text-xs font-semibold tabular-nums ${reached ? 'text-success' : 'text-ink-soft'}`}>
            {pct ?? 0}%
          </span>
        </div>
      ) : (
        <div className="mt-2 text-xs text-ink-soft">{t('dashboard.goal.notSet')}</div>
      )}
    </div>
  );
}

export default function GoalCard() {
  const { t } = useTranslation();
  const { canSpecial } = usePermissions();
  const canManage = canSpecial('system:goals_manage');
  const [editing, setEditing] = useState(false);

  const { data, refetch } = useQuery<MonthlyGoal>({
    queryKey: ['monthly-goal'],
    queryFn: () => api.get('/goals/current').then((r) => r.data),
  });

  const hasGoal = !!data && (data.target_orders != null || data.target_revenue_uzs != null);

  return (
    <>
      <Card
        title={<span className="flex items-center gap-2"><Target size={18} className="text-primary" />{t('dashboard.goal.title')}</span>}
        action={canManage && (
          <button
            onClick={() => setEditing(true)}
            className="flex items-center gap-1 px-2.5 py-1 text-xs rounded-button border border-black/10 hover:bg-black/5"
          >
            <Pencil size={13} /> {hasGoal ? t('actions.edit') : t('dashboard.goal.set')}
          </button>
        )}
      >
        {hasGoal ? (
          <div className="space-y-4">
            <ProgressRow
              icon={<ShoppingCart size={15} />}
              label={t('dashboard.goal.orders')}
              actual={String(data!.actual_orders)}
              target={data!.target_orders != null ? String(data!.target_orders) : null}
              pct={data!.orders_pct}
              accent="bg-primary"
            />
            <ProgressRow
              icon={<TrendingUp size={15} />}
              label={t('dashboard.goal.revenue')}
              actual={formatUZS(data!.actual_revenue_uzs)}
              target={data!.target_revenue_uzs != null ? formatUZS(data!.target_revenue_uzs) : null}
              pct={data!.revenue_pct}
              accent="bg-success"
            />
          </div>
        ) : (
          <p className="text-sm text-ink-soft py-2">
            {canManage ? t('dashboard.goal.emptyManage') : t('dashboard.goal.empty')}
          </p>
        )}
      </Card>

      {editing && (
        <GoalModal
          goal={data ?? null}
          onClose={() => setEditing(false)}
          onSaved={() => refetch()}
        />
      )}
    </>
  );
}
