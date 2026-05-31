import { useEffect, useMemo, useRef, useState } from 'react';
import { ChevronDown } from 'lucide-react';

export interface Country {
  code: string;
  name: string;
  dialCode: string;
  flagCodes: string;   // Twemoji hex code'lar, '-' bilan ajratilgan
  format: string;
  maxDigits: number;
}

// Twemoji CDN — bayroqlarni SVG sifatida olamiz (Windows'da ham ishlaydi)
const TWEMOJI_BASE = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/svg';

// 6 davlat
export const COUNTRIES: Country[] = [
  { code: 'UZ', name: "O'zbekiston", dialCode: '+998', flagCodes: '1f1fa-1f1ff', format: 'XX XXX XX XX', maxDigits: 9 },
  { code: 'RU', name: 'Rossiya',     dialCode: '+7',   flagCodes: '1f1f7-1f1fa', format: 'XXX XXX XX XX', maxDigits: 10 },
  { code: 'KZ', name: "Qozog'iston", dialCode: '+7',   flagCodes: '1f1f0-1f1ff', format: 'XXX XXX XX XX', maxDigits: 10 },
  { code: 'KG', name: "Qirg'iziston", dialCode: '+996', flagCodes: '1f1f0-1f1ec', format: 'XXX XXX XXX',  maxDigits: 9 },
  { code: 'TJ', name: 'Tojikiston',  dialCode: '+992', flagCodes: '1f1f9-1f1ef', format: 'XX XXX XXXX',   maxDigits: 9 },
  { code: 'TR', name: 'Turkiya',     dialCode: '+90',  flagCodes: '1f1f9-1f1f7', format: 'XXX XXX XX XX', maxDigits: 10 },
];

const DEFAULT_COUNTRY = COUNTRIES[0];

function onlyDigits(s: string): string {
  return s.replace(/\D/g, '');
}

function detectCountry(value: string): Country {
  const d = onlyDigits(value);
  const sorted = [...COUNTRIES].sort((a, b) => b.dialCode.length - a.dialCode.length);
  for (const c of sorted) {
    const dialDigits = onlyDigits(c.dialCode);
    if (d.startsWith(dialDigits)) return c;
  }
  return DEFAULT_COUNTRY;
}

function applyMask(digits: string, country: Country): string {
  const trimmed = digits.slice(0, country.maxDigits);
  let result = '';
  let di = 0;
  for (const ch of country.format) {
    if (di >= trimmed.length) break;
    if (ch === 'X') {
      result += trimmed[di];
      di++;
    } else {
      result += ch;
    }
  }
  return result;
}

function stripDial(value: string, country: Country): string {
  const digits = onlyDigits(value);
  const dialDigits = onlyDigits(country.dialCode);
  if (digits.startsWith(dialDigits)) return digits.slice(dialDigits.length);
  return digits;
}

/** Bayroq SVG / fallback rangli badge */
function Flag({ country, size = 20 }: { country: Country; size?: number }) {
  const [err, setErr] = useState(false);
  if (err) {
    // Twemoji yuklanmasa — rangli badge fallback
    return (
      <span
        className="inline-flex items-center justify-center rounded-sm bg-primary/10 text-primary text-[9px] font-bold leading-none shrink-0"
        style={{ width: size * 1.4, height: size, fontSize: size * 0.5 }}
      >
        {country.code}
      </span>
    );
  }
  return (
    <img
      src={`${TWEMOJI_BASE}/${country.flagCodes}.svg`}
      alt={country.code}
      onError={() => setErr(true)}
      className="rounded-sm shrink-0 object-cover"
      style={{ width: size * 1.4, height: size }}
      loading="lazy"
    />
  );
}

export default function PhoneInput({
  value,
  onChange,
  placeholder,
  disabled,
  countries = COUNTRIES,
  defaultCountry,
  id,
}: {
  value: string;
  onChange: (val: string) => void;
  placeholder?: string;
  disabled?: boolean;
  countries?: Country[];
  defaultCountry?: string;
  id?: string;
}) {
  const [country, setCountry] = useState<Country>(() => {
    if (value) return detectCountry(value);
    if (defaultCountry) {
      const found = countries.find((c) => c.code === defaultCountry);
      if (found) return found;
    }
    return countries[0] || DEFAULT_COUNTRY;
  });
  const [open, setOpen] = useState(false);
  const popoverRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!value) return;
    const detected = detectCountry(value);
    if (detected.code !== country.code || detected.dialCode !== country.dialCode) {
      setCountry(detected);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const localValue = useMemo(() => {
    const national = stripDial(value, country);
    return applyMask(national, country);
  }, [value, country]);

  function emit(nationalDigits: string, c: Country) {
    const trimmed = nationalDigits.slice(0, c.maxDigits);
    if (trimmed.length === 0) {
      onChange('');
      return;
    }
    const formatted = applyMask(trimmed, c);
    onChange(`${c.dialCode} ${formatted}`);
  }

  function handleInputChange(raw: string) {
    const digits = onlyDigits(raw);
    emit(digits, country);
  }

  function selectCountry(c: Country) {
    setOpen(false);
    if (c.code === country.code && c.dialCode === country.dialCode) return;
    const oldNational = stripDial(value, country);
    setCountry(c);
    emit(oldNational, c);
  }

  return (
    <div className="flex gap-2 w-full">
      <div className="relative shrink-0">
        <button
          type="button"
          onClick={() => !disabled && setOpen((o) => !o)}
          disabled={disabled}
          className="input flex items-center gap-2 !py-2 hover:bg-black/[0.03] disabled:opacity-60"
          aria-label="Davlat"
        >
          <Flag country={country} size={18} />
          <span className="text-sm font-medium">{country.code}</span>
          <ChevronDown size={14} className={'transition-transform ' + (open ? 'rotate-180' : '')} />
        </button>
        {open && (
          <>
            <div className="fixed inset-0 z-30" onClick={() => setOpen(false)} />
            <div
              ref={popoverRef}
              className="absolute z-40 mt-1 w-64 max-h-72 overflow-y-auto bg-card border border-black/10 rounded-button shadow-lg"
            >
              {countries.map((c) => {
                const active = c.code === country.code;
                return (
                  <button
                    type="button"
                    key={c.code}
                    onClick={() => selectCountry(c)}
                    className={
                      'w-full flex items-center gap-2 px-3 py-2 text-sm text-left hover:bg-black/5 ' +
                      (active ? 'bg-primary/5' : '')
                    }
                  >
                    <Flag country={c} size={18} />
                    <span className="font-medium w-6">{c.code}</span>
                    <span className="text-ink/80 truncate flex-1">{c.name}</span>
                    <span className="text-ink-soft text-xs">{c.dialCode}</span>
                  </button>
                );
              })}
            </div>
          </>
        )}
      </div>
      <input
        id={id}
        type="tel"
        inputMode="tel"
        className="input flex-1 min-w-0"
        value={localValue}
        onChange={(e) => handleInputChange(e.target.value)}
        placeholder={placeholder ?? country.format}
        disabled={disabled}
        autoComplete="tel-national"
      />
    </div>
  );
}
