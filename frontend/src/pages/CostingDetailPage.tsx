import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  ArrowLeft, Plus, Trash2, Save, Calculator, Lock, Unlock, AlertTriangle,
  PackagePlus, Receipt, TrendingUp,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import ConfirmModal from '@/components/ui/ConfirmModal';
import MoneyInput from '@/components/ui/MoneyInput';
import { formatMoney, formatQty } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import { cn } from '@/lib/cn';
import type { CostDetail, EntryMode, MaterialOption } from '@/features/costing/types';
import { marginTone, CURRENCY_LABEL, UNIT_LABEL } from '@/features/costing/types';
import MaterialModal from '@/features/costing/MaterialModal';

/** Tahrirlash uchun satr holati (backendga yuborishdan oldingi ko'rinish). */
interface EditRow {
  key: string;
  kind: 'material' | 'expense';
  material_id: string | null;
  label: string;
  /** qty — miqdor × narx; sum — summa to'g'ridan-to'g'ri */
  mode: EntryMode;
  qty: string;
  amount: number;
  unit: string;
  // manual=false — narx katalogdan JONLI olinadi (tavsiya etiladi)
  manual: boolean;
  unit_price: number;
  currency: 'UZS' | 'USD';
}

const newKey = () => Math.random().toString(36).slice(2);
const num = (v: string | number) => {
  const n = typeof v === 'string' ? parseFloat(v) : v;
  return Number.isFinite(n) ? n : 0;
};

/**
 * Bitta mahsulotning tannarx kalkulyatsiyasi: tarkib (ichki materiallar) +
 * qo'shimcha xarajatlar + ustama foizi. O'ng panelda hisob jonli yangilanadi.
 */
