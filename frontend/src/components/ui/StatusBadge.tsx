import { cn } from '@/lib/cn';

const STATUS_STYLES: Record<string, string> = {
  new: 'bg-blue-100 text-blue-700',
  ready: 'bg-teal-100 text-teal-700',
  delivered: 'bg-emerald-100 text-emerald-700',
  rejected: 'bg-red-100 text-red-700',
  // eski (legacy) statuslar — qayta seed/migratsiyagacha o'qilishi uchun
  confirmed: 'bg-indigo-100 text-indigo-700',
  in_production: 'bg-orange-100 text-orange-700',
  paid: 'bg-green-100 text-green-800',
  cancelled: 'bg-red-100 text-red-700',
};

// Interfeys tili — o'zbekcha (ilovaning qolgan qismi kabi)
const STATUS_LABELS: Record<string, string> = {
  new: 'Navbatda',
  ready: 'Tayyor bo\'ldi',
  delivered: 'Yetkazildi',
  rejected: 'Rad etildi',
  // legacy
  confirmed: 'Tasdiqlangan',
  in_production: 'Ishlab chiqarishda',
  paid: 'To\'langan',
  cancelled: 'Bekor qilingan',
};

interface Props {
  status: string;
  className?: string;
}

export default function StatusBadge({ status, className }: Props) {
  const style = STATUS_STYLES[status] || 'bg-gray-100 text-gray-700';
  return (
    <span className={cn('badge', style, className)}>
      {STATUS_LABELS[status] || status}
    </span>
  );
}
