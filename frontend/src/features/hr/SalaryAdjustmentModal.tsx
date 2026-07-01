import { useEffect, useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Scale, Trash2, MinusCircle, PlusCircle } from 'lucide-react';

import { api } from '@/api/client';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatUZS, formatDate } from '@/lib/format';

const HR_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentyabr', '10': 'Oktyabr', '11': 'Noyabr', '12': 'Dekabr',
};

type Kind = 'penalty' | 'bonus';

interface Adjustment {
  id: string;
  employee_id: string;
  year: number;
  month: number;
  kind: Kind;
  amount: string;
  currency: string;
  note?: string | null;
  status?: string;
  created_at: string;
}

interface EmpLite {
  id: string;
  full_name: string;
}

// Faqat raqamlar (boshidagi keraksiz nollarsiz); ko'rsatishda mingliklar ajratiladi
const onlyDigits = (s: string) => s.replace(/[^\d]/g, '').replace(/^0+(?=\d)/, '');
const groupDigits = (s: string) => s.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseFloat(s.replace(/[^\d.]/g, '')) || 0;

// FastAPI 422 xatosini xavfsiz matnga aylantiradi (obyektlar ro'yxati oq ekranга olib kelmasin)
function errText(e: any, fallback: string): string {
  const d = e?.response?.data?.detail;
  if (typeof d === 'string') return d;
  if (Array.isArray(d)) {
    const msg = d.map((x) => (typeof x === 'string' ? x : x?.msg)).filter(Boolean).join('; ');
    return msg || fallback;
  }
  if (d && typeof d === 'object') return (d.msg || d.message || fallback);
  return fallback;
}

/**
 * Jarima / bonus qo'shish modali (xodimlar ro'yxati tepasidan ochiladi).
 * Xodim + oy + yil tanlanadi, jarima yoki bonus, summa va izoh kiritiladi.
 * Tanlangan oyning hisoblangan oyligi shunga qarab o'zgaradi. Xato kiritilsa
 * — ro'yxatdan o'chirish (bekor qilish) mumkin, yozuv tarixda qoladi.
 */
