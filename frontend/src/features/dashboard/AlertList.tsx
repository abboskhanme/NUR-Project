import { ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ShieldCheck, Wrench, CalendarClock, PackageMinus, HandCoins, ListOrdered,
} from 'lucide-react';

import { formatUZS } from '@/lib/format';
import type { DashboardAlerts } from './types';

interface AlertRow {
  icon: ReactNode;
  label: string;
  value: string;
  tone: 'warning' | 'danger' | 'primary';
  to?: string;
  show: boolean;
}

export default function AlertList({ alerts }: { alerts?: DashboardAlerts }) {
  const navigate = useNavigate();
  const a = alerts;

  const rows: AlertRow[] = [
    {
      icon: <ShieldCheck size={16} />,
      label: 'Kafolat tugaydi (30 kun)',
      value: a ? `${a.warranty_expiring} ta` : '—',
      tone: 'warning',
      to: '/service',
      show: !a || a.warranty_expiring > 0,
    },
    {
      icon: <Wrench size={16} />,
      label: 'Yangi servis arizalari',
      value: a ? `${a.service_new} ta` : '—',
      tone: 'warning',
      to: '/service',
      show: !a || a.service_new > 0,
    },
    {
      icon: <CalendarClock size={16} />,
      label: 'Rejalashtirilgan tashriflar',
      value: a ? `${a.service_scheduled} ta` : '—',
      tone: 'primary',
      to: '/service',
      show: !a || a.service_scheduled > 0,
    },
    {
      icon: <PackageMinus size={16} />,
      label: 'Kam qolgan tovarlar',
      value: a ? `${a.low_stock} ta` : '—',
      tone: 'danger',
      to: '/supply',
      show: !a || a.low_stock > 0,
    },
    {
      icon: <HandCoins size={16} />,
      label: "Ta'minotchilarga qarz",
      value: a ? formatUZS(a.vendor_debt_uzs) : '—',
      tone: 'danger',
      to: '/supply',
      show: !a || a.vendor_debt_uzs > 0,
    },
    {
      icon: <ListOrdered size={16} />,
      label: 'Navbatdagi buyurtmalar',
      value: a ? `${a.queue_count} ta` : '—',
      tone: 'primary',
      to: '/queue',
      show: !a || a.queue_count > 0,
    },
  ];

  const visible = rows.filter((r) => r.show);

  if (a && visible.length === 0) {
    return <div className="text-sm text-ink-soft py-4 text-center">Faol eslatmalar yo'q ✓</div>;
  }

  const toneClass = (t: AlertRow['tone']) =>
    t === 'danger' ? 'text-danger' : t === 'warning' ? 'text-warning' : 'text-primary';

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
            <span className="text-ink">{r.label}</span>
          </span>
          <span className={`font-semibold ${toneClass(r.tone)}`}>{r.value}</span>
        </button>
      ))}
    </div>
  );
}
