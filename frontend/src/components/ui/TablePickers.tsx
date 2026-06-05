import { ReactNode, useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { Check, ChevronDown, ChevronLeft, ChevronRight, Search } from 'lucide-react';

/**
 * Jadval kataklari uchun ixcham, chiroyli popover'li tanlagichlar:
 *  - CellSelect — custom dropdown (Select.tsx uslubida)
 *  - CellDate   — custom kalendar (native date picker o'rniga)
 * Popover `position: fixed` + portal bilan chiqadi, shuning uchun
 * jadvalning overflow-x-auto konteyneri uni kesib qo'ymaydi.
 */

const MONTHS = ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr'];
const WEEKDAYS = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

const pad = (n: number) => String(n).padStart(2, '0');
const todayIso = () => {
  const d = new Date();
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};
const isoToDisplay = (iso: string) => {
  const [y, m, d] = (iso || '').split('-');
  return y && m && d ? `${d}.${m}.${y}` : '';
};

function Popover({ anchorRef, onClose, width, children }: {
  anchorRef: React.RefObject<HTMLElement>;
  onClose: () => void;
  width: number;
  children: ReactNode;
}) {
  const popRef = useRef<HTMLDivElement>(null);
  const [style, setStyle] = useState<React.CSSProperties | null>(null);

  useEffect(() => {
    const r = anchorRef.current?.getBoundingClientRect();
    if (!r) return;
    const w = Math.max(width, r.width);
    const left = Math.max(8, Math.min(r.left, window.innerWidth - w - 8));
    const below = window.innerHeight - r.bottom;
    const s: React.CSSProperties = { position: 'fixed', left, width: w, zIndex: 50 };
    if (below < 340 && r.top > 340) s.bottom = window.innerHeight - r.top + 4;
    else s.top = r.bottom + 4;
    setStyle(s);

    // Sahifa/jadval scroll bo'lsa popover joyidan siljib qolmasin — yopamiz
    const onScroll = (e: Event) => {
      if (popRef.current && e.target instanceof Node && popRef.current.contains(e.target)) return;
      onClose();
    };
    window.addEventListener('scroll', onScroll, true);
    window.addEventListener('resize', onClose);
    return () => {
      window.removeEventListener('scroll', onScroll, true);
      window.removeEventListener('resize', onClose);
    };
  }, [anchorRef, onClose, width]);

  if (!style) return null;
  return createPortal(
    <>
      <div className="fixed inset-0 z-40" onClick={onClose} />
      <div ref={popRef} style={style}
           className="bg-card border border-black/10 rounded-xl shadow-xl overflow-hidden">
        {children}
      </div>
    </>,
    document.body,
  );
}

// ---------- CellSelect ----------
export interface CellOption { value: string; label: string }

export function CellSelect({
  value, onChange, options, placeholder = '—', allowEmpty = false, emptyLabel = '—',
  triggerClassName = '', valueClassName = '', hideChevron = false,
}: {
  value: string;
  onChange: (val: string) => void;
  options: CellOption[];
  placeholder?: string;
  allowEmpty?: boolean;
  emptyLabel?: string;
  triggerClassName?: string;
  valueClassName?: string;
  hideChevron?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const btnRef = useRef<HTMLButtonElement>(null);

  const selected = options.find((o) => o.value === value);
  const searchable = options.length > 8;
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return q ? options.filter((o) => o.label.toLowerCase().includes(q)) : options;
  }, [options, query]);

  function close() { setOpen(false); setQuery(''); }
  function pick(v: string) { onChange(v); close(); }

  return (
    <>
      <button ref={btnRef} type="button" onClick={() => setOpen((o) => !o)}
              className={triggerClassName + ' flex items-center justify-between gap-1 text-left'}>
        <span className={'truncate flex-1 ' + valueClassName + (selected ? '' : ' text-ink/40')}>
          {selected ? selected.label : placeholder}
        </span>
        {!hideChevron && (
          <ChevronDown size={13}
                       className={'shrink-0 text-ink/40 transition-transform duration-150 ' + (open ? 'rotate-180' : '')} />
        )}
      </button>
      {open && (
        <Popover anchorRef={btnRef} onClose={close} width={210}>
          {searchable && (
            <div className="flex items-center gap-2 px-3 py-2 border-b border-black/5">
              <Search size={14} className="text-ink/40 shrink-0" />
              <input autoFocus value={query} onChange={(e) => setQuery(e.target.value)}
                     placeholder="Qidirish..." className="w-full bg-transparent outline-none text-sm" />
            </div>
          )}
          <div className="max-h-60 overflow-y-auto p-1">
            {allowEmpty && !query && (
              <button type="button" onClick={() => pick('')}
                      className={'w-full flex items-center justify-between gap-2 px-3 py-1.5 text-sm text-left rounded-lg ' +
                        (!value ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-black/5 text-ink/60')}>
                {emptyLabel}
                {!value && <Check size={14} className="shrink-0" />}
              </button>
            )}
            {filtered.length === 0 ? (
              <p className="px-3 py-3 text-sm text-ink-soft text-center">Topilmadi</p>
            ) : filtered.map((o) => {
              const active = o.value === value;
              return (
                <button type="button" key={o.value} onClick={() => pick(o.value)}
                        className={'w-full flex items-center gap-2 px-3 py-1.5 text-sm text-left rounded-lg ' +
                          (active ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-black/5')}>
                  <span className="truncate flex-1">{o.label}</span>
                  {active && <Check size={14} className="shrink-0" />}
                </button>
              );
            })}
          </div>
        </Popover>
      )}
    </>
  );
}

// ---------- CellDate ----------
export function CellDate({
  value, onChange, clearable = true, placeholder = 'kun.oy.yil', triggerClassName = '',
}: {
  value: string;                       // ISO yyyy-mm-dd yoki ''
  onChange: (iso: string) => void;
  clearable?: boolean;
  placeholder?: string;
  triggerClassName?: string;
}) {
  const [open, setOpen] = useState(false);
  const btnRef = useRef<HTMLButtonElement>(null);
  const base = value ? new Date(value + 'T00:00:00') : new Date();
  const [vy, setVy] = useState(base.getFullYear());
  const [vm, setVm] = useState(base.getMonth());

  useEffect(() => {
    if (!open) return;
    const d = value ? new Date(value + 'T00:00:00') : new Date();
    setVy(d.getFullYear()); setVm(d.getMonth());
  }, [open, value]);

  function nav(diff: number) {
    const d = new Date(vy, vm + diff, 1);
    setVy(d.getFullYear()); setVm(d.getMonth());
  }
  function pick(day: number) {
    onChange(`${vy}-${pad(vm + 1)}-${pad(day)}`);
    setOpen(false);
  }

  const firstWd = (new Date(vy, vm, 1).getDay() + 6) % 7; // Dushanba = 0
  const daysIn = new Date(vy, vm + 1, 0).getDate();
  const tIso = todayIso();

  return (
    <>
      <button ref={btnRef} type="button" onClick={() => setOpen((o) => !o)}
              className={triggerClassName + ' text-left'}>
        <span className={'truncate ' + (value ? '' : 'text-ink/35')}>
          {value ? isoToDisplay(value) : placeholder}
        </span>
      </button>
      {open && (
        <Popover anchorRef={btnRef} onClose={() => setOpen(false)} width={252}>
          <div className="p-2.5 select-none">
            {/* Oy navigatsiyasi */}
            <div className="flex items-center justify-between mb-1.5">
              <button type="button" onClick={() => nav(-1)}
                      className="p-1.5 rounded-lg hover:bg-black/5 text-ink/60"><ChevronLeft size={15} /></button>
              <span className="text-sm font-semibold">{MONTHS[vm]} {vy}</span>
              <button type="button" onClick={() => nav(1)}
                      className="p-1.5 rounded-lg hover:bg-black/5 text-ink/60"><ChevronRight size={15} /></button>
            </div>
            {/* Hafta kunlari */}
            <div className="grid grid-cols-7 mb-0.5">
              {WEEKDAYS.map((w) => (
                <span key={w} className="text-center text-[11px] font-medium text-ink/40 py-1">{w}</span>
              ))}
            </div>
            {/* Kunlar */}
            <div className="grid grid-cols-7 gap-y-0.5">
              {Array.from({ length: firstWd }).map((_, i) => <span key={'b' + i} />)}
              {Array.from({ length: daysIn }).map((_, i) => {
                const day = i + 1;
                const iso = `${vy}-${pad(vm + 1)}-${pad(day)}`;
                const isSel = iso === value;
                const isToday = iso === tIso;
                return (
                  <button type="button" key={day} onClick={() => pick(day)}
                          className={'h-7 w-7 mx-auto flex items-center justify-center rounded-full text-[13px] transition-colors ' +
                            (isSel ? 'bg-primary text-white font-semibold'
                              : isToday ? 'text-primary font-semibold ring-1 ring-primary/40 hover:bg-primary/10'
                              : 'hover:bg-black/5')}>
                    {day}
                  </button>
                );
              })}
            </div>
            {/* Pastki amallar */}
            <div className="flex items-center justify-between mt-2 pt-2 border-t border-black/5">
              {clearable && value ? (
                <button type="button" onClick={() => { onChange(''); setOpen(false); }}
                        className="text-xs text-ink/50 hover:text-danger px-1.5 py-1 rounded">Tozalash</button>
              ) : <span />}
              <button type="button" onClick={() => { onChange(todayIso()); setOpen(false); }}
                      className="text-xs text-primary font-medium px-1.5 py-1 rounded hover:bg-primary/10">Bugun</button>
            </div>
          </div>
        </Popover>
      )}
    </>
  );
}
