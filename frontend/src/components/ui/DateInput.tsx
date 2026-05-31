import { useEffect, useState } from 'react';
import { Calendar } from 'lucide-react';
import { cn } from '@/lib/cn';

/**
 * dd.mm.yyyy ko'rinishidagi sana inputi.
 * value/onChange ISO formatda (yyyy-mm-dd) ishlaydi, ko'rsatish esa kun.oy.yil.
 */
function isoToDisplay(iso: string): string {
  if (!iso) return '';
  const [y, m, d] = iso.split('-');
  if (!y || !m || !d) return '';
  return `${d}.${m}.${y}`;
}

function formatDigits(digits: string): string {
  digits = digits.slice(0, 8);
  const parts: string[] = [digits.slice(0, 2)];
  if (digits.length > 2) parts.push(digits.slice(2, 4));
  if (digits.length > 4) parts.push(digits.slice(4, 8));
  return parts.join('.');
}

function toIso(digits: string): string | null {
  if (digits.length !== 8) return null;
  const d = digits.slice(0, 2), m = digits.slice(2, 4), y = digits.slice(4, 8);
  const dd = parseInt(d, 10), mm = parseInt(m, 10), yy = parseInt(y, 10);
  if (mm < 1 || mm > 12 || dd < 1 || dd > 31 || yy < 1900) return null;
  const dt = new Date(yy, mm - 1, dd);
  if (dt.getFullYear() !== yy || dt.getMonth() !== mm - 1 || dt.getDate() !== dd) return null;
  return `${y}-${m}-${d}`;
}

interface Props {
  value: string;                       // ISO yyyy-mm-dd yoki ''
  onChange: (iso: string) => void;
  placeholder?: string;
  className?: string;
}

export default function DateInput({ value, onChange, placeholder = 'kun.oy.yil', className }: Props) {
  const [text, setText] = useState(isoToDisplay(value));

  useEffect(() => { setText(isoToDisplay(value)); }, [value]);

  function handle(e: React.ChangeEvent<HTMLInputElement>) {
    const digits = e.target.value.replace(/\D/g, '');
    setText(formatDigits(digits));
    if (digits.length === 0) {
      onChange('');
    } else {
      const iso = toIso(digits);
      if (iso) onChange(iso);
    }
  }

  return (
    <div className={cn(
      'flex items-center gap-2 rounded-button border border-black/10 px-3 py-2 bg-white',
      className,
    )}>
      <Calendar size={15} className="text-ink/40 shrink-0" />
      <input
        value={text}
        onChange={handle}
        placeholder={placeholder}
        inputMode="numeric"
        maxLength={10}
        className="bg-transparent outline-none w-full text-sm"
      />
    </div>
  );
}
