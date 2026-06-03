// CSV eksport yordamchisi — hisobot jadvallarini yuklab olish uchun.

type Row = Record<string, unknown>;

/** Qiymatni CSV katakchasi uchun xavfsiz ko'rinishga keltiradi. */
function cell(value: unknown): string {
  if (value == null) return '';
  const s = String(value);
  if (/[",\n;]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

/**
 * Massiv obyektlarini CSV faylga eksport qiladi va brauzerda yuklab olishni boshlaydi.
 * @param rows   ma'lumot qatorlari
 * @param columns ustunlar: { key, label }
 * @param filename fayl nomi (.csv qo'shiladi)
 */
export function exportCSV(
  rows: Row[],
  columns: Array<{ key: string; label: string }>,
  filename: string,
): void {
  const header = columns.map((c) => cell(c.label)).join(';');
  const body = rows
    .map((r) => columns.map((c) => cell(r[c.key])).join(';'))
    .join('\n');
  // BOM — Excel UTF-8 ni to'g'ri o'qishi uchun
  const csv = '﻿' + header + '\n' + body;

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename.endsWith('.csv') ? filename : `${filename}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
