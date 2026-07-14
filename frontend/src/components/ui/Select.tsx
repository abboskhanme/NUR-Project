import { ReactNode, useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { Check, ChevronDown, Search } from 'lucide-react';

export interface SelectOption {
  value: string;
  label: string;
  icon?: ReactNode;
}

/**
 * Chiroyli custom dropdown — native <select> o'rniga.
 * Ochilgan ro'yxat PORTAL + `position: fixed` bilan chiqadi, shuning uchun
 * modal yoki `overflow-y-auto` konteyner uni kesib qo'ymaydi (TablePickers uslubi).
 * Har variant `icon` (masalan mahsulot rasmi) ko'rsatishi mumkin — trigger'da ham.
 */
export default function Select({
  value,
  onChange,
  options,
  placeholder = '—',
  allowEmpty = false,
  emptyLabel = '—',
  disabled = false,
  invalid = false,
  className = '',
}: {
  value: string;
  onChange: (val: string) => void;
  options: SelectOption[];
  placeholder?: string;
  allowEmpty?: boolean;
  emptyLabel?: string;
  disabled?: boolean;
  invalid?: boolean;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const btnRef = useRef<HTMLButtonElement>(null);
  const popRef = useRef<HTMLDivElement>(null);
  const [style, setStyle] = useState<React.CSSProperties | null>(null);

  const selected = options.find((o) => o.value === value);
  const searchable = options.length > 8;

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter((o) => o.label.toLowerCase().includes(q));
  }, [options, query]);

  function close() {
    setOpen(false);
    setQuery('');
  }
  function pick(v: string) {
    onChange(v);
    close();
  }

  // Portal ro'yxatini trigger tugmasiga nisbatan joylashtirish (fixed).
  useEffect(() => {
    if (!open) {
      setStyle(null);
      return;
    }
    const place = () => {
      const r = btnRef.current?.getBoundingClientRect();
      if (!r) return;
      // Dropdown trigger'dan kengroq — uzun nomlar oxirigacha o'qilsin (min 340px),
      // lekin ekrandan chiqmasin.
      const w = Math.min(Math.max(r.width, 340), window.innerWidth - 16);
      const left = Math.max(8, Math.min(r.left, window.innerWidth - w - 8));
      const below = window.innerHeight - r.bottom;
      const above = r.top;
      // Pastda joy kam bo'lsa va tepada ko'proq bo'lsa — yuqoriga ochamiz
      const openUp = below < 280 && above > below;
      // Ekranda ko'rinadigan bo'sh joyga qarab balandlik — ko'proq element ko'rsatamiz
      const avail = (openUp ? above : below) - 16;
      const maxHeight = Math.max(200, Math.min(avail, 460));
      const s: React.CSSProperties = { position: 'fixed', left, width: w, zIndex: 60, maxHeight };
      if (openUp) s.bottom = window.innerHeight - r.top + 6;
      else s.top = r.bottom + 6;
      setStyle(s);
    };
    place();
    const onScroll = (e: Event) => {
      if (popRef.current && e.target instanceof Node && popRef.current.contains(e.target)) return;
      close();
    };
    window.addEventListener('scroll', onScroll, true);
    window.addEventListener('resize', close);
    return () => {
      window.removeEventListener('scroll', onScroll, true);
      window.removeEventListener('resize', close);
    };
  }, [open]);

  return (
    <div className={'relative ' + className}>
      <button
        ref={btnRef}
        type="button"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        className={'input w-full flex items-center justify-between gap-2 text-left hover:bg-black/[0.03] disabled:opacity-60 '
          + (invalid ? 'border-danger ring-1 ring-danger/40' : '')}
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

      {open && style && createPortal(
        <>
          <div className="fixed inset-0 z-[55]" onClick={close} />
          <div ref={popRef} style={style}
               className="bg-card border border-black/10 rounded-xl shadow-xl overflow-hidden flex flex-col">
            {searchable && (
              <div className="flex items-center gap-2 px-3 py-2 border-b border-black/5 shrink-0">
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
            <div className="flex-1 overflow-y-auto p-1 min-h-0">
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
        </>,
        document.body,
      )}
    </div>
  );
}
