import { useState } from 'react';
import { ShoppingCart, Wallet, Wrench, Truck } from 'lucide-react';

import DateRangeFilter, { presetRange } from '@/features/reports/DateRangeFilter';
import SalesReport from '@/features/reports/SalesReport';
import FinanceReport from '@/features/reports/FinanceReport';
import ServiceReport from '@/features/reports/ServiceReport';
import SupplyReport from '@/features/reports/SupplyReport';
import { formatDate } from '@/lib/format';
import type { DateRange } from '@/features/reports/types';

type Tab = 'sales' | 'finance' | 'service' | 'supply';
type Preset = 'this_month' | 'last_month' | 'last_30' | 'last_90' | 'this_year';

const TABS: Array<{ key: Tab; label: string; icon: typeof ShoppingCart }> = [
  { key: 'sales', label: 'Sotuv', icon: ShoppingCart },
  { key: 'finance', label: 'Moliya', icon: Wallet },
  { key: 'service', label: 'Servis', icon: Wrench },
  { key: 'supply', label: "Ta'minot", icon: Truck },
];

export default function ReportsPage() {
  const [tab, setTab] = useState<Tab>('sales');
  const [preset, setPreset] = useState<Preset | null>('this_month');
  const [range, setRange] = useState<DateRange>(() => presetRange('this_month'));

  function applyPreset(p: Preset) {
    setPreset(p);
    setRange(presetRange(p));
  }
  function applyRange(r: DateRange) {
    setPreset(null); // qo'lda tahrirlanganda preset bekor
    setRange(r);
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Hisobotlar</h1>
          <p className="text-sm text-ink-soft">
            {formatDate(range.from)} — {formatDate(range.to)}
          </p>
        </div>
      </div>

      {/* Davr filtri */}
      <div className="card !p-3">
        <DateRangeFilter
          range={range}
          onChange={applyRange}
          activePreset={preset}
          onPreset={applyPreset}
        />
      </div>

      {/* Bo'lim tablari */}
      <div className="flex gap-1 border-b border-black/10 overflow-x-auto">
        {TABS.map((t) => {
          const Icon = t.icon;
          return (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 -mb-px whitespace-nowrap transition ${
                tab === t.key
                  ? 'border-primary text-primary'
                  : 'border-transparent text-ink-soft hover:text-ink'
              }`}
            >
              <Icon size={16} /> {t.label}
            </button>
          );
        })}
      </div>

      {tab === 'sales' && <SalesReport range={range} />}
      {tab === 'finance' && <FinanceReport range={range} />}
      {tab === 'service' && <ServiceReport range={range} />}
      {tab === 'supply' && <SupplyReport range={range} />}
    </div>
  );
}
