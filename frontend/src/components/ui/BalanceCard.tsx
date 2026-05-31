import { ReactNode } from 'react';
import { cn } from '@/lib/cn';

export default function BalanceCard({
  title, value, icon, accent, trend,
}: {
  title: string;
  value: string;
  icon?: ReactNode;
  accent?: 'primary' | 'success' | 'warning';
  trend?: { value: number; label: string };
}) {
  const ring = accent === 'success' ? 'bg-success/10 text-success'
             : accent === 'warning' ? 'bg-warning/10 text-warning'
             : 'bg-primary/10 text-primary';
  return (
    <div className="card">
      <div className="flex items-start justify-between">
        <div>
          <div className="text-sm text-ink-soft">{title}</div>
          <div className="text-2xl font-bold mt-2">{value}</div>
          {trend && (
            <div className={cn('text-xs mt-1', trend.value >= 0 ? 'text-success' : 'text-danger')}>
              {trend.value >= 0 ? '+' : ''}{trend.value}% {trend.label}
            </div>
          )}
        </div>
        {icon && <div className={cn('w-10 h-10 rounded-button flex items-center justify-center', ring)}>{icon}</div>}
      </div>
    </div>
  );
}