export default function CostingDetailPage() {
  const { productId = '' } = useParams();
  const navigate = useNavigate();
  const { can } = usePermissions();
  const canWrite = can('costing:write');
  const canDelete = can('costing:delete');

  const detailQ = useQuery<CostDetail>({
    queryKey: ['costing-detail', productId],
    queryFn: () => api.get(`/costing/products/${productId}`).then((r) => r.data),
    enabled: !!productId,
  });
  const materialsQ = useQuery<MaterialOption[]>({
    queryKey: ['costing-materials'],
    queryFn: () => api.get('/costing/materials').then((r) => r.data),
  });

  const [rows, setRows] = useState<EditRow[]>([]);
  const [overhead, setOverhead] = useState('0');
  const [targetPrice, setTargetPrice] = useState<number>(0);
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  const [confirmDel, setConfirmDel] = useState(false);
  const [newMaterial, setNewMaterial] = useState(false);

  const detail = detailQ.data;
  const materials = materialsQ.data ?? [];
  const matById = useMemo(
    () => Object.fromEntries(materials.map((m) => [m.id, m])) as Record<string, MaterialOption>,
    [materials],
  );

  // Serverdan kelgan ma'lumotni tahrirlash holatiga ochamiz
  useEffect(() => {
    if (!detail) return;
    setRows(detail.items.map((it) => ({
      key: newKey(),
      kind: it.kind as 'material' | 'expense',
      material_id: it.material_id ?? null,
      label: it.label,
      mode: it.entry_mode === 'sum' ? 'sum' : 'qty',
      qty: String(it.qty),
      amount: it.amount ?? 0,
      unit: it.unit ?? '',
      manual: it.kind === 'expense' ? true : !it.price_from_material,
      unit_price: it.unit_price,
      currency: (it.currency === 'USD' ? 'USD' : 'UZS'),
    })));
    setOverhead(String(detail.overhead_percent ?? 0));
    setTargetPrice(detail.target_price_usd ?? 0);
    setNote(detail.note ?? '');
  }, [detail]);

  const rate = detail?.breakdown.usd_rate ?? 0;

  /** Satrning amaldagi narxi va valyutasi (jonli yoki qo'lda). */
  const effective = (r: EditRow) => {
    if (r.kind === 'expense' || r.manual) return { price: r.unit_price, currency: r.currency };
    const m = r.material_id ? matById[r.material_id] : undefined;
    return { price: m?.unit_price ?? 0, currency: (m?.currency === 'USD' ? 'USD' : 'UZS') as 'UZS' | 'USD' };
  };
  const lineUzs = (r: EditRow) => {
    const { price, currency } = effective(r);
    const total = r.mode === 'sum' ? r.amount : num(r.qty) * price;
    return currency === 'USD' ? total * rate : total;
  };

  // Jonli hisob — saqlashdan oldin ham ko'rinadi
  const calc = useMemo(() => {
    const materialsUzs = rows.filter((r) => r.kind === 'material').reduce((s, r) => s + lineUzs(r), 0);
    const expensesUzs = rows.filter((r) => r.kind === 'expense').reduce((s, r) => s + lineUzs(r), 0);
    const pct = num(overhead);
    const overheadUzs = ((materialsUzs + expensesUzs) * pct) / 100;
    const cost = materialsUzs + expensesUzs + overheadUzs;
    const priceUsd = targetPrice || detail?.base_price_usd || 0;
    const priceUzs = priceUsd * rate;
    const profit = priceUzs - cost;
    const margin = priceUzs > 0 ? (profit / priceUzs) * 100 : 0;
    const markup = cost > 0 ? (profit / cost) * 100 : 0;
    return { materialsUzs, expensesUzs, pct, overheadUzs, cost, priceUsd, priceUzs, profit, margin, markup };
  }, [rows, overhead, targetPrice, detail, rate, matById]); // eslint-disable-line react-hooks/exhaustive-deps

  const patch = (key: string, next: Partial<EditRow>) =>
    setRows((prev) => prev.map((r) => (r.key === key ? { ...r, ...next } : r)));

  // Bir material faqat bitta satrda bo'ladi — tanlanganlari boshqa satrlarning
  // dropdown'ida ko'rinmaydi (o'z satridagi tanlov, albatta, qoladi).
  const takenMaterialIds = useMemo(
    () => new Set(rows.filter((r) => r.kind === 'material' && r.material_id).map((r) => r.material_id!)),
    [rows],
  );

  const addMaterial = () => setRows((p) => [...p, {
    key: newKey(), kind: 'material', material_id: null, label: '', mode: 'qty',
    qty: '1', amount: 0, unit: '', manual: false, unit_price: 0, currency: 'UZS',
  }]);
  const addExpense = () => setRows((p) => [...p, {
    key: newKey(), kind: 'expense', material_id: null, label: '', mode: 'sum',
    qty: '1', amount: 0, unit: '', manual: true, unit_price: 0, currency: 'UZS',
  }]);

  async function handleSave() {
    // Tekshiruv: material tanlanmagan yoki xarajat nomi bo'sh satrlar
    const seenMaterials = new Set<string>();
    for (const r of rows) {
      if (r.kind === 'material' && !r.material_id) {
        toast.error('Har bir material satrida material tanlangan bo\'lishi kerak');
        return;
      }
      if (r.kind === 'material' && r.material_id) {
        if (seenMaterials.has(r.material_id)) {
          toast.error(`«${matById[r.material_id]?.name ?? r.label}» ikki marta kiritilgan — ortiqcha satrni o'chiring`);
          return;
        }
        seenMaterials.add(r.material_id);
      }
      if (r.kind === 'expense' && !r.label.trim()) {
        toast.error('Xarajat satrida nom kiriting');
        return;
      }
      if (r.mode === 'sum') {
        if (r.amount <= 0) {
          toast.error(`«${r.label || 'satr'}» uchun summani kiriting`);
          return;
        }
      } else if (num(r.qty) <= 0) {
        toast.error(`«${r.label || 'satr'}» uchun miqdor 0 dan katta bo'lishi kerak`);
        return;
      }
    }
    setSaving(true);
    try {
      await api.put(`/costing/products/${productId}`, {
        overhead_percent: num(overhead),
        target_price_usd: targetPrice || null,
        note: note.trim() || null,
        items: rows.map((r) => ({
          kind: r.kind,
          material_id: r.kind === 'material' ? r.material_id : null,
          label: r.kind === 'expense' ? r.label.trim() : null,
          entry_mode: r.mode,
          qty: r.mode === 'sum' ? 1 : num(r.qty),
          amount: r.mode === 'sum' ? r.amount : null,
          unit: r.unit.trim() || null,
          unit_price: r.kind === 'expense' || r.manual ? r.unit_price : null,
          currency: r.currency,
        })),
      });
      toast.success('Kalkulyatsiya saqlandi');
      detailQ.refetch();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    try {
      await api.delete(`/costing/products/${productId}`);
      toast.success("Kalkulyatsiya o'chirildi");
      navigate('/costing');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    }
  }

  if (detailQ.isLoading) {
    return <div className="space-y-3">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="h-16 rounded-card bg-black/5 animate-pulse" />
      ))}
    </div>;
  }
  if (!detail) return <div className="text-ink-soft">Mahsulot topilmadi</div>;

  const b = detail.breakdown;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <Link to="/costing" className="p-2 rounded-button hover:bg-black/5 text-ink-soft shrink-0">
            <ArrowLeft size={18} />
          </Link>
          <div className="min-w-0">
            <h1 className="text-lg sm:text-2xl font-bold truncate">{detail.display_name}</h1>
            <p className="text-xs sm:text-sm text-ink-soft">
              Tannarx kalkulyatsiyasi · {rows.length} ta satr
              {b.usd_rate > 0 ? ` · kurs ${formatMoney(b.usd_rate, 'UZS')}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          {canDelete && detail.has_recipe && (
            <button onClick={() => setConfirmDel(true)}
                    className="p-2 rounded-button text-ink-soft hover:bg-danger/10 hover:text-danger transition">
              <Trash2 size={17} />
            </button>
          )}
          {canWrite && (
            <button onClick={handleSave} disabled={saving} className="btn-primary flex-1 sm:flex-none">
              <Save size={16} /> {saving ? 'Saqlanmoqda...' : 'Saqlash'}
            </button>
          )}
        </div>
      </div>

      {b.usd_rate <= 0 && (
        <div className="rounded-card border border-warning/30 bg-warning/10 px-4 py-3 flex items-center gap-3">
          <AlertTriangle size={18} className="text-warning shrink-0" />
          <div className="text-sm text-warning">
            USD kursi kiritilmagan — dollardagi narxlar so'mga o'girilmaydi. Moliya bo'limida kursni kiriting.
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* ============ Tarkib ============ */}
        <div className="lg:col-span-2 space-y-4">
          <Card title="Tarkib — materiallar">
            <div className="space-y-2">
              {rows.filter((r) => r.kind === 'material').length === 0 && (
                <div className="text-sm text-ink-soft py-3 text-center">
                  Material qo'shilmagan — pastdagi tugma orqali qo'shing
                </div>
              )}
              {rows.map((r) => r.kind !== 'material' ? null : (
                <MaterialRow key={r.key} row={r} materials={materials} matById={matById}
                             takenIds={takenMaterialIds}
                             rate={rate} canWrite={canWrite}
                             lineUzs={lineUzs(r)}
                             onPatch={(next) => patch(r.key, next)}
                             onAddMaterial={() => setNewMaterial(true)}
                             onRemove={() => setRows((p) => p.filter((x) => x.key !== r.key))} />
              ))}
            </div>
            {canWrite && (
              <button onClick={addMaterial}
                      disabled={materials.length > 0 && takenMaterialIds.size >= materials.length}
                      title={materials.length > 0 && takenMaterialIds.size >= materials.length
                        ? 'Katalogdagi barcha materiallar qo\'shilgan' : undefined}
                      className="mt-3 inline-flex items-center gap-1.5 px-3 py-2 rounded-button text-sm font-medium bg-primary/10 text-primary hover:bg-primary/20 transition disabled:opacity-40 disabled:hover:bg-primary/10">
                <PackagePlus size={15} /> Material qo'shish
              </button>
            )}
          </Card>

          <Card title="Qo'shimcha xarajatlar">
            <div className="space-y-2">
              {rows.filter((r) => r.kind === 'expense').length === 0 && (
                <div className="text-sm text-ink-soft py-3 text-center">
                  Masalan: ish haqi, bo'yoq ishi, payvandlash — ixtiyoriy
                </div>
              )}
              {rows.map((r) => r.kind !== 'expense' ? null : (
                <ExpenseRow key={r.key} row={r} canWrite={canWrite} lineUzs={lineUzs(r)}
                            onPatch={(next) => patch(r.key, next)}
                            onRemove={() => setRows((p) => p.filter((x) => x.key !== r.key))} />
              ))}
            </div>
            {canWrite && (
              <button onClick={addExpense}
                      className="mt-3 inline-flex items-center gap-1.5 px-3 py-2 rounded-button text-sm font-medium bg-warning/10 text-warning hover:bg-warning/20 transition">
                <Receipt size={15} /> Xarajat qo'shish
              </button>
            )}
          </Card>
        </div>

        {/* ============ Hisob paneli ============ */}
        <div className="space-y-4">
          <Card title="Hisob">
            <div className="space-y-1.5 text-sm">
              <Line label="Materiallar" value={formatMoney(calc.materialsUzs, 'UZS')} />
              <Line label="Qo'shimcha xarajatlar" value={formatMoney(calc.expensesUzs, 'UZS')} />
              <div className="flex items-center justify-between gap-2">
                <span className="text-ink-soft flex items-center gap-1.5">
                  Ustama
                  <input className="input !w-16 !py-1 !px-2 text-xs text-center" type="number"
                         min="0" max="100" step="any" disabled={!canWrite}
                         value={overhead} onChange={(e) => setOverhead(e.target.value)} />
                  %
                </span>
                <span className="font-medium">{formatMoney(calc.overheadUzs, 'UZS')}</span>
              </div>
              <div className="border-t border-black/10 pt-2 mt-1 flex items-center justify-between">
                <span className="font-semibold flex items-center gap-1.5">
                  <Calculator size={15} className="text-primary" /> TANNARX
                </span>
                <span className="text-lg font-bold text-primary">
                  {formatMoney(calc.cost, 'UZS')}
                </span>
              </div>
            </div>
          </Card>

          <Card title="Sotish narxi va foyda">
            <div className="space-y-3">
              <div>
                <label className="label">Sotish narxi (dollarda)</label>
                {canWrite ? (
                  <MoneyInput value={targetPrice} onChange={setTargetPrice} suffix="dollar" />
                ) : (
                  <div className="input bg-black/[0.03] text-ink-soft">
                    ${targetPrice || detail.base_price_usd || 0}
                  </div>
                )}
                <p className="text-[11px] text-ink-soft mt-1">
                  Bo'sh (0) bo'lsa mahsulot kartochkasidagi narx olinadi
                  {detail.base_price_usd ? `: $${detail.base_price_usd}` : ''}
                </p>
              </div>
              <div className="space-y-1.5 text-sm">
                <Line label="Sotish narxi (so'm)" value={formatMoney(calc.priceUzs, 'UZS')} />
                <Line label="Tannarx" value={formatMoney(calc.cost, 'UZS')} />
                <div className="border-t border-black/10 pt-2 flex items-center justify-between">
                  <span className="font-semibold">FOYDA</span>
                  <span className={cn('text-lg font-bold', marginTone(calc.margin))}>
                    {formatMoney(calc.profit, 'UZS')}
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-2 pt-1">
                  <div className="rounded-button bg-black/[0.03] px-3 py-2 text-center">
                    <div className="text-[11px] text-ink-soft">Marja</div>
                    <div className={cn('font-bold', marginTone(calc.margin))}>
                      {calc.margin.toFixed(1)}%
                    </div>
                  </div>
                  <div className="rounded-button bg-black/[0.03] px-3 py-2 text-center">
                    <div className="text-[11px] text-ink-soft">Ustama</div>
                    <div className="font-bold">{calc.markup.toFixed(1)}%</div>
                  </div>
                </div>
              </div>
            </div>
          </Card>

          {/* Haqiqiy sotuvlar bilan solishtirish */}
          {b.avg_sold_uzs != null && (
            <Card title="Haqiqiy sotuvlar (oxirgi 180 kun)">
              <div className="space-y-1.5 text-sm">
                <Line label="Sotilgan" value={`${b.sold_count} dona`} />
                <Line label="O'rtacha sotuv narxi" value={formatMoney(b.avg_sold_uzs, 'UZS')} />
                <div className="border-t border-black/10 pt-2 flex items-center justify-between">
                  <span className="font-semibold flex items-center gap-1.5">
                    <TrendingUp size={15} /> Haqiqiy foyda (1 dona)
                  </span>
                  <span className={cn('font-bold', marginTone(b.real_margin_percent))}>
                    {b.real_profit_uzs != null ? formatMoney(b.real_profit_uzs, 'UZS') : '—'}
                  </span>
                </div>
                {b.real_margin_percent != null && (
                  <div className="text-[11px] text-ink-soft text-right">
                    marja {b.real_margin_percent}% · saqlangan tannarx bo'yicha
                  </div>
                )}
              </div>
            </Card>
          )}

          <Card title="Izoh">
            <textarea className="input min-h-[70px]" value={note} disabled={!canWrite}
                      placeholder="Kalkulyatsiya haqida eslatma..."
                      onChange={(e) => setNote(e.target.value)} />
          </Card>
        </div>
      </div>

      {newMaterial && (
        <MaterialModal onClose={() => setNewMaterial(false)}
                       onSaved={() => materialsQ.refetch()} />
      )}
      <ConfirmModal
        open={confirmDel}
        title="Kalkulyatsiyani o'chirish"
        message="Bu mahsulotning tarkibi va tannarx hisobi o'chiriladi. Davom etamizmi?"
        confirmText="O'chirish"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDel(false)}
      />
    </div>
  );
}

function Line({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-2">
      <span className="text-ink-soft">{label}</span>
      <span className="font-medium">{value}</span>
    </div>
  );
}

/**
 * Material satri. Materialning kiritish usuliga qarab ko'rinish o'zgaradi:
 *   qty — Miqdor + Narx (narx katalogdan jonli, qulf bilan qotirish mumkin)
 *   sum — bitta «Summa» maydoni ("50 ming so'mlik kraska sepildi")
 */
function MaterialRow({ row, materials, matById, takenIds, rate, canWrite, lineUzs, onPatch, onRemove, onAddMaterial }: {
  row: EditRow;
  materials: MaterialOption[];
  matById: Record<string, MaterialOption>;
  takenIds: Set<string>;
  rate: number;
  canWrite: boolean;
  lineUzs: number;
  onPatch: (next: Partial<EditRow>) => void;
  onRemove: () => void;
  onAddMaterial: () => void;
}) {
  const mat = row.material_id ? matById[row.material_id] : undefined;
  const livePrice = mat?.unit_price ?? 0;
  const liveCurrency = mat?.currency === 'USD' ? 'USD' : 'UZS';
  const missing = !!row.material_id && !mat;
  const isSum = row.mode === 'sum';

  return (
    <div className={cn('rounded-button border p-2.5',
      missing ? 'border-danger/30 bg-danger/[0.04]' : 'border-black/[0.07] bg-black/[0.02]')}>
      <div className="flex flex-wrap items-end gap-2">
        {/* Material tanlash + yangi qo'shish */}
        <div className="basis-full sm:basis-0 sm:flex-1 min-w-0">
          <label className="label !mb-0.5 text-xs">Material</label>
          <div className="flex items-center gap-1.5">
            <select className="input !py-1.5 text-sm min-w-0" value={row.material_id ?? ''} disabled={!canWrite}
                    onChange={(e) => {
                      const m = matById[e.target.value];
                      onPatch({
                        material_id: e.target.value || null,
                        label: m?.name ?? '',
                        unit: m?.unit ?? '',
                        unit_price: m?.unit_price ?? 0,
                        currency: (m?.currency === 'USD' ? 'USD' : 'UZS'),
                      });
                    }}>
              <option value="">— tanlang —</option>
              {/* Boshqa satrlarda tanlangan materiallar ro'yxatda ko'rinmaydi */}
              {materials.filter((m) => m.id === row.material_id || !takenIds.has(m.id)).map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name}
                  {`${m.unit ? ` (${UNIT_LABEL[m.unit] ?? m.unit})` : ''} — ${m.currency === 'USD' ? `$${m.unit_price}` : `${m.unit_price} so'm`}`}
                </option>
              ))}
            </select>
            {canWrite && (
              <button type="button" onClick={onAddMaterial} title="Ro'yxatda yo'q materialni qo'shish"
                      className="p-2 rounded-button bg-primary/10 text-primary hover:bg-primary/20 transition shrink-0">
                <Plus size={15} />
              </button>
            )}
          </div>
        </div>

        {/* Usul: miqdor × narx yoki to'g'ridan-to'g'ri summa */}
        <div className="w-[104px]">
          <label className="label !mb-0.5 text-xs">Usul</label>
          <select className="input !py-1.5 text-sm" value={row.mode} disabled={!canWrite}
                  onChange={(e) => onPatch({ mode: e.target.value as EntryMode })}>
            <option value="qty">Miqdor</option>
            <option value="sum">Summa</option>
          </select>
        </div>

        {isSum ? (
          /* Summa rejimi — bitta maydon */
          <div className="w-[140px]">
            <label className="label !mb-0.5 text-xs">Summa *</label>
            <input className="input !py-1.5 text-sm" type="number" min="0" step="any" disabled={!canWrite}
                   value={row.amount || ''} placeholder="50000"
                   onChange={(e) => onPatch({ amount: parseFloat(e.target.value) || 0 })} />
          </div>
        ) : (
          <>
            {/* Miqdor */}
            <div className="w-[92px]">
              <label className="label !mb-0.5 text-xs">Miqdor</label>
              <input className="input !py-1.5 text-sm" type="number" min="0" step="any" disabled={!canWrite}
                     value={row.qty} onChange={(e) => onPatch({ qty: e.target.value })} />
            </div>
            {/* Narx */}
            <div className="w-[132px]">
              <label className="label !mb-0.5 text-xs flex items-center gap-1">
                Narx
                {canWrite && (
                  <button type="button" title={row.manual ? 'Katalog narxiga qaytarish' : "Narxni qo'lda kiritish"}
                          onClick={() => onPatch({
                            manual: !row.manual,
                            unit_price: row.manual ? livePrice : (row.unit_price || livePrice),
                            currency: row.manual ? liveCurrency : row.currency,
                          })}
                          className="text-ink-soft hover:text-primary">
                    {row.manual ? <Unlock size={12} /> : <Lock size={12} />}
                  </button>
                )}
              </label>
              {row.manual ? (
                <input className="input !py-1.5 text-sm" type="number" min="0" step="any" disabled={!canWrite}
                       value={row.unit_price}
                       onChange={(e) => onPatch({ unit_price: parseFloat(e.target.value) || 0 })} />
              ) : (
                <div className="input !py-1.5 text-sm bg-black/[0.03] text-ink-soft truncate">
                  {liveCurrency === 'USD' ? `$${livePrice}` : `${formatQty(livePrice)} so'm`}
                </div>
              )}
            </div>
          </>
        )}

        {/* Satr summasi */}
        <div className="ml-auto text-right shrink-0">
          <div className="text-[11px] text-ink-soft">Jami</div>
          <div className="font-bold whitespace-nowrap">{formatMoney(lineUzs, 'UZS')}</div>
        </div>
        {canWrite && (
          <button onClick={onRemove} title="Satrni olib tashlash"
                  className="p-2 rounded-button text-ink-soft hover:bg-danger/10 hover:text-danger transition shrink-0">
            <Trash2 size={15} />
          </button>
        )}
      </div>
      <div className="text-[11px] text-ink-soft mt-1.5">
        {missing ? (
          <span className="text-danger">Material o'chirilgan — boshqasini tanlang</span>
        ) : mat ? (
          isSum
            ? "summa to'g'ridan-to'g'ri kiritildi — miqdor va narx hisobga olinmaydi"
            : (
              <>
                {row.manual
                  ? "narx qo'lda kiritilgan (katalogdagi o'zgarish ta'sir qilmaydi)"
                  : 'narx katalogdan jonli olinadi'}
                {liveCurrency === 'USD' && rate > 0 ? ` · kurs ${formatQty(rate)}` : ''}
              </>
            )
        ) : "material tanlanmagan"}
      </div>
    </div>
  );
}

