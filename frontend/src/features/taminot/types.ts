/**
 * Ta'minot moduli — umumiy tiplar.
 *
 * IKKI DARAJA:
 *   1) Yetkazib beruvchi (`TaminotSupplier`) — PUL hisobi shu yerda. Bitta
 *      joydan nechta mahsulot olinishidan qat'i nazar qarz bitta.
 *   2) Mahsulot (`TaminotProduct`) — OMBOR QOLDIG'I shu yerda.
 */

/** Ombor qoldig'i holati: harakat yo'q / tugagan / kam qoldi / yetarli */
export type StockStatus = 'none' | 'out' | 'low' | 'ok';

/** Bitta yetkazib beruvchining bitta valyutadagi hisobi. */
export interface SupplierTotal {
  currency: string;
  total_purchased: number;
  total_paid: number;
  balance: number;
  stock_value: number;
}

export interface TaminotSupplier {
  id: string;
  scope: string;
  name: string;
  phone?: string | null;
  note?: string | null;
  created_at: string;
  product_count: number;
  /** Valyuta bo'yicha alohida — UZS va USD hech qachon qo'shilmaydi */
  totals: SupplierTotal[];
  last_purchase_at?: string | null;
  low_stock_count: number;
  out_of_stock_count: number;
}

/** Ta'minotdagi bitta harakat (kirim, to'lov, sarf, to'g'rilash). */
export type TxKind = 'purchase' | 'payment' | 'consume' | 'adjust';

export interface TaminotTx {
  id: string;
  supplier_id: string;
  supplier_name?: string | null;
  /** Yetkazib beruvchiga qilingan umumiy to'lovda mahsulot bo'lmaydi */
  product_id?: string | null;
  product_name?: string | null;
  unit: string;
  kind: TxKind;
  qty: number;
  unit_price: number;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
  /** To'ldirilgan bo'lsa — ARXIVDA: hisobga qo'shilmaydi, chizib ko'rsatiladi */
  deleted_at?: string | null;
}

export interface TaminotProduct {
  id: string;
  scope: string;
  supplier_id: string;
  supplier_name?: string | null;
  name: string;
  unit: string;
  unit_price: number;
  currency: string;
  min_qty: number;
  note?: string | null;
  /** Shu mahsulotdan jami qancha olib kelingan (qarz emas — qarz guruhda) */
  total_purchased: number;
  last_purchase_at?: string | null;
  tx_count: number;
  // Ombor qoldig'i (miqdor bo'yicha)
  in_qty: number;
  out_qty: number;
  adjust_qty: number;
  stock: number;
  stock_value: number;
  stock_status: StockStatus;
  last_consume_at?: string | null;
}

export const UNIT_LABEL: Record<string, string> = {
  dona: 'dona', kg: 'kg', metr: 'metr', list: 'list',
};
export const CURRENCY_LABEL: Record<string, string> = {
  UZS: "so'm", USD: 'dollar',
};

/** Yetkazib beruvchining qarzi bor valyutalari (0 dan katta bo'lganlari). */
export const debtTotals = (s: TaminotSupplier) => s.totals.filter((t) => t.balance > 0);
