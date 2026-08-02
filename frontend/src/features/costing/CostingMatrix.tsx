import { useEffect, useMemo, useRef, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Save, Info, RotateCcw } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import StickyScrollbar from '@/components/ui/StickyScrollbar';
import { formatMoney, formatQty } from '@/lib/format';
import { cn } from '@/lib/cn';
import type { MaterialOption } from '@/features/costing/types';

interface MatrixRow {
  product_id: string;
  display_name: string;
  has_recipe: boolean;
  cells: Record<string, number>;
  materials_uzs: number;
  cost_uzs: number;
  expense_count: number;
  sum_line_count: number;
  overhead_percent: number;
}
interface MatrixData {
  usd_rate: number;
  materials: MaterialOption[];
  rows: MatrixRow[];
}

/** Katak qiymati: bo'sh matn = material ishlatilmaydi. */
type CellMap = Record<string, Record<string, string>>; // productId -> materialId -> qty

const num = (v: string) => {
  const n = parseFloat(v);
  return Number.isFinite(n) ? n : 0;
};

/**
 * Tannarx matritsasi — kalendar uslubidagi jadval: qatorlar mahsulotlar,
 * ustunlar tannarx katalogidagi materiallar. Katakka mahsulotga ketadigan miqdor
 * yoki (sum rejimida) summa yoziladi. Bir ekranda hammasini belgilash mumkin.
 *
 * Saqlash faqat material satrlarini almashtiradi — qo'shimcha xarajatlar va
 * ustama foizi mahsulot sahifasida tahrirlanadi va bu yerda tegilmaydi.
 */
