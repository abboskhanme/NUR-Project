import { useEffect, useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, HandCoins, Wallet, Coins, AlertTriangle } from 'lucide-react';

import { api } from '@/api/client';
import { formatUZS } from '@/lib/format';

// Faqat raqamlar; ko'rsatishda mingliklar ajratiladi
const onlyDigits = (s: string) => s.replace(/[^\d]/g, '').replace(/^0+(?=\d)/, '');
const groupDigits = (s: string) => s.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
const toNum = (s: string) => parseFloat(s.replace(/[^\d.]/g, '')) || 0;

const HR_MONTHS = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
];
const pad = (n: number) => String(n).padStart(2, '0');

interface MonthAdvance {
  id: string;
  advance_date: string;
  amount: string;
  note?: string | null;
  status?: string;
}

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
 * Xodim qarzini uning oyligidan so'ndirish modali.
 * Kiritilgan summa: (1) xodim qarzidan so'ndiriladi (Xodim qarzlari bo'limidagi
 * so'ndirilgan qarzlar ro'yxatiga yoziladi); (2) o'sha summa tanlangan oy avansiga
 * qo'shiladi ("Qarzga to'landi") va o'sha oyning qolgan oyligidan ayiriladi.
 * "Oylikdan allaqachon ushlangan" belgilansa — (2) qilinmaydi (ikki marta ushlanmasin).
 * Moliya bo'limiga umuman aralashmaydi (naqd pul harakati yo'q).
 */
