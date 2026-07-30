/** Tannarx moduli — backend sxemalari bilan bir xil turlar. */

export interface CostRow {
  product_id: string;
  display_name: string;
  product_type: string;
  model?: string | null;
  kvm?: number | null;
  year?: number | null;
  has_recipe: boolean;
  item_count: number;
  cost_uzs?: number | null;
  price_uzs?: number | null;
  profit_uzs?: number | null;
  margin_percent?: number | null;
  avg_sold_uzs?: number | null;
  sold_count: number;
  updated_at?: string | null;
}

export interface RecipeItem {
  id?: string;
  kind: 'material' | 'expense';
  material_id?: string | null;
  label: string;
  /** qty — miqdor × narx; sum — summa to'g'ridan-to'g'ri kiritilgan */
  entry_mode: EntryMode;
  qty: number;
  amount?: number | null;
  unit?: string | null;
  unit_price: number;
  currency: string;
  line_total: number;
  line_total_uzs: number;
  price_from_material: boolean;
  material_missing: boolean;
}

export interface Breakdown {
  usd_rate: number;
  materials_uzs: number;
  expenses_uzs: number;
  overhead_percent: number;
  overhead_uzs: number;
  cost_uzs: number;
  cost_usd: number;
  price_usd: number;
  price_uzs: number;
  price_source: 'recipe' | 'product' | 'none';
  profit_uzs: number;
  margin_percent: number;
  markup_percent: number;
  avg_sold_uzs?: number | null;
  sold_count: number;
  real_profit_uzs?: number | null;
  real_margin_percent?: number | null;
}

export interface CostDetail {
  product_id: string;
  display_name: string;
  product_type: string;
  base_price_usd: number;
  has_recipe: boolean;
  overhead_percent: number;
  target_price_usd?: number | null;
  note?: string | null;
  items: RecipeItem[];
  breakdown: Breakdown;
  updated_at?: string | null;
}

/** Kalkulyatsiya satrining kiritilish usuli (material darajasida emas). */
export type EntryMode = 'qty' | 'sum';

/** Tannarx modulining O'Z katalogidagi material (ta'minotdan mustaqil). */
export interface MaterialOption {
  id: string;
  name: string;
  /** Ixtiyoriy — summa rejimida odatda bo'sh */
  unit?: string | null;
  unit_price: number;
  currency: string;
  note?: string | null;
  is_active: boolean;
  /** Nechta mahsulot kalkulyatsiyasida ishlatilgani */
  used_in: number;
}

export const UNITS = ['dona', 'kg', 'metr', 'list', 'litr'] as const;
export const UNIT_LABEL: Record<string, string> = {
  dona: 'dona', kg: 'kg', metr: 'metr', list: 'list', litr: 'litr',
};
export const CURRENCY_LABEL: Record<string, string> = { UZS: "so'm", USD: 'dollar' };
export const ENTRY_MODE_LABEL: Record<EntryMode, string> = {
  qty: 'Miqdor',
  sum: 'Summa',
};

export interface CostingSummary {
  usd_rate: number;
  product_count: number;
  with_recipe: number;
  without_recipe: number;
  avg_margin_percent?: number | null;
  best_name?: string | null;
  best_margin_percent?: number | null;
  worst_name?: string | null;
  worst_margin_percent?: number | null;
  loss_count: number;
}

/** Marja darajasiga qarab rang — jadval va kartalarda bir xil ishlatiladi. */
export function marginTone(margin?: number | null): string {
  if (margin == null) return 'text-ink-soft';
  if (margin <= 0) return 'text-danger';
  if (margin < 15) return 'text-warning';
  return 'text-success';
}