export default function CostingMatrix({ canWrite }: { canWrite: boolean }) {
  const q = useQuery<MatrixData>({
    queryKey: ['costing-matrix'],
    queryFn: () => api.get('/costing/matrix').then((r) => r.data),
  });

  const [draft, setDraft] = useState<CellMap>({});
  const [saving, setSaving] = useState(false);

  // Gorizontal scrollbar jadval tepasida turadi (pastdagisi yashirilgan) va
  // sahifa aylantirilganda ham ko'rinib turadi — StickyScrollbar.
  const bodyScrollRef = useRef<HTMLDivElement>(null);

  // Serverdan kelgan qiymatlarni tahrirlash holatiga ochamiz
  const serverCells = useMemo<CellMap>(() => {
    const out: CellMap = {};
    for (const r of q.data?.rows ?? []) {
      out[r.product_id] = {};
      for (const [mid, qty] of Object.entries(r.cells)) {
        out[r.product_id][mid] = String(qty);
      }
    }
    return out;
  }, [q.data]);

  useEffect(() => { setDraft(serverCells); }, [serverCells]);

  const data = q.data;
  const materials = data?.materials ?? [];
  const rate = data?.usd_rate ?? 0;

  const cell = (pid: string, mid: string) => draft[pid]?.[mid] ?? '';
  const setCell = (pid: string, mid: string, v: string) =>
    setDraft((prev) => ({ ...prev, [pid]: { ...(prev[pid] ?? {}), [mid]: v } }));

  /** Qator bo'yicha miqdorli materiallar summasi (jonli narx bilan). */
  const rowMaterials = (pid: string) =>
    materials.reduce((sum, m) => {
      const qty = num(cell(pid, m.id));
      if (qty <= 0) return sum;
      const line = qty * m.unit_price;
      return sum + (m.currency === 'USD' ? line * rate : line);
    }, 0);

  /** O'zgargan qatorlar (faqat ularni saqlaymiz). */
  const dirtyRows = useMemo(() => {
    const ids: string[] = [];
    for (const r of data?.rows ?? []) {
      const before = serverCells[r.product_id] ?? {};
      const now = draft[r.product_id] ?? {};
      const keys = new Set([...Object.keys(before), ...Object.keys(now)]);
      const changed = [...keys].some((k) => num(before[k] ?? '') !== num(now[k] ?? ''));
      if (changed) ids.push(r.product_id);
    }
    return ids;
  }, [draft, serverCells, data]);

  async function handleSave() {
    setSaving(true);
    try {
      await api.put('/costing/matrix', {
        rows: dirtyRows.map((pid) => ({
          product_id: pid,
          cells: materials
            .filter((m) => num(cell(pid, m.id)) > 0)
            .map((m) => ({ material_id: m.id, value: num(cell(pid, m.id)) })),
        })),
      });
      toast.success(`${dirtyRows.length} ta mahsulot saqlandi`);
      q.refetch();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  if (q.isLoading) {
    return <Card><div className="space-y-2">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />
      ))}
    </div></Card>;
  }
  if (!data || data.rows.length === 0) {
    return <Card><EmptyState title="Mahsulot yo'q"
      description="Mahsulotlar bo'limida asosiy mahsulot qo'shilgach shu yerda paydo bo'ladi" /></Card>;
  }
  if (materials.length === 0) {
    return <Card><EmptyState title="Material yo'q"
      description="«Materiallar» tabida material qo'shsangiz, ustunlar shu yerda paydo bo'ladi" /></Card>;
  }

  return (
    <div className="space-y-3">
      <div className="rounded-card border border-primary/20 bg-primary/[0.04] px-4 py-3 flex items-start gap-3">
        <Info size={17} className="text-primary shrink-0 mt-0.5" />
        <div className="text-sm text-ink-soft">
          Katakka <b className="text-ink">bitta mahsulotga ketadigan miqdor</b> yoziladi;
          narx katalogdan olinadi. Bo'sh katak "ishlatilmaydi" degani. Qo'shimcha
          xarajatlar, ustama foizi va summa bilan kiritilgan satrlar mahsulot sahifasida
          boshqariladi — bu jadval ularga tegmaydi.
        </div>
      </div>

      <Card>
        <div className="flex items-center justify-between flex-wrap gap-2 mb-3">
          <div className="text-sm text-ink-soft">
            {data.rows.length} mahsulot × {materials.length} material
            {rate > 0 ? ` · kurs ${formatMoney(rate, 'UZS')}` : ''}
          </div>
          {canWrite && (
            <div className="flex items-center gap-2">
              {dirtyRows.length > 0 && (
                <button onClick={() => setDraft(serverCells)}
                        className="inline-flex items-center gap-1.5 px-3 py-2 rounded-button text-sm font-medium bg-black/5 text-ink-soft hover:bg-black/10 transition">
                  <RotateCcw size={15} /> Bekor qilish
                </button>
              )}
              <button onClick={handleSave} disabled={saving || dirtyRows.length === 0}
                      className="btn-primary disabled:opacity-40">
                <Save size={16} />
                {saving ? 'Saqlanmoqda...'
                  : dirtyRows.length > 0 ? `Saqlash (${dirtyRows.length})` : 'Saqlash'}
              </button>
            </div>
          )}
        </div>

        {/* Gorizontal scrollbar jadval tepasida, doim ko'rinadi va sahifa
            aylantirilganda joyida qotib turadi */}
        <StickyScrollbar targetRef={bodyScrollRef} className="sticky top-16 z-20 bg-card py-1.5" />

        <div ref={bodyScrollRef} className="overflow-x-auto no-scrollbar-x">
          <table className="text-sm border-separate border-spacing-0">
            <thead>
              <tr>
                {/* Birinchi ustun yopishib turadi — gorizontal siljiganda nom ko'rinadi */}
                <th className="sticky left-0 z-10 bg-card text-left py-2 pr-3 border-b border-black/10 min-w-[190px]">
                  Mahsulot
                </th>
                {materials.map((m) => (
                  <th key={m.id} className="py-2 px-2 border-b border-black/10 text-center min-w-[100px]">
                    <div className="font-medium truncate max-w-[110px] mx-auto" title={m.name}>
                      {m.name}
                    </div>
                    <div className="text-[10px] font-normal text-ink-soft">
                      {`${m.currency === 'USD' ? `$${m.unit_price}` : formatQty(m.unit_price)}${m.unit ? `/${m.unit}` : ''}`}
                    </div>
                  </th>
                ))}
                <th className="py-2 pl-3 border-b border-black/10 text-right min-w-[120px]">
                  Materiallar
                </th>
                <th className="py-2 pl-3 border-b border-black/10 text-right min-w-[130px]">
                  Tannarx
                </th>
              </tr>
            </thead>
            <tbody>
              {data.rows.map((r) => {
                const mats = rowMaterials(r.product_id);
                const isDirty = dirtyRows.includes(r.product_id);
                // Tannarx = materiallar + (saqlangan xarajatlar) + ustama
                const savedExpenses = Math.max(
                  0, r.cost_uzs - r.materials_uzs * (1 + r.overhead_percent / 100),
                );
                const estCost = (mats + savedExpenses) * (1 + r.overhead_percent / 100);
                return (
                  <tr key={r.product_id} className={cn('group', isDirty && 'bg-warning/[0.05]')}>
                    <td className={cn(
                      'sticky left-0 z-10 py-1.5 pr-3 border-b border-black/5 whitespace-nowrap',
                      isDirty ? 'bg-warning/[0.05]' : 'bg-card group-hover:bg-black/[0.02]')}>
                      <div className="font-medium truncate max-w-[190px]" title={r.display_name}>
                        {r.display_name}
                      </div>
                      <div className="text-[10px] text-ink-soft">
                        {[
                          r.expense_count > 0 ? `${r.expense_count} xarajat` : null,
                          r.sum_line_count > 0 ? `${r.sum_line_count} summa satri` : null,
                          r.overhead_percent > 0 ? `ustama ${r.overhead_percent}%` : null,
                        ].filter(Boolean).join(' · ') || 'faqat miqdorlar'}
                      </div>
                    </td>
                    {materials.map((m) => {
                      const v = cell(r.product_id, m.id);
                      const filled = num(v) > 0;
                      return (
                        <td key={m.id} className="py-1 px-1 border-b border-black/5">
                          <input
                            className={cn(
                              'w-full text-center rounded-button border px-1 py-1.5 text-sm outline-none transition',
                              'focus:border-primary focus:ring-2 focus:ring-primary/20',
                              filled ? 'border-primary/30 bg-primary/[0.06] font-medium'
                                     : 'border-transparent bg-black/[0.02] text-ink-soft',
                            )}
                            type="number" min="0" step="any" inputMode="decimal"
                            placeholder="—"
                            title={`${m.name}: miqdor${m.unit ? ` (${m.unit})` : ''}`}
                            disabled={!canWrite}
                            value={v}
                            onChange={(e) => setCell(r.product_id, m.id, e.target.value)}
                          />
                        </td>
                      );
                    })}
                    <td className="py-1.5 pl-3 border-b border-black/5 text-right whitespace-nowrap tabular-nums">
                      {mats > 0 ? formatMoney(mats, 'UZS') : '—'}
                    </td>
                    <td className="py-1.5 pl-3 border-b border-black/5 text-right whitespace-nowrap tabular-nums font-semibold">
                      {estCost > 0 ? formatMoney(estCost, 'UZS') : '—'}
                      {isDirty && <div className="text-[10px] font-normal text-warning">saqlanmagan</div>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        <p className="text-[11px] text-ink-soft mt-3">
          «Tannarx» ustuni jadvaldagi miqdorlar + mahsulotda saqlangan xarajatlar va ustama
          bo'yicha hisoblangan taxminiy qiymat. Saqlagandan keyin aniq qiymat mahsulot
          sahifasida va ro'yxatda ko'rinadi.
        </p>
      </Card>
    </div>
  );
}