export default function RepayDebtModal({
  employeeId, fullName, debt, remainingSalary, year, month, onClose,
}: {
  employeeId: string;
  fullName: string;
  debt: number;
  remainingSalary?: number;
  year?: number;    // HR sahifasida ko'rilayotgan oy — default tanlov
  month?: number;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  const [alreadyDeducted, setAlreadyDeducted] = useState(false);

  // Qaysi oy oyligidan: joriy oy va oldingi 2 oy (+ sahifada ko'rilayotgan oy)
  const now = new Date();
  const curKey = `${now.getFullYear()}-${pad(now.getMonth() + 1)}`;
  const monthOptions = useMemo(() => {
    const keys: string[] = [];
    for (let i = 0; i < 3; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      keys.push(`${d.getFullYear()}-${pad(d.getMonth() + 1)}`);
    }
    const viewed = year && month ? `${year}-${pad(month)}` : null;
    if (viewed && viewed < curKey && !keys.includes(viewed)) keys.push(viewed);
    return keys;
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [year, month]);
  const viewedKey = year && month ? `${year}-${pad(month)}` : curKey;
  const [ym, setYm] = useState(monthOptions.includes(viewedKey) ? viewedKey : curKey);
  const [selY, selM] = ym.split('-').map(Number);
  const isCurrent = ym === curKey;
  const monthLabel = `${HR_MONTHS[selM - 1]} ${selY}`;
  const lastDay = new Date(selY, selM, 0).getDate();
  // Joriy oyda — bugungi sana, o'tgan oyda — o'sha oyning oxirgi kuni
  const payDate = isCurrent
    ? `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
    : `${ym}-${pad(lastDay)}`;

  // Tanlangan oyning qolgan oyligi
  const summaryQ = useQuery<{ net: string }>({
    queryKey: ['hr', 'summary', employeeId, selY, selM],
    queryFn: () => api.get(`/hr/employees/${employeeId}/summary`, { params: { year: selY, month: selM } })
      .then((r) => r.data),
  });
  const monthNet = summaryQ.data ? parseFloat(summaryQ.data.net) || 0 : remainingSalary;

  // Tanlangan oyda qo'lda kiritilgan qarz ushlanmalari — ikki marta ushlamaslik uchun ogohlantirish
  const advQ = useQuery<MonthAdvance[]>({
    queryKey: ['hr', 'advances', employeeId, selY, selM],
    queryFn: () => api.get('/hr/advances', {
      params: { employee_id: employeeId, date_from: `${ym}-01`, date_to: `${ym}-${pad(lastDay)}` },
    }).then((r) => r.data),
  });
  const loanDeductions = (advQ.data ?? []).filter(
    (a) => a.status !== 'void' && /qarz/i.test(a.note ?? ''),
  );

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const amt = toNum(amount);
  const afterDebt = Math.max(0, debt - amt);
  const overDebt = amt > debt;

  async function handleSubmit() {
    if (!amt || amt <= 0) { toast.error('Summani kiriting'); return; }
    if (overDebt) { toast.error('Summa jami qarzdan oshib ketmasligi kerak'); return; }
    setSaving(true);
    try {
      const r = await api.post(`/hr/employees/${employeeId}/repay-loan-from-salary`, {
        amount: amt,
        note: note || null,
        pay_date: payDate,
        deduct_from_salary: !alreadyDeducted,
      });
      const remaining = parseFloat(r.data?.remaining_debt ?? '0') || 0;
      toast.success(
        remaining > 0
          ? `So'ndirildi. Qolgan qarz: ${formatUZS(remaining)}`
          : 'Qarz to\'liq so\'ndirildi',
      );
      qc.invalidateQueries({ queryKey: ['employees'] });
      qc.invalidateQueries({ queryKey: ['employee-loans'] });
      qc.invalidateQueries({ queryKey: ['salary-debts'] });
      qc.invalidateQueries({ queryKey: ['hr', 'advances'] });
      qc.invalidateQueries({ queryKey: ['hr', 'employee-loans'] });
      qc.invalidateQueries({ queryKey: ['hr', 'salary-history'] });
      qc.invalidateQueries({ queryKey: ['hr', 'summary'] });
      onClose();
    } catch (e: any) {
      toast.error(errText(e, 'So\'ndirib bo\'lmadi'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4"
      onClick={onClose}
    >
      <div
        className="bg-card rounded-2xl shadow-xl w-full max-w-md flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Sarlavha */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500/20 to-amber-500/5 text-amber-600 flex items-center justify-center shrink-0">
              <HandCoins size={20} />
            </div>
            <div className="min-w-0">
              <h3 className="font-semibold text-base leading-tight truncate">Qarzni so'ndirish</h3>
              <p className="text-xs text-ink-soft mt-0.5 truncate">{fullName}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-black/5 text-ink/40 hover:text-ink transition-colors shrink-0"
          >
            <X size={18} />
          </button>
        </div>

        <div className="px-5 py-4 space-y-4">
          {/* Kontekst kartalari */}
          <div className="grid grid-cols-2 gap-2">
            <div className="rounded-xl border border-amber-500/15 bg-amber-500/[0.06] p-3">
              <div className="flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-wide text-amber-600/80">
                <Coins size={13} /> Jami qarz
              </div>
              <div className="text-base font-bold text-amber-700 tabular-nums mt-1">{formatUZS(debt)}</div>
            </div>
            <div className="rounded-xl border border-black/5 bg-black/[0.02] p-3">
              <div className="flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-wide text-ink-soft">
                <Wallet size={13} /> Qolgan oylik · {HR_MONTHS[selM - 1]}
              </div>
              <div className="text-base font-bold tabular-nums mt-1">
                {monthNet != null ? formatUZS(monthNet) : '—'}
              </div>
            </div>
          </div>

          {/* Qaysi oy oyligidan */}
          <div>
            <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">
              Qaysi oy oyligidan
            </label>
            <div className="mt-1 flex gap-1.5 flex-wrap">
              {monthOptions.map((k) => {
                const [y, m] = k.split('-').map(Number);
                return (
                  <button
                    key={k}
                    type="button"
                    onClick={() => setYm(k)}
                    className={
                      'px-3 py-1.5 rounded-button text-sm border transition-colors ' +
                      (ym === k
                        ? 'border-amber-600 bg-amber-500/10 text-amber-700 font-medium'
                        : 'border-black/10 text-ink-soft hover:bg-black/5')
                    }
                  >
                    {HR_MONTHS[m - 1]} {y}{k === curKey ? ' (joriy)' : ''}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Summa */}
          <div>
            <div className="flex items-center justify-between">
              <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">
                So'ndirish summasi
              </label>
              <button
                type="button"
                onClick={() => setAmount(onlyDigits(String(Math.round(debt))))}
                className="text-xs text-primary hover:underline"
              >
                Butun qarz
              </button>
            </div>
            <div className="relative mt-1">
              <input
                type="text"
                inputMode="decimal"
                autoFocus
                className={
                  'input text-lg font-semibold pr-14 tabular-nums ' +
                  (overDebt ? 'border-danger focus:border-danger focus:ring-danger/20' : '')
                }
                placeholder="0"
                value={groupDigits(amount)}
                onChange={(e) => setAmount(onlyDigits(e.target.value))}
              />
              <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-sm text-ink-soft pointer-events-none">
                so'm
              </span>
            </div>
            {overDebt ? (
              <p className="text-xs text-danger mt-1">Summa jami qarzdan ({formatUZS(debt)}) oshib ketdi.</p>
            ) : amt > 0 ? (
              <p className="text-xs text-ink-soft mt-1">
                So'ndirishdan keyingi qoldiq qarz: <span className="font-medium text-ink">{formatUZS(afterDebt)}</span>
              </p>
            ) : null}
          </div>

          {/* Izoh */}
          <div>
            <label className="text-[11px] font-medium uppercase tracking-wide text-ink-soft">Izoh</label>
            <input
              className="input mt-1"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Qarzga to'landi"
            />
          </div>

          {/* Shu oyda qarz uchun qo'lda ushlanma bor — ikki marta ushlanmasin */}
          {loanDeductions.length > 0 && !alreadyDeducted && (
            <div className="rounded-xl border border-amber-500/30 bg-amber-500/[0.08] p-3 text-xs text-amber-800 leading-relaxed">
              <div className="flex items-center gap-1.5 font-semibold">
                <AlertTriangle size={14} /> {monthLabel} oyligidan qarz uchun ushlanma allaqachon bor:
              </div>
              <ul className="mt-1 space-y-0.5 tabular-nums">
                {loanDeductions.map((a) => (
                  <li key={a.id}>
                    {a.advance_date.split('-').reverse().join('.')} — {formatUZS(a.amount)} «{a.note}»
                  </li>
                ))}
              </ul>
              <div className="mt-1">
                Agar shu summani qarzga yozmoqchi bo'lsangiz — pastdagi «Oylikdan allaqachon ushlangan»
                belgisini qo'ying, aks holda oylikdan ikki marta ushlanadi.
              </div>
            </div>
          )}

          <label className="flex items-start gap-2 text-sm cursor-pointer">
            <input
              type="checkbox"
              className="mt-0.5"
              checked={alreadyDeducted}
              onChange={(e) => setAlreadyDeducted(e.target.checked)}
            />
            <span>
              Oylikdan allaqachon ushlangan
              <span className="block text-xs text-ink-soft">Faqat qarz yopiladi, oylikdan qayta ushlanmaydi</span>
            </span>
          </label>

          <div className="rounded-xl bg-black/[0.03] p-3 text-xs text-ink-soft leading-relaxed">
            {alreadyDeducted ? (
              <>Bu summa faqat xodim qarzidan so'ndiriladi — <span className="font-medium text-ink">avans qo'shilmaydi</span>,
              oylik o'zgarmaydi.</>
            ) : (
              <>Bu summa xodim qarzidan so'ndiriladi va <span className="font-medium text-ink">{monthLabel}</span> avansiga
              qo'shilib, o'sha oyning qolgan oyligidan ayiriladi.</>
            )}{' '}
            Moliya bo'limiga ta'sir qilmaydi (naqd pul harakati yo'q).
          </div>

          <button
            onClick={handleSubmit}
            disabled={saving || overDebt || !amt}
            className="btn w-full justify-center bg-amber-600 text-white hover:bg-amber-700 disabled:opacity-50"
          >
            <HandCoins size={16} /> {saving ? 'So\'ndirilmoqda…' : 'So\'ndirish'}
          </button>
        </div>
      </div>
    </div>
  );
}
