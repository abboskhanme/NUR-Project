import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, CalendarClock, Trash2, Info } from 'lucide-react';

import { api } from '@/api/client';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatUZS, formatDate } from '@/lib/format';

const HR_MONTHS: Record<string, string> = {
  '1': 'Yanvar', '2': 'Fevral', '3': 'Mart', '4': 'Aprel', '5': 'May', '6': 'Iyun',
  '7': 'Iyul', '8': 'Avgust', '9': 'Sentyabr', '10': 'Oktyabr', '11': 'Noyabr', '12': 'Dekabr',
};

interface Override {
  id: string;
  employee_id: string;
  year: number;
  month: number;
  amount: string;
  currency: string;
  note?: string | null;
  status?: string;
  created_at: string;
}

// Faqat raqamlar (boshidagi keraksiz nollarsiz); ko'rsatishda mingliklar ajratiladi
const onlyDigits = (s: string) => s.replace(/[^\d]/g, '').replace(/^0+(?=\d)/, '');
const groupDigits = (s: string) => s.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseFloat(s.replace(/[^\d.]/g, '')) || 0;

// FastAPI 422 xatosini xavfsiz matnga aylantiradi
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
 * "Muayyan oy uchun oylik" modali — tanlangan bitta oy oyligini absolute qiymatga
 * belgilaydi. Faqat o'sha oy o'zgaradi; qolgan oylar standart oylikda qoladi.
 * Jarima/bonusdan farqi: delta emas, o'sha oyning asosiy oyligini almashtiradi.
 */
