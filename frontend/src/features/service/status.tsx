import { cn } from '@/lib/cn';

export type ServiceStatus = 'new' | 'scheduled' | 'completed' | 'cancelled';

export const SERVICE_STATUS_ORDER: ServiceStatus[] = ['new', 'scheduled', 'completed', 'cancelled'];

export const SERVICE_STATUS_CLS: Record<string, string> = {
  new: 'bg-blue-100 text-blue-700',
  scheduled: 'bg-amber-100 text-amber-700',
  completed: 'bg-emerald-100 text-emerald-700',
  cancelled: 'bg-gray-200 text-gray-600',
};

const SERVICE_STATUS_LABELS: Record<string, string> = {
  new: 'Yangi',
  scheduled: 'Rejalashtirilgan',
  completed: 'Bajarildi',
  cancelled: 'Bekor qilingan',
};

export function ServiceStatusBadge({ status, className }: { status: string; className?: string }) {
  const cls = SERVICE_STATUS_CLS[status] ?? 'bg-gray-100 text-gray-700';
  const label = SERVICE_STATUS_LABELS[status] ?? status;
  return <span className={cn('badge', cls, className)}>{label}</span>;
}
