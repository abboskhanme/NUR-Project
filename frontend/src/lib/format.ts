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