export default function SalaryOverrideModal({
  employeeId, employeeName, currency = 'UZS', onClose,
}: {
  employeeId: string;
  employeeName?: string;
  currency?: string;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const now = new Date();

  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  const [confirmVoid, setConfirmVoid] = useState<Override | null>(null);
  const [voiding, setVoiding] = useState(false);

  const yearOptions = [now.getFullYear(), now.getFullYear() - 1, now.getFullYear() - 2];

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  // Tanlangan xodim + oy uchun mavjud faol override
  const monthQ = useQuery<Override[]>({
    queryKey: ['hr', 'salary-overrides', employeeId, year, month],
    queryFn: () => api
      .get('/hr/salary-overrides', { params: { employee_id: employeeId, year, month } })
      .then((r) => r.data),
    enabled: !!employeeId,
  });
  const current = (monthQ.data ?? [])[0] ?? null;

  // Shu xodimning barcha faol override'lari (pastdagi ro'yxat)
  const allQ = useQuery<Override[]>({
    queryKey: ['hr', 'salary-overrides', employeeId, 'all'],
    queryFn: () => api
      .get('/hr/salary-overrides', { params: { employee_id: employeeId } })
      .then((r) => r.data),
    enabled: !!employeeId,
  });
  const allItems = allQ.data ?? [];

  function invalidateAll() {
    qc.invalidateQueries({ queryKey: ['employees'] });
    qc.invalidateQueries({ queryKey: ['hr', 'salary-overrides'] });
    qc.invalidateQueries({ queryKey: ['hr', 'summary'] });
    qc.invalidateQueries({ queryKey: ['hr', 'history'] });
    qc.invalidateQueries({ queryKey: ['salary-debts'] });
  }

  async function handleSubmit() {
    const amt = toNum(amount);
    if (!amount || amt < 0) { toast.error('Summani kiriting'); return; }
    setSaving(true);
    try {
      await api.post('/hr/salary-overrides', {
        employee_id: employeeId,
        year, month, amount: amt,
        currency,
        note: note || null,
      });
      toast.success(`${HR_MONTHS[String(month)]} ${year} oyligi belgilandi`);
      invalidateAll();
      onClose();
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
      await api.delete(`/hr/salary-overrides/${confirmVoid.id}`);
      toast.success('Bekor qilindi');
      setConfirmVoid(null);
      monthQ.refetch();
      allQ.refetch();
      invalidateAll();
    } catch (e: any) {
      toast.error(errText(e, 'O\'chirib bo\'lmadi'));
    } finally {
      setVoiding(false);
    }
  }

  return (
    <>
      <div
        className="fixed inset-0 z-[70] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4"
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
                <CalendarClock size={20} />
              </div>
              <div>
                <h3 className="font-semibold text-base leading-tight">Muayyan oy uchun oylik</h3>
                <p className="text-xs text-ink-soft mt-0.5 truncate max-w-[16rem]">
                  {employeeName ?? 'Xodim'}
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
            <div className="flex items-start gap-2 text-xs bg-primary/5 text-ink/80 rounded-button px-3 py-2.5">
              <Info size={15} className="text-primary mt-0.5 shrink-0" />
              <span>
                Faqat tanlangan oy oyligi shu summaga o'zgaradi. Qolgan oylar standart oylikda
                qoladi. (Umumiy tahrirdagi «joriy oydan o'zgartirish» alohida ishlaydi.)
              </span>
            </div>

            {/* Kirish formasi */}
            <div className="space-y-4">
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

              {current && (
                <div className="flex items-center justify-between gap-2 px-3 py-2 rounded-lg bg-amber-500/10 text-amber-700 text-sm">
                  <span>
                    Bu oyга allaqachon belgilangan:{' '}
                    <span className="font-bold tabular-nums">{formatUZS(current.amount)}</span>
                  </span>
                  <button
                    title="Bekor qilish"
                    onClick={() => setConfirmVoid(current)}
                    className="p-1.5 rounded-lg text-amber-700/70 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              )}

              <div>
                <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">
                  Shu oy oyligi
                </label>
                <div className="relative mt-1">
                  <input
                    type="text"
                    inputMode="decimal"
                    className="input text-lg font-semibold pr-14 tabular-nums"
                    placeholder={current ? current.amount.split('.')[0] : '0'}
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
                  placeholder="Sabab (ixtiyoriy)"
                />
              </div>

              <button
                onClick={handleSubmit}
                disabled={saving}
                className="btn-primary w-full justify-center disabled:opacity-50"
              >
                {saving ? 'Saqlanmoqda…' : current ? 'Yangilash' : 'Belgilash'}
              </button>
            </div>

            {/* Belgilangan oylar ro'yxati */}
            {allItems.length > 0 && (
              <div className="border-t border-black/5 pt-4">
                <div className="text-sm font-semibold mb-3">Belgilangan oylar</div>
                <div className="space-y-2">
                  {allItems.map((o) => (
                    <div
                      key={o.id}
                      className="flex items-center gap-3 p-3 rounded-xl border border-primary/15 bg-primary/[0.04]"
                    >
                      <div className="w-9 h-9 rounded-full bg-primary/15 text-primary flex items-center justify-center shrink-0">
                        <CalendarClock size={17} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm font-bold tabular-nums whitespace-nowrap">
                          {formatUZS(o.amount)}
                        </div>
                        <div className="text-xs text-ink-soft truncate">
                          {HR_MONTHS[String(o.month)]} {o.year}
                          {o.note ? ` · ${o.note}` : ''} · {formatDate(o.created_at)}
                        </div>
                      </div>
                      <button
                        title="O'chirish (bekor qilish)"
                        onClick={() => setConfirmVoid(o)}
                        className="p-2 rounded-lg text-ink/30 hover:text-danger hover:bg-danger/10 transition-colors shrink-0"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <ConfirmModal
        open={!!confirmVoid}
        title="Bekor qilish"
        message={confirmVoid
          ? `${HR_MONTHS[String(confirmVoid.month)]} ${confirmVoid.year} uchun belgilangan oylik (${formatUZS(confirmVoid.amount)}) bekor qilinsinmi? O'sha oy yana standart oylik bo'yicha hisoblanadi.`
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
