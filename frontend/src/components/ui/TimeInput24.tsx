import { useEffect, useState } from 'react';
import { cn } from '@/lib/cn';

/**
 * 24-soatlik vaqt kiritish maydoni (HH:MM).
 * Native <input type="time"> brauzer tiliga qarab AM/PM ko'rsatishi mumkin —
 * bu komponent har doim 0–24 formatda ishlaydi.
 * Qiymat "HH:MM" ko'rinishida (yoki bo'sh "").
 */
export default function TimeInput24({
  value,
  onChange,
  disabled,
  className,
}: {
  value: string;
  onChange: (v: string) => void;
  disabled?: boolean;
  className?: string;
}) {
  const [text, setText] = useState(value || '');

  useEffect(() => {
    setText(value || '');
  }, [value]);

  function handleChange(raw: string) {
    let digits = raw.replace(/\D/g, '').slice(0, 4);
    // Soat va daqiqani cheklash
    if (digits.length >= 2) {
      let hh = parseInt(digits.slice(0, 2), 10);
      if (hh > 23) hh = 23;
      digits = String(hh).padStart(2, '0') + digits.slice(2);
    }
    if (digits.length === 4) {
      let mm = parseInt(digits.slice(2, 4), 10);
      if (mm > 59) mm = 59;
      digits = digits.slice(0, 2) + String(mm).padStart(2, '0');
    }
    const formatted = digits.length <= 2 ? digits : `${digits.slice(0, 2)}:${digits.slice(2)}`;
    setText(formatted);
    // To'liq HH:MM bo'lsa onChange, bo'sh bo'lsa tozalash
    if (formatted === '') onChange('');
    else if (digits.length === 4) onChange(`${digits.slice(0, 2)}:${digits.slice(2)}`);
  }

  function handleBlur() {
    // Yarim kiritilgan qiymatni tiklash
    setText(value || '');
  }

  return (
    <input
      type="text"
      inputMode="numeric"
      placeholder="--:--"
      className={cn('input text-center tabular-nums', className)}
      value={text}
      disabled={disabled}
      onChange={(e) => handleChange(e.target.value)}
      onBlur={handleBlur}
    />
  );
}
