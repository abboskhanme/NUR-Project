import { useTranslation } from 'react-i18next';
import DateInput from '@/components/ui/DateInput';
import type { DateRange } from './types';

/** Tayyor davr presetlari. */
type Preset = 'this_month' | 'last_month' | 'last_30' | 'last_90' | 'this_year';

const PRESET_KEYS: Preset[] = ['this_month', 'last_month', 'last_30', 'last_90', 'this_year'];

const iso = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

export function presetRange(p: Preset): DateRange {
  const now = new Date();
  const y = now.getFullYear();
  const m = now.getMonth();
  switch (p) {
    case 'this_month':
      return { from: iso(new Date(y, m, 1)), to: iso(now) };
    case 'last_month':
      return { from: iso(new Date(y, m - 1, 1)), to: iso(new Date(y, m, 0)) };
    case 'last_30':
      return { from: iso(new Date(now.getTime() - 29 * 864e5)), to: iso(now) };
    case 'last_90':
      return { from: iso(new Date(now.getTime() - 89 * 864e5)), to: iso(now) };
    case 'this_year':
      return { from: iso(new Date(y, 0, 1)), to: iso(now) };
  }
}

interface Props {
  range: DateRange;
  onChange: (r: DateRange) => void;
  activePreset?: Preset | null;
  onPreset?: (p: Preset) => void;
}

export default function DateRangeFilter({ range, onChange, activePreset, onPreset }: Props) {
  const { t } = useTranslation();

  return (
    <div className="flex flex-wrap items-center gap-2">
      <div className="flex flex-wrap gap-1.5">
        {PRESET_KEYS.map((key) => (
          <button
            key={key}
            onClick={() => onPreset?.(key)}
            className={`px-3 py-1.5 rounded-button text-sm border transition ${
              activePreset === key
                ? 'bg-primary text-white border-primary'
                : 'bg-white text-ink border-black/10 hover:border-primary/40'
            }`}
          >
            {t(`reports.presets.${key}`)}
          </button>
        ))}
      </div>
      <div className="flex items-center gap-2 ml-auto">
        <DateInput
          value={range.from}
          onChange={(v) => onChange({ ...range, from: v })}
          className="w-36"
        />
        <span className="text-ink-soft">—</span>
        <DateInput
          value={range.to}
          onChange={(v) => onChange({ ...range, to: v })}
          className="w-36"
        />
      </div>
    </div>
  );
}
