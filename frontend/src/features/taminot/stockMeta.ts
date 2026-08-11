import type { StockStatus } from '@/features/taminot/types';

/**
 * Ombor qoldig'i holati uchun ko'rinish: qizil — tugagan/kam qolgan.
 *
 * Ilgari `TaminotStockTab` ichida edi; alohida "Ombor qoldiq" tabi olib
 * tashlangach (qoldiq endi mahsulotlar ro'yxatining o'zida ko'rsatiladi)
 * shu yerga ko'chirildi.
 */
export const STOCK_META: Record<StockStatus, {
  label: string; badge: string; row: string; value: string;
}> = {
  out: {
    label: 'Tugadi',
    badge: 'bg-danger text-white',
    row: 'bg-danger/[0.07] hover:bg-danger/10',
    value: 'text-danger',
  },
  low: {
    label: 'Kam qoldi',
    badge: 'bg-danger/15 text-danger',
    row: 'bg-danger/[0.04] hover:bg-danger/[0.07]',
    value: 'text-danger',
  },
  ok: {
    label: 'Yetarli',
    badge: 'bg-success/15 text-success',
    row: 'hover:bg-black/[0.02]',
    value: 'text-ink',
  },
  none: {
    label: 'Harakat yo‘q',
    badge: 'bg-black/5 text-ink-soft',
    row: 'hover:bg-black/[0.02]',
    value: 'text-ink-soft',
  },
};