/** Qo'shimcha xarajat satri: nom + miqdor + narx + valyuta. */
function ExpenseRow({ row, canWrite, lineUzs, onPatch, onRemove }: {
  row: EditRow;
  canWrite: boolean;
  lineUzs: number;
  onPatch: (next: Partial<EditRow>) => void;
  onRemove: () => void;
}) {
  return (
    <div className="rounded-button border border-black/[0.07] bg-black/[0.02] p-2.5">
      <div className="flex flex-wrap items-end gap-2">
        <div className="basis-full sm:basis-0 sm:flex-1 min-w-0">
          <label className="label !mb-0.5 text-xs">Xarajat nomi</label>
          <input className="input !py-1.5 text-sm" placeholder="Masalan: payvandlash ishi"
                 value={row.label} disabled={!canWrite}
                 onChange={(e) => onPatch({ label: e.target.value })} />
        </div>
        <div className="w-[92px]">
          <label className="label !mb-0.5 text-xs">Miqdor</label>
          <input className="input !py-1.5 text-sm" type="number" min="0" step="any" disabled={!canWrite}
                 value={row.qty} onChange={(e) => onPatch({ qty: e.target.value })} />
        </div>
        <div className="w-[112px]">
          <label className="label !mb-0.5 text-xs">Narx</label>
          <input className="input !py-1.5 text-sm" type="number" min="0" step="any" disabled={!canWrite}
                 value={row.unit_price}
                 onChange={(e) => onPatch({ unit_price: parseFloat(e.target.value) || 0 })} />
        </div>
        <div className="w-[86px]">
          <label className="label !mb-0.5 text-xs">Valyuta</label>
          <select className="input !py-1.5 text-sm" value={row.currency} disabled={!canWrite}
                  onChange={(e) => onPatch({ currency: e.target.value as 'UZS' | 'USD' })}>
            <option value="UZS">so'm</option>
            <option value="USD">dollar</option>
          </select>
        </div>
        <div className="ml-auto text-right shrink-0">
          <div className="text-[11px] text-ink-soft">Summa</div>
          <div className="font-bold whitespace-nowrap">{formatMoney(lineUzs, 'UZS')}</div>
        </div>
        {canWrite && (
          <button onClick={onRemove} title="Satrni olib tashlash"
                  className="p-2 rounded-button text-ink-soft hover:bg-danger/10 hover:text-danger transition shrink-0">
            <Trash2 size={15} />
          </button>
        )}
      </div>
    </div>
  );
}
