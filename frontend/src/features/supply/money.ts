// Ta'minot modali uchun kichik summa formatlovchilar (so'm)

/** "2000000" -> "2 000 000" (mingliklarni bo'shliq bilan) */
export function formatAmount(s: string): string {
  const cleaned = s.replace(/[^\d.]/g, '');
  const firstDot = cleaned.indexOf('.');
  const intPart = (firstDot === -1 ? cleaned : cleaned.slice(0, firstDot)).replace(/^0+(?=\d)/, '');
  const intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  if (firstDot === -1) return intFmt;
  const decPart = cleaned.slice(firstDot + 1).replace(/\./g, '').slice(0, 2);
  return `${intFmt || '0'}.${decPart}`;
}

export const toNum = (s: string) => parseFloat(String(s).replace(/[^\d.]/g, '')) || 0;

export const UNITS = ['dona', 'kg', 'gr', 'metr', 'list', 'litr', 'rulon', 'quti'];

export const today = () => new Date().toISOString().slice(0, 10);
