// O'zbekiston formatlari

export function formatUZS(value: number | string | null | undefined): string {
  if (value == null || value === '') return '0';
  const n = typeof value === 'string' ? parseFloat(value) : value;
  if (Number.isNaN(n)) return '0';
  return n.toLocaleString('uz-UZ', { maximumFractionDigits: 0 }).replace(/,/g, ' ') + ' so\'m';
}

export function formatUSD(value: number | string | null | undefined): string {
  if (value == null || value === '') return '$0';
  const n = typeof value === 'string' ? parseFloat(value) : value;
  if (Number.isNaN(n)) return '$0';
  return '$' + n.toLocaleString('en-US', { maximumFractionDigits: 2 });
}

/** Valyutaga qarab formatlash: UZS -> so'm, USD -> $ */
export function formatMoney(
  value: number | string | null | undefined,
  currency?: string | null,
): string {
  return currency === 'USD' ? formatUSD(value) : formatUZS(value);
}

/**
 * Input ichida raqamni 3 xonadan bo'sh joy bilan ajratib ko'rsatish.
 * Masalan "1234567.5" -> "1 234 567.5". Faqat raqam va bitta nuqta qoladi.
 */
export function formatNumberInput(raw: string | number | null | undefined): string {
  if (raw == null) return '';
  let s = String(raw).replace(/[^\d.]/g, '');
  const dot = s.indexOf('.');
  if (dot !== -1) {
    s = s.slice(0, dot + 1) + s.slice(dot + 1).replace(/\./g, '');
  }
  const [intPart, decPart] = s.split('.');
  const cleanInt = (intPart || '').replace(/^0+(?=\d)/, '');
  const grouped = cleanInt.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return decPart !== undefined ? `${grouped}.${decPart}` : grouped;
}

/** Formatlangan input matnidan toza son olish. */
export function parseNumberInput(display: string | null | undefined): number {
  if (!display) return 0;
  const n = parseFloat(String(display).replace(/\s/g, ''));
  return Number.isNaN(n) ? 0 : n;
}

export function formatDate(d: string | Date | null | undefined): string {
  if (!d) return '—';
  const date = typeof d === 'string' ? new Date(d) : d;
  const dd = String(date.getDate()).padStart(2, '0');
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const yyyy = date.getFullYear();
  return `${dd}.${mm}.${yyyy}`;
}

export function formatDateTime(d: string | Date | null | undefined): string {
  if (!d) return '—';
  const date = typeof d === 'string' ? new Date(d) : d;
  const hh = String(date.getHours()).padStart(2, '0');
  const mi = String(date.getMinutes()).padStart(2, '0');
  return `${formatDate(date)} ${hh}:${mi}`;
}

/** Davlat kodlari va ularning milliy formati */
const PHONE_PATTERNS: Array<{ dial: string; mask: string }> = [
  { dial: '998', mask: 'XX XXX XX XX' },     // UZ
  { dial: '996', mask: 'XXX XXX XXX' },      // KG
  { dial: '992', mask: 'XX XXX XXXX' },      // TJ
  { dial: '90',  mask: 'XXX XXX XX XX' },    // TR
  { dial: '7',   mask: 'XXX XXX XX XX' },    // RU / KZ
];

function applyMask(digits: string, mask: string): string {
  let out = '';
  let di = 0;
  for (const ch of mask) {
    if (di >= digits.length) break;
    if (ch === 'X') {
      out += digits[di];
      di++;
    } else {
      out += ch;
    }
  }
  return out;
}

export function formatPhone(p: string | null | undefined): string {
  if (!p) return '—';
  const digits = p.replace(/\D/g, '');
  if (!digits) return p;
  // Eng uzun dial code'lardan boshlab tekshiramiz
  const sorted = [...PHONE_PATTERNS].sort((a, b) => b.dial.length - a.dial.length);
  for (const { dial, mask } of sorted) {
    if (digits.startsWith(dial)) {
      const national = digits.slice(dial.length);
      return `+${dial} ${applyMask(national, mask)}`.trimEnd();
    }
  }
  return p;
}
