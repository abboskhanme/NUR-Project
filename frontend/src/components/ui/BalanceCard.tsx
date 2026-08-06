import { ReactNode } from 'react';
import { cn } from '@/lib/cn';

export default function BalanceCard({
  title, value, icon, accent, trend, action,
}: {
  title: string;
  value: string;
  icon?: ReactNode;
  accent?: 'primary' | 'success' | 'warning' | 'accent';
  // invert: o'sish yomon (masalan chiqim) — ko'tarilganda qizil, tushganda yashil.
  // kind: 'pct' — foizda (%), 'count' — sonda (... ta). Standart: 'pct'.
  trend?: { value: number; label: string; invert?: boolean; kind?: 'pct' | 'count' };
  // action: karta tagida ko'rinadigan tugma yoki boshqa element (ixtiyoriy).
  action?: ReactNode;
}) {
  const ring = accent === 'success' ? 'bg-success/10 text-success'
             : accent === 'warning' ? 'bg-warning/10 text-warning'
             : accent === 'accent' ? 'bg-accent/10 text-accent'
             : 'bg-primary/10 text-primary';
  const good = trend ? (trend.invert ? trend.value <= 0 : trend.value >= 0) : true;
  return (
    <div className="card">
      <div className="flex items-start justify-between gap-2">
        {/* min-w-0 — busiz uzun summa ikonkani siqib, o'zi tor ustunga tushib ketadi */}
        <div className="min-w-0 flex-1">
          <div className="text-xs sm:text-sm text-ink-soft">{title}</div>
          <div className="text-xl sm:text-2xl font-bold mt-1.5 sm:mt-2 break-words">{value}</div>
          {trend && (
            <div className={cn('text-[11px] sm:text-xs mt-1', good ? 'text-success' : 'text-danger')}>
              {trend.value >= 0 ? '+' : ''}{trend.value}{trend.kind === 'count' ? ' ta' : '%'} {trend.label}
            </div>
          )}
        </div>
        {icon && (
          <div className={cn(
            'shrink-0 w-9 h-9 sm:w-10 sm:h-10 rounded-button flex items-center justify-center', ring,
          )}>{icon}</div>
        )}
      </div>
      {action && <div className="mt-3">{action}</div>}
    </div>
  );
}
