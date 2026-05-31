import { useEffect, useRef, useState } from 'react';
import { ChevronDown, Check } from 'lucide-react';

import { useUIStore } from '@/stores/ui';

type Locale = 'uz' | 'ru' | 'en';

// Ichki SVG bayroqlar — tashqi CDN'siz, hamma joyda bir xil chiqadi
function FlagUZ() {
  return (
    <svg viewBox="0 0 60 30" className="w-5 h-3.5 rounded-[2px] shrink-0">
      <rect width="60" height="10" y="0" fill="#0099b5" />
      <rect width="60" height="10" y="10" fill="#fff" />
      <rect width="60" height="10" y="20" fill="#1eb53a" />
      <rect width="60" height="1.4" y="9.3" fill="#ce1126" />
      <rect width="60" height="1.4" y="19.3" fill="#ce1126" />
      <circle cx="9" cy="5" r="3" fill="#fff" />
      <circle cx="10.7" cy="5" r="3" fill="#0099b5" />
    </svg>
  );
}
function FlagRU() {
  return (
    <svg viewBox="0 0 60 30" className="w-5 h-3.5 rounded-[2px] shrink-0">
      <rect width="60" height="10" y="0" fill="#fff" />
      <rect width="60" height="10" y="10" fill="#0039a6" />
      <rect width="60" height="10" y="20" fill="#d52b1e" />
    </svg>
  );
}
function FlagEN() {
  return (
    <svg viewBox="0 0 60 30" className="w-5 h-3.5 rounded-[2px] shrink-0">
      <clipPath id="lsuk"><path d="M0,0 v30 h60 v-30 z" /></clipPath>
      <clipPath id="lsukt"><path d="M30,15 h30 v15 z v15 h-30 z h-30 v-15 z v-15 h30 z" /></clipPath>
      <g clipPath="url(#lsuk)">
        <path d="M0,0 v30 h60 v-30 z" fill="#012169" />
        <path d="M0,0 L60,30 M60,0 L0,30" stroke="#fff" strokeWidth="6" />
        <path d="M0,0 L60,30 M60,0 L0,30" clipPath="url(#lsukt)" stroke="#c8102e" strokeWidth="4" />
        <path d="M30,0 v30 M0,15 h60" stroke="#fff" strokeWidth="10" />
        <path d="M30,0 v30 M0,15 h60" stroke="#c8102e" strokeWidth="6" />
      </g>
    </svg>
  );
}

const LANGS: Array<{ code: Locale; label: string; flag: () => JSX.Element }> = [
  { code: 'uz', label: "O'zbekcha", flag: FlagUZ },
  { code: 'ru', label: 'Русский', flag: FlagRU },
  { code: 'en', label: 'English', flag: FlagEN },
];

export default function LanguageSwitcher() {
  const locale = useUIStore((s) => s.locale);
  const setLocale = useUIStore((s) => s.setLocale);
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', onClick);
    return () => document.removeEventListener('mousedown', onClick);
  }, []);

  const current = LANGS.find((l) => l.code === locale) ?? LANGS[0];

  return (
    <div className="relative" ref={ref}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex items-center gap-1.5 text-xs border border-black/10 rounded-button px-2 py-1.5 hover:bg-black/5"
      >
        <current.flag />
        <span className="uppercase font-medium">{current.code}</span>
        <ChevronDown size={14} className="text-ink/50" />
      </button>

      {open && (
        <div className="absolute right-0 mt-1 w-40 bg-card rounded-lg shadow-xl border border-black/5 py-1 z-50">
          {LANGS.map((l) => (
            <button
              key={l.code}
              type="button"
              onClick={() => { setLocale(l.code); setOpen(false); }}
              className="w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-black/5 text-left"
            >
              <l.flag />
              <span className="flex-1">{l.label}</span>
              {l.code === locale && <Check size={14} className="text-primary" />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
