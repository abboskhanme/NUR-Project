import DateInput from '@/components/ui/DateInput';
import type { DateRange } from './types';

/** Tayyor davr presetlari. */
type Preset = 'this_month' | 'last_month' | 'last_30' | 'last_90' | 'this_year';

const PRESETS: Array<{ key: Preset; label: string }> = [
  { key: 'this_month', label: 'Joriy oy' },
  { key: 'last_month', label: "O'tgan oy" },
  { key: 'last_30', label: '30 kun' },
  { key: 'last_90', label: '90 kun' },
  { key: 'this_year', label: 'Joriy yil' },
];

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
  return (
    <div className="flex flex-wrap items-center gap-2">
      <div className="flex flex-wrap gap-1.5">
        {PRESETS.map((p) => (
          <button
            key={p.key}
            onClick={() => onPreset?.(p.key)}
            className={`px-3 py-1.5 rounded-button text-sm border transition ${
              activePreset === p.key
                ? 'bg-primary text-white border-primary'
                : 'bg-white text-ink border-black/10 hover:border-primary/40'
            }`}
          >
            {p.label}
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