export default function SalaryAdjustmentModal({
  onClose, defaultEmployeeId, defaultYear, defaultMonth,
}: {
  onClose: () => void;
  defaultEmployeeId?: string;
  defaultYear?: number;
  defaultMonth?: number;
}) {
  const qc = useQueryClient();
  const now = new Date();

  const [employeeId, setEmployeeId] = useState(defaultEmployeeId ?? '');
  const [year, setYear] = useState(defaultYear ?? now.getFullYear());
  const [month, setMonth] = useState(defaultMonth ?? now.getMonth() + 1);
  const [kind, setKind] = useState<Kind>('penalty');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  const [confirmVoid, setConfirmVoid] = useState<Adjustment | null>(null);
  const [voiding, setVoiding] = useState(false);

  const yearOptions = [now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2];

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  // Xodimlar ro'yxati (dropdown uchun)
  const empQ = useQuery<EmpLite[]>({
    queryKey: ['hr', 'employees', 'lite'],
    queryFn: () => api
      .get('/hr/employees', { params: { status: 'active', page_size: 200 } })
      .then((r) => (r.data?.items ?? []).map((e: any) => ({ id: e.id, full_name: e.full_name }))),
  });
  const employees = empQ.data ?? [];

  // Tanlangan xodim + oy uchun mavjud tuzatishlar
  const listQ = useQuery<Adjustment[]>({
    queryKey: ['hr', 'adjustments', employeeId, year, month],
    queryFn: () => api
      .get('/hr/adjustments', { params: { employee_id: employeeId, year, month } })
      .then((r) => r.data),
    enabled: !!employeeId,
  });
  const items = listQ.data ?? [];

  // Faol tuzatishlarning oylikка sof ta'siri (bonus − jarima)
  const netEffect = useMemo(
    () => items.reduce((s, a) => {
      if (a.status === 'void') return s;
      const v = parseFloat(a.amount) || 0;
      return s + (a.kind === 'bonus' ? v : -v);
    }, 0),
    [items],
  );

  function invalidateAll() {
    qc.invalidateQueries({ queryKey: ['employees'] });
    qc.invalidateQueries({ queryKey: ['hr', 'adjustments'] });
    qc.invalidateQueries({ queryKey: ['salary-debts'] });
  }

  async function handleSubmit() {
    if (!employeeId) { toast.error('Xodimni tanlang'); return; }
    const amt = toNum(amount);
    if (!amt || amt <= 0) { toast.error('Summani kiriting'); return; }
    setSaving(true);
    try {
      await api.post('/hr/adjustments', {
        employee_id: employeeId,
        year, month, kind, amount: amt,
        note: note || null,
      });
      toast.success(kind === 'bonus' ? 'Bonus qo\'shildi' : 'Jarima qo\'shildi');
      setAmount('');
      setNote('');
      listQ.refetch();
      invalidateAll();
    } catch (e: any) {
      toast.error(errText(e, 'Saqlab bo\'lmadi'));
    } finally {
      setSaving(false);
    }
  }

  async function handleVoid() {
    if (!confirmVoid) return;
    setVoiding(true);
    try {
      await api.delete(`/hr/adjustments/${confirmVoid.id}`);
      toast.success('Bekor qilindi');
      setConfirmVoid(null);
      listQ.refetch();
      invalidateAll();
    } catch (e: any) {
      toast.error(errText(e, 'O\'chirib bo\'lmadi'));
    } finally {
      setVoiding(false);
    }
  }

  const selectedEmp = employees.find((e) => e.id === employeeId);
  const isBonusForm = kind === 'bonus';
  const activeItems = items.filter((a) => a.status !== 'void');

  return (
    <>
      <div
        className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4"
        onClick={onClose}
      >
        <div
          className="bg-card rounded-2xl shadow-xl w-full max-w-lg max-h-[90vh] flex flex-col overflow-hidden"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Sarlavha */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary/20 to-primary/5 text-primary flex items-center justify-center shrink-0">
                <Scale size={20} />
              </div>
              <div>
                <h3 className="font-semibold text-base leading-tight">Jarima / Bonus</h3>
                <p className="text-xs text-ink-soft mt-0.5">
                  Tanlangan oy oyligini o'zgartiradi
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-black/5 text-ink/40 hover:text-ink transition-colors"
            >
              <X size={18} />
            </button>
          </div>

          <div className="px-5 py-4 overflow-y-auto space-y-5">
            {/* Kirish formasi */}
            <div className="space-y-4">
              {/* Tur tanlash: segmentli o'tkazgich */}
              <div className="grid grid-cols-2 gap-1 p-1 bg-black/[0.04] rounded-xl">
                <button
                  type="button"
                  onClick={() => setKind('penalty')}
                  className={
                    'flex items-center justify-center gap-1.5 py-2 rounded-lg text-sm font-medium transition-all ' +
                    (kind === 'penalty'
                      ? 'bg-white text-danger shadow-sm ring-1 ring-danger/15'
                      : 'text-ink/50 hover:text-ink/80')
                  }
                >
                  <MinusCircle size={16} /> Jarima
                </button>
                <button
                  type="button"
                  onClick={() => setKind('bonus')}
                  className={
                    'flex items-center justify-center gap-1.5 py-2 rounded-lg text-sm font-medium transition-all ' +
                    (kind === 'bonus'
                      ? 'bg-white text-green-700 shadow-sm ring-1 ring-green-600/15'
                      : 'text-ink/50 hover:text-ink/80')
                  }
                >
                  <PlusCircle size={16} /> Bonus
                </button>
              </div>

              <div>
                <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">Xodim</label>
                <select
                  className="input mt-1"
                  value={employeeId}
                  onChange={(e) => setEmployeeId(e.target.value)}
                >
                  <option value="">— Xodimni tanlang —</option>
                  {employees.map((e) => (
                    <option key={e.id} value={e.id}>{e.full_name}</option>
                  ))}
                </select>
              </div>

              <div className="flex gap-2">
                <div className="flex-1">
                  <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">Oy</label>
                  <select
                    className="input mt-1"
                    value={month}
                    onChange={(e) => setMonth(Number(e.target.value))}
                  >
                    {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                      <option key={m} value={m}>{HR_MONTHS[String(m)]}</option>
                    ))}
                  </select>
                </div>
                <div className="w-28">
                  <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">Yil</label>
                  <select
                    className="input mt-1"
                    value={year}
                    onChange={(e) => setYear(Number(e.target.value))}
                  >
                    {yearOptions.map((y) => (
                      <option key={y} value={y}>{y}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">Summa</label>
                <div className="relative mt-1">
                  <input
                    type="text"
                    inputMode="decimal"
                    className="input text-lg font-semibold pr-14 tabular-nums"
                    placeholder="0"
                    value={groupDigits(amount)}
                    onChange={(e) => setAmount(onlyDigits(e.target.value))}
                  />
                  <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-sm text-ink-soft pointer-events-none">
                    so'm
                  </span>
                </div>
              </div>

              <div>
                <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">Izoh</label>
                <input
                  className="input mt-1"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder={isBonusForm ? 'Mukofot sababi (ixtiyoriy)' : 'Jarima sababi (ixtiyoriy)'}
                />
              </div>

              <button
                onClick={handleSubmit}
                disabled={saving}
                className={
                  'btn w-full justify-center text-white disabled:opacity-50 ' +
                  (isBonusForm ? 'bg-green-600 hover:bg-green-700' : 'bg-danger hover:opacity-90')
                }
              >
                {isBonusForm ? <PlusCircle size={16} /> : <MinusCircle size={16} />}
                {saving ? 'Saqlanmoqda…' : (isBonusForm ? 'Bonus qo\'shish' : 'Jarima qo\'shish')}
              </button>
            </div>

            {/* Tanlangan oy ro'yxati */}
            {employeeId && (
              <div className="border-t border-black/5 pt-4">
                <div className="flex items-center justify-between gap-2 mb-3">
                  <div className="min-w-0">
                    <div className="text-sm font-semibold truncate">
                      {selectedEmp?.full_name ?? 'Yozuvlar'}
                    </div>
                    <div className="text-xs text-ink-soft">
                      {HR_MONTHS[String(month)]} {year}
                    </div>
                  </div>
                  {activeItems.length > 0 && (
                    <div className={
                      'shrink-0 text-right px-3 py-1.5 rounded-lg tabular-nums ' +
                      (netEffect < 0 ? 'bg-danger/10 text-danger' : netEffect > 0 ? 'bg-green-600/10 text-green-700' : 'bg-black/5 text-ink-soft')
                    }>
                      <div className="text-[10px] uppercase tracking-wide opacity-70 leading-none">Jami ta'sir</div>
                      <div className="text-sm font-bold leading-tight mt-0.5">
                        {netEffect > 0 ? '+' : ''}{formatUZS(netEffect)}
                      </div>
                    </div>
                  )}
                </div>

                {listQ.isLoading ? (
                  <div className="space-y-2">
                    {Array.from({ length: 2 }).map((_, i) => (
                      <div key={i} className="h-14 rounded-xl bg-black/5 animate-pulse" />
                    ))}
                  </div>
                ) : items.length === 0 ? (
                  <div className="text-center py-8 px-4 rounded-xl border border-dashed border-black/10">
                    <div className="w-10 h-10 rounded-full bg-black/5 text-ink/30 flex items-center justify-center mx-auto mb-2">
                      <Scale size={18} />
                    </div>
                    <p className="text-sm font-medium text-ink/70">Yozuv yo'q</p>
                    <p className="text-xs text-ink-soft mt-0.5">Bu oyda jarima yoki bonus qo'shilmagan.</p>
                  </div>
                ) : (
                  <div className="space-y-2">
                    {items.map((a) => {
                      const voided = a.status === 'void';
                      const isBonus = a.kind === 'bonus';
                      const accent = voided
                        ? 'border-black/5 bg-black/[0.02]'
                        : isBonus ? 'border-green-600/15 bg-green-600/[0.04]' : 'border-danger/15 bg-danger/[0.04]';
                      return (
                        <div
                          key={a.id}
                          className={`flex items-center gap-3 p-3 rounded-xl border ${accent}`}
                        >
                          <div className={
                            'w-9 h-9 rounded-full flex items-center justify-center shrink-0 ' +
                            (voided ? 'bg-black/5 text-ink/30'
                              : isBonus ? 'bg-green-600/15 text-green-700' : 'bg-danger/15 text-danger')
                          }>
                            {isBonus ? <PlusCircle size={17} /> : <MinusCircle size={17} />}
                          </div>

                          <div className="flex-1 min-w-0">
                            <div className="flex items-baseline gap-2">
                              <span className={
                                'text-sm font-bold tabular-nums whitespace-nowrap ' +
                                (voided ? 'text-ink/40 line-through' : isBonus ? 'text-green-700' : 'text-danger')
                              }>
                                {isBonus ? '+' : '−'}{formatUZS(a.amount)}
                              </span>
                              {voided && (
                                <span className="badge bg-black/5 text-ink/50 text-[10px]">O'chirilgan</span>
                              )}
                            </div>
                            <div className={`text-xs truncate ${voided ? 'text-ink/30' : 'text-ink-soft'}`}>
                              {(a.note || (isBonus ? 'Bonus' : 'Jarima'))} · {formatDate(a.created_at)}
                            </div>
                          </div>

                          {!voided && (
                            <button
                              title="O'chirish (bekor qilish)"
                              onClick={() => setConfirmVoid(a)}
                              className="p-2 rounded-lg text-ink/30 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
                            >
                              <Trash2 size={16} />
                            </button>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      <ConfirmModal
        open={!!confirmVoid}
        title="Bekor qilish"
        message={confirmVoid
          ? `${confirmVoid.kind === 'bonus' ? 'Bonus' : 'Jarima'} (${formatUZS(confirmVoid.amount)}) bekor qilinsinmi? Tarixda o'chirilgan holatda qoladi va bu oyning oyligiga ta'sir qilmaydi.`
          : ''}
        confirmText="Ha, bekor qilish"
        variant="danger"
        loading={voiding}
        onConfirm={handleVoid}
        onCancel={() => setConfirmVoid(null)}
      />
    </>
  );
}
