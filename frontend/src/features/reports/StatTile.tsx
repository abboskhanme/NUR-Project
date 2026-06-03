import { cn } from '@/lib/cn';

interface Props {
  label: string;
  value: string;
  tone?: 'default' | 'primary' | 'success' | 'danger' | 'warning';
  sub?: string;
}

const TONE: Record<NonNullable<Props['tone']>, string> = {
  default: 'text-ink',
  primary: 'text-primary',
  success: 'text-success',
  danger: 'text-danger',
  warning: 'text-warning',
};

export default function StatTile({ label, value, tone = 'default', sub }: Props) {
  return (
    <div className="card !p-4">
      <div className="text-xs text-ink-soft">{label}</div>
      <div className={cn('text-xl font-bold mt-1 leading-tight', TONE[tone])}>{value}</div>
      {sub && <div className="text-xs text-ink-soft mt-0.5">{sub}</div>}
    </div>
  );
}
