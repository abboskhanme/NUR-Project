import { useTranslation } from 'react-i18next';
import { cn } from '@/lib/cn';

export type ServiceStatus = 'new' | 'scheduled' | 'completed' | 'cancelled';

export const SERVICE_STATUS_ORDER: ServiceStatus[] = ['new', 'scheduled', 'completed', 'cancelled'];

export const SERVICE_STATUS_CLS: Record<string, string> = {
  new: 'bg-blue-100 text-blue-700',
  scheduled: 'bg-amber-100 text-amber-700',
  completed: 'bg-emerald-100 text-emerald-700',
  cancelled: 'bg-gray-200 text-gray-600',
};

export function ServiceStatusBadge({ status, className }: { status: string; className?: string }) {
  const { t } = useTranslation();
  const cls = SERVICE_STATUS_CLS[status] ?? 'bg-gray-100 text-gray-700';
  const label = t(`service.status.${status}`, { defaultValue: status });
  return <span className={cn('badge', cls, className)}>{label}</span>;
}
