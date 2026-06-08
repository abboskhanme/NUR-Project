import { ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  ShieldCheck, Wrench, CalendarClock, PackageMinus, HandCoins, ListOrdered,
} from 'lucide-react';

import { formatUZS } from '@/lib/format';
import type { DashboardAlerts } from './types';

interface AlertRow {
  icon: ReactNode;
  labelKey: string;
  value: string;
  tone: 'warning' | 'danger' | 'primary';
  to?: string;
  show: boolean;
}

export default function AlertList({ alerts }: { alerts?: DashboardAlerts }) {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const a = alerts;

  const rows: AlertRow[] = [
    {
      icon: <ShieldCheck size={16} />,
      labelKey: 'dashboard.alerts.warrantyExpiring',
      value: a ? t('dashboard.alerts.countUnit', { count: a.warranty_expiring }) : '—',
      tone: 'warning',
      to: '/service',
      show: !a || a.warranty_expiring > 0,
    },
    {
      icon: <Wrench size={16} />,
      labelKey: 'dashboard.alerts.serviceNew',
      value: a ? t('dashboard.alerts.countUnit', { count: a.service_new }) : '—',
      tone: 'warning',
      to: '/service',
      show: !a || a.service_new > 0,
    },
    {
      icon: <CalendarClock size={16} />,
      labelKey: 'dashboard.alerts.serviceScheduled',
      value: a ? t('dashboard.alerts.countUnit', { count: a.service_scheduled }) : '—',
      tone: 'primary',
      to: '/service',
      show: !a || a.service_scheduled > 0,
    },
    {
      icon: <PackageMinus size={16} />,
      labelKey: 'dashboard.alerts.lowStock',
      value: a ? t('dashboard.alerts.countUnit', { count: a.low_stock }) : '—',
      tone: 'danger',
      to: '/supply',
      show: !a || a.low_stock > 0,
    },
    {
      icon: <HandCoins size={16} />,
      labelKey: 'dashboard.alerts.vendorDebt',
      value: a ? formatUZS(a.vendor_debt_uzs) : '—',
      tone: 'danger',
      to: '/supply',
      show: !a || a.vendor_debt_uzs > 0,
    },
    {
      icon: <ListOrdered size={16} />,
      labelKey: 'dashboard.alerts.queueCount',
      value: a ? t('dashboard.alerts.countUnit', { count: a.queue_count }) : '—',
      tone: 'primary',
      to: '/queue',
      show: !a || a.queue_count > 0,
    },
  ];

  const visible = rows.filter((r) => r.show);

  if (a && visible.length === 0) {
    return <div className="text-sm text-ink-soft py-4 text-center">{t('dashboard.alerts.noAlerts')}</div>;
  }

  const toneClass = (tone: AlertRow['tone']) =>
    tone === 'danger' ? 'text-danger' : tone === 'warning' ? 'text-warning' : 'text-primary';

  return (
    <div className="space-y-1">
      {visible.map((r, i) => (
        <button
          key={i}
          onClick={() => r.to && navigate(r.to)}
          className="w-full flex items-center justify-between gap-2 rounded-button px-2 py-2 text-sm hover:bg-primary/5 transition text-left"
        >
          <span className={`flex items-center gap-2 ${toneClass(r.tone)}`}>
            {r.icon}
            <span className="text-ink">{t(r.labelKey)}</span>
          </span>
          <span className={`font-semibold ${toneClass(r.tone)}`}>{r.value}</span>
        </button>
      ))}
    </div>
  );
}
