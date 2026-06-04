import { ReactNode, useMemo, useState } from 'react';
import { Check, ChevronDown, Search } from 'lucide-react';

export interface SelectOption {
  value: string;
  label: string;
  icon?: ReactNode;
}

/**
 * Chiroyli custom dropdown — native <select> o'rniga.
 * PhoneInput'dagi popover uslubida: yumaloq burchaklar, soya, hover,
 * tanlanganda belgi (check), ko'p variantda qidiruv.
 */
export default function Select({
  value,
  onChange,
  options,
  placeholder = '—',
  allowEmpty = false,
  emptyLabel = '—',
  disabled = false,
  className = '',
}: {
  value: string;
  onChange: (val: string) => void;
  options: SelectOption[];
  placeholder?: string;
  allowEmpty?: boolean;
  emptyLabel?: string;
  disabled?: boolean;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');

  const selected = options.find((o) => o.value === value);
  const searchable = options.length > 8;

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter((o) => o.label.toLowerCase().includes(q));
  }, [options, query]);

  function pick(v: string) {
    onChange(v);
    setOpen(false);
    setQuery('');
  }

  return (
    <div className={'relative ' + className}>
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        className="input w-full flex items-center justify-between gap-2 text-left hover:bg-black/[0.03] disabled:opacity-60"
      >
        <span className="flex items-center gap-2 min-w-0 flex-1">
          {selected?.icon}
          <span className={'truncate ' + (selected ? '' : 'text-ink/40')}>
            {selected ? selected.label : placeholder}
          </span>
        </span>
        <ChevronDown size={15}
                     className={'shrink-0 text-ink/50 transition-transform duration-150 ' + (open ? 'rotate-180' : '')} />
      </button>

      {open && (
        <>
          {/* Tashqariga bosilganda yopish */}
          <div className="fixed inset-0 z-30" onClick={() => { setOpen(false); setQuery(''); }} />
          <div className="absolute z-40 mt-1.5 w-full min-w-[200px] bg-card border border-black/10 rounded-xl shadow-xl overflow-hidden">
            {searchable && (
              <div className="flex items-center gap-2 px-3 py-2 border-b border-black/5">
                <Search size={14} className="text-ink/40 shrink-0" />
                <input
                  autoFocus
                  className="w-full bg-transparent outline-none text-sm"
                  placeholder="Qidirish..."
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                />
              </div>
            )}
            <div className="max-h-60 overflow-y-auto p-1">
              {allowEmpty && !query && (
                <button type="button" onClick={() => pick('')}
                        className={'w-full flex items-center justify-between gap-2 px-3 py-2 text-sm text-left rounded-lg ' +
                          (!value ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-black/5 text-ink/60')}>
                  {emptyLabel}
                  {!value && <Check size={15} className="shrink-0" />}
                </button>
              )}
              {filtered.length === 0 ? (
                <p className="px-3 py-3 text-sm text-ink-soft text-center">Topilmadi</p>
              ) : (
                filtered.map((o) => {
                  const active = o.value === value;
                  return (
                    <button
                      type="button"
                      key={o.value}
                      onClick={() => pick(o.value)}
                      className={'w-full flex items-center gap-2 px-3 py-2 text-sm text-left rounded-lg ' +
                        (active ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-black/5')}
                    >
                      {o.icon}
                      <span className="truncate flex-1">{o.label}</span>
                      {active && <Check size={15} className="shrink-0" />}
                    </button>
                  );
                })
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
