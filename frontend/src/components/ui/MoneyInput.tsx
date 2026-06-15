import { useState } from 'react';
import { formatNumberInput, parseNumberInput } from '@/lib/format';

/**
 * Pul/son kiritish maydoni — yozish jarayonida 3 xonadan bo'sh joy bilan
 * ajratib formatlaydi (1 234 567). Tashqariga toza son (number) qaytaradi.
 */
export default function MoneyInput({
  value, onChange, className = 'input', placeholder, autoFocus, suffix, id,
}: {
  value: number;
  onChange: (n: number) => void;
  className?: string;
  placeholder?: string;
  autoFocus?: boolean;
  suffix?: string;
  id?: string;
}) {
  const [text, setText] = useState(value ? formatNumberInput(String(value)) : '');

  function handle(e: React.ChangeEvent<HTMLInputElement>) {
    const formatted = formatNumberInput(e.target.value);
    setText(formatted);
    onChange(parseNumberInput(formatted));
  }

  const input = (
    <input
      id={id}
      className={suffix ? `${className} pr-16` : className}
      inputMode="decimal"
      placeholder={placeholder}
      autoFocus={autoFocus}
      value={text}
      onChange={handle}
    />
  );

  if (!suffix) return input;
  return (
    <div className="relative">
      {input}
      <span className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-ink-soft pointer-events-none">
        {suffix}
      </span>
    </div>
  );
}
