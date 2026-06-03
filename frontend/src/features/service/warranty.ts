// Kafolatni mijoz tomonida hisoblash (backend warranty_service bilan bir xil):
// yetkazilgan kundan 1-yil to'liq, 2–3-yil faqat ish. Buyurtmalar ro'yxatida
// har biriga belgini ko'rsatish uchun (har biriga alohida so'rov yubormaslik uchun).

export type WarrantyStatus = 'active_full' | 'active_service_only' | 'expired' | 'not_delivered';

export interface WarrantyCalc {
  status: WarrantyStatus;
  year1End: Date | null;
  year3End: Date | null;
  daysYear1: number;
  daysYear3: number;
}

const DAY = 24 * 60 * 60 * 1000;

export function computeWarranty(deliveredAt?: string | null): WarrantyCalc {
  if (!deliveredAt) {
    return { status: 'not_delivered', year1End: null, year3End: null, daysYear1: 0, daysYear3: 0 };
  }
  const start = new Date(deliveredAt);
  const year1End = new Date(start.getTime() + 365 * DAY);
  const year3End = new Date(start.getTime() + 365 * 3 * DAY);
  const today = new Date();
  const daysYear1 = Math.ceil((year1End.getTime() - today.getTime()) / DAY);
  const daysYear3 = Math.ceil((year3End.getTime() - today.getTime()) / DAY);
  const status: WarrantyStatus =
    daysYear1 > 0 ? 'active_full' : daysYear3 > 0 ? 'active_service_only' : 'expired';
  return { status, year1End, year3End, daysYear1: Math.max(0, daysYear1), daysYear3: Math.max(0, daysYear3) };
}

export const WARRANTY_META: Record<WarrantyStatus, { short: string; long: string; cls: string }> = {
  active_full: {
    short: '1-yil — bepul',
    long: '1-yil kafolat — ish va ehtiyot qism bepul',
    cls: 'bg-success/10 text-success',
  },
  active_service_only: {
    short: '2–3-yil — faqat ish',
    long: '2–3-yil kafolat — faqat ish bepul, ehtiyot qism mijoz hisobidan',
    cls: 'bg-warning/10 text-warning',
  },
  expired: {
    short: 'Kafolat tugagan',
    long: 'Kafolat muddati tugagan — xizmat va ehtiyot qism mijoz hisobidan',
    cls: 'bg-gray-100 text-gray-600',
  },
  not_delivered: {
    short: 'Yetkazilmagan',
    long: 'Mahsulot hali yetkazilmagan — kafolat boshlanmagan',
    cls: 'bg-blue-50 text-blue-700',
  },
};
