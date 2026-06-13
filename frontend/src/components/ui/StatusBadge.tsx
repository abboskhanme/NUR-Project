import { useTranslation } from 'react-i18next';
import { cn } from '@/lib/cn';

const STATUS_STYLES: Record<string, string> = {
  new: 'bg-blue-100 text-blue-700',
  ready: 'bg-teal-100 text-teal-700',
  delivered: 'bg-emerald-100 text-emerald-700',
  rejected: 'bg-gray-200 text-gray-600',
  // legacy statuslar
  confirmed: 'bg-indigo-100 text-indigo-700',
  in_production: 'bg-orange-100 text-orange-700',
  paid: 'bg-green-100 text-green-800',
  cancelled: 'bg-gray-200 text-gray-600',
};

interface Props {
  status: string;
  className?: string;
}

export default function StatusBadge({ status, className }: Props) {
  const { t } = useTranslation();
  const style = STATUS_STYLES[status] || 'bg-gray-100 text-gray-700';
  const label = t(`ui.statusBadge.${status}`, { defaultValue: status });
  return (
    <span className={cn('badge', style, className)}>
      {label}
    </span>
  );
}
