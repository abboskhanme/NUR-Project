import { cn } from '@/lib/cn';

export type ServiceStatus = 'new' | 'scheduled' | 'completed' | 'cancelled';

export const SERVICE_STATUS_ORDER: ServiceStatus[] = ['new', 'scheduled', 'completed', 'cancelled'];

export const SERVICE_STATUS_META: Record<string, { label: string; cls: string }> = {
  new: { label: 'Yangi', cls: 'bg-blue-100 text-blue-700' },
  scheduled: { label: 'Rejalashtirilgan', cls: 'bg-amber-100 text-amber-700' },
  completed: { label: 'Bajarildi', cls: 'bg-emerald-100 text-emerald-700' },
  cancelled: { label: 'Bekor qilingan', cls: 'bg-gray-200 text-gray-600' },
};

export function ServiceStatusBadge({ status, className }: { status: string; className?: string }) {
  const m = SERVICE_STATUS_META[status] ?? { label: status, cls: 'bg-gray-100 text-gray-700' };
  return <span className={cn('badge', m.cls, className)}>{m.label}</span>;
}
