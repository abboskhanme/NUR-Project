import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, Lock, Wallet, Clock, Coins, Scale, Plus, Trash2 } from 'lucide-react';

import { api } from '@/api/client';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatUZS, formatDate } from '@/lib/format';
import type { EmployeeRow, EmployeeMonthSummary } from '@/features/hr/EmployeeModal';

export type HistoryKind = 'salary' | 'advance' | 'remaining' | 'hours';

// Mingliklarni bo'sh joy bilan formatlash: 2000000 -> "2 000 000"
function formatAmount(s: string): string {
  const cleaned = s.replace(/[^\d]/g, '').replace(/^0+(?=\d)/, '');
  return cleaned.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}
const toNum = (s: string) => parseFloat(s.replace(/[^\d.]/g, '')) || 0;

interface Advance {
  id: string;
  advance_date: string;
  amount: string;
  currency: string;
  note?: string | null;
  status?: string;
}

interface AttendanceDay {
  id: string;
  work_date: string;
  check_in?: string | null;
  check_out?: string | null;
  hours_worked: string;
  daily_pay: string;
  note?: string | null;
}

function monthRange(year: number, month: number) {
  const mm = String(month).padStart(2, '0');
  const last = new Date(year, month, 0).getDate();
  return { from: `${year}-${mm}-01`, to: `${year}-${mm}-${String(last).padStart(2, '0')}` };
}

const ICONS: Record<HistoryKind, React.ReactNode> = {
  salary: <Coins size={18} />,
  advance: <Wallet size={18} />,
  remaining: <Scale size={18} />,
  hours: <Clock size={18} />,
};

/**
 * Joriy oy uchun tanlangan ko'rsatkich tarixi modali.
 * Avans (advance) uchun — yangi avans/oylik kiritish ham mumkin; bu tranzaksiya
 * moliya bo'limiga ham yoziladi. Qolgan turlar faqat ko'rish uchun.
 */
export default function EmployeeHistoryModal({
  employee, kind, year, month, onClose,
}: {
  employee: EmployeeRow;
  kind: HistoryKind;
  year: number;
  month: number;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const editable = kind === 'advance';

  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);
  const [confirmVoid, setConfirmVoid] = useState<Advance | null>(null);
  const [voiding, setVoiding] = useState(false);

  function invalidateAll() {
    qc.invalidateQueries({ queryKey: ['employees'] });
    qc.invalidateQueries({ queryKey: ['balance-summary'] });
    qc.invalidateQueries({ queryKey: ['finance-summary'] });
    qc.invalidateQueries({ queryKey: ['finance-transactions'] });
  }

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const { from, to } = monthRange(year, month);
  const needsAdvances = kind === 'advance';
  const needsAttendance = kind === 'salary' || kind === 'hours';

  const advQ = useQuery<Advance[]>({
    queryKey: ['hr', 'advances', employee.id, year, month],
    queryFn: () => api
      .get('/hr/advances', { params: { employee_id: employee.id, date_from: from, date_to: to } })
      .then((r) => r.data),
    enabled: needsAdvances,
  });

  const attQ = useQuery<AttendanceDay[]>({
    queryKey: ['hr', 'attendance', employee.id, year, month],
    queryFn: () => api
      .get('/hr/attendance', { params: { employee_id: employee.id, date_from: from, date_to: to } })
      .then((r) => r.data),
    enabled: needsAttendance,
  });

  async function handleAddAdvance() {
    const amt = toNum(amount);
    if (!amt || amt <= 0) { toast.error(t('hr.histModal.amountRequired')); return; }
    setSaving(true);
    try {
      // Moliya endpointi: ham HR avans yozuvini, ham moliya chiqim tranzaksiyasini yaratadi
      await api.post('/finance/employee-payments', {
        employee_id: employee.id,
        kind: 'advance',
        amount: amt,
        year,
        month,
        currency: employee.currency || 'UZS',
        note: note || null,
      });
      toast.success(t('hr.histModal.advanceSaved'));
      setAmount('');
      setNote('');
      advQ.refetch();
      invalidateAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('hr.histModal.saveError'));
    } finally {
      setSaving(false);
    }
  }

  async function handleVoid() {
    if (!confirmVoid) return;
    setVoiding(true);
    try {
      await api.delete(`/hr/advances/${confirmVoid.id}`);
      toast.success(t('hr.histModal.voided'));
      setConfirmVoid(null);
      advQ.refetch();
      invalidateAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('hr.histModal.saveError'));
    } finally {
      setVoiding(false);
    }
  }

  const monthLabel = t(`hr.months.${month}`);
  const title = `${employee.full_name} — ${t(`hr.histModal.title.${kind}`)} · ${monthLabel} ${year}`;

  const isLoading = (needsAdvances && advQ.isLoading) || (needsAttendance && attQ.isLoading);

  return (
    <>
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[85vh] flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between px-5 py-4 border-b border-black/5">
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-full bg-primary/10 text-primary flex items-center justify-center shrink-0">
              {ICONS[kind]}
            </div>
            <div>
              <h3 className="font-semibold text-base leading-tight">{title}</h3>
              {!editable && (
                <p className="text-xs text-ink-soft mt-0.5 flex items-center gap-1">
                  <Lock size={11} /> {t('hr.histModal.readonly')}
                </p>
              )}
            </div>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50">
            <X size={18} />
          </button>
        </div>

        {editable && (
          <div className="px-5 pt-4">
            <div className="rounded-button border border-primary/15 bg-primary/5 p-3">
              <div className="text-sm font-medium mb-2">{t('hr.histModal.addAdvanceTitle')}</div>
              <div className="flex items-end gap-2 flex-wrap">
                <div className="flex-1 min-w-[140px]">
                  <label className="text-xs text-ink-soft">{t('hr.histModal.amountLabel')}</label>
                  <input
                    type="text"
                    inputMode="decimal"
                    className="input"
                    placeholder="0"
                    value={amount}
                    onChange={(e) => setAmount(formatAmount(e.target.value))}
                  />
                </div>
                <div className="flex-1 min-w-[140px]">
                  <label className="text-xs text-ink-soft">{t('hr.histModal.noteLabel')}</label>
                  <input
                    className="input"
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    placeholder={t('hr.histModal.notePlaceholder')}
                  />
                </div>
                <button
                  onClick={handleAddAdvance}
                  disabled={saving}
                  className="btn-primary disabled:opacity-50"
                >
                  <Plus size={16} /> {saving ? t('hr.histModal.saving') : t('hr.histModal.give')}
                </button>
              </div>
              <p className="text-[11px] text-ink-soft mt-2">{t('hr.histModal.financeHint')}</p>
            </div>
          </div>
        )}

        <div className="px-5 py-4 overflow-y-auto">
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="h-9 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : (
            <Body
              kind={kind}
              advances={advQ.data ?? []}
              attendance={attQ.data ?? []}
              summary={employee.month_summary}
              salaryType={employee.month_summary?.salary_type || employee.salary_type}
              onVoid={editable ? setConfirmVoid : undefined}
            />
          )}
        </div>
      </div>
    </div>

    <ConfirmModal
      open={!!confirmVoid}
      title={t('hr.histModal.voidTitle')}
      message={confirmVoid
        ? t('hr.histModal.voidConfirm', {
            amount: formatUZS(confirmVoid.amount),
            date: formatDate(confirmVoid.advance_date),
          })
        : ''}
      confirmText={t('hr.histModal.voidConfirmBtn')}
      loading={voiding}
      onConfirm={handleVoid}
      onCancel={() => setConfirmVoid(null)}
    />
    </>
  );
}

function Body({
  kind, advances, attendance, summary, salaryType, onVoid,
}: {
  kind: HistoryKind;
  advances: Advance[];
  attendance: AttendanceDay[];
  summary?: EmployeeMonthSummary | null;
  salaryType: string;
  onVoid?: (a: Advance) => void;
}) {
  const { t } = useTranslation();

  if (kind === 'advance') {
    // Bekor qilingan (void) avanslar jamiga kirmaydi — real holat emas
    const total = advances.reduce((s, a) => s + (a.status === 'void' ? 0 : (parseFloat(a.amount) || 0)), 0);
    if (advances.length === 0) {
      return <EmptyState title={t('hr.histModal.emptyAdvanceTitle')} description={t('hr.histModal.emptyAdvanceDesc')} />;
    }
    return (
      <table className="w-full text-sm">
        <thead className="text-left text-ink-soft border-b border-black/5">
          <tr>
            <th className="py-2 pr-4">{t('hr.histModal.colDate')}</th>
            <th className="py-2 px-4 text-right">{t('hr.histModal.colAmount')}</th>
            <th className="py-2 pl-4 w-full">{t('hr.histModal.colNote')}</th>
            <th className="py-2 pl-2 w-8"></th>
          </tr>
        </thead>
        <tbody>
          {advances.map((a) => {
            const voided = a.status === 'void';
            return (
              <tr key={a.id} className={`border-b border-black/5 ${voided ? 'text-ink/40' : ''}`}>
                <td className="py-2 pr-4 whitespace-nowrap">{formatDate(a.advance_date)}</td>
                <td className={`py-2 px-4 text-right tabular-nums font-medium whitespace-nowrap ${voided ? 'line-through' : ''}`}>
                  {formatUZS(a.amount)}
                </td>
                <td className="py-2 pl-4">
                  {voided ? (
                    <span className="badge bg-danger/10 text-danger">{t('hr.histModal.voidedBadge')}</span>
                  ) : (
                    <span className="text-ink/70">{a.note || '—'}</span>
                  )}
                </td>
                <td className="py-2 pl-2 text-right">
                  {onVoid && !voided && (
                    <button
                      title={t('hr.histModal.voidTitle')}
                      onClick={() => onVoid(a)}
                      className="p-1.5 rounded hover:bg-danger/10 text-ink/40 hover:text-danger transition-colors"
                    >
                      <Trash2 size={15} />
                    </button>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
        <tfoot>
          <tr className="border-t border-black/10 font-semibold">
            <td className="py-2 pr-4">{t('hr.histModal.total')}</td>
            <td className="py-2 px-4 text-right tabular-nums whitespace-nowrap">{formatUZS(total)}</td>
            <td colSpan={2} />
          </tr>
        </tfoot>
      </table>
    );
  }

  if (kind === 'hours') {
    const worked = attendance.filter((d) => (parseFloat(d.hours_worked) || 0) > 0);
    const total = worked.reduce((s, d) => s + (parseFloat(d.hours_worked) || 0), 0);
    if (worked.length === 0) {
      return <EmptyState title={t('hr.histModal.emptyHoursTitle')} description={t('hr.histModal.emptyHoursDesc')} />;
    }
    return (
      <table className="w-full text-sm">
        <thead className="text-left text-ink-soft border-b border-black/5">
          <tr>
            <th className="py-2 pr-4">{t('hr.histModal.colDate')}</th>
            <th className="py-2 px-4">{t('hr.histModal.colCheckIn')}</th>
            <th className="py-2 px-4">{t('hr.histModal.colCheckOut')}</th>
            <th className="py-2 pl-4 text-right">{t('hr.histModal.colHours')}</th>
          </tr>
        </thead>
        <tbody>
          {worked.map((d) => (
            <tr key={d.id} className="border-b border-black/5">
              <td className="py-2 pr-4 whitespace-nowrap">{formatDate(d.work_date)}</td>
              <td className="py-2 px-4 tabular-nums">{(d.check_in || '—').slice(0, 5)}</td>
              <td className="py-2 px-4 tabular-nums">{(d.check_out || '—').slice(0, 5)}</td>
              <td className="py-2 pl-4 text-right tabular-nums font-medium">{(parseFloat(d.hours_worked) || 0).toFixed(1)}</td>
            </tr>
          ))}
        </tbody>
        <tfoot>
          <tr className="border-t border-black/10 font-semibold">
            <td className="py-2 pr-4" colSpan={3}>{t('hr.histModal.total')}</td>
            <td className="py-2 pl-4 text-right tabular-nums">{total.toFixed(1)} {t('hr.histModal.hoursUnit')}</td>
          </tr>
        </tfoot>
      </table>
    );
  }

  // salary (gross breakdown) — kunlik to'lovlar
  if (kind === 'salary') {
    const paid = attendance.filter((d) => (parseFloat(d.daily_pay) || 0) > 0);
    const total = paid.reduce((s, d) => s + (parseFloat(d.daily_pay) || 0), 0);
    if (salaryType === 'fixed') {
      return (
        <div className="text-sm">
          <div className="border-t border-black/10 pt-2">
            <Line label={t('hr.histModal.lineGross')} value={formatUZS(summary?.gross ?? 0)} bold />
          </div>
          <p className="text-xs text-ink-soft mt-3">{t('hr.histModal.fixedHint')}</p>
        </div>
      );
    }
    if (paid.length === 0) {
      return <EmptyState title={t('hr.histModal.emptySalaryTitle')} description={t('hr.histModal.emptySalaryDesc')} />;
    }
    return (
      <table className="w-full text-sm">
        <thead className="text-left text-ink-soft border-b border-black/5">
          <tr>
            <th className="py-2 pr-4">{t('hr.histModal.colDate')}</th>
            <th className="py-2 px-4 text-right">{t('hr.histModal.colHours')}</th>
            <th className="py-2 pl-4 text-right">{t('hr.histModal.colDailyPay')}</th>
          </tr>
        </thead>
        <tbody>
          {paid.map((d) => (
            <tr key={d.id} className="border-b border-black/5">
              <td className="py-2 pr-4 whitespace-nowrap">{formatDate(d.work_date)}</td>
              <td className="py-2 px-4 text-right tabular-nums">{(parseFloat(d.hours_worked) || 0).toFixed(1)}</td>
              <td className="py-2 pl-4 text-right tabular-nums font-medium whitespace-nowrap">{formatUZS(d.daily_pay)}</td>
            </tr>
          ))}
        </tbody>
        <tfoot>
          <tr className="border-t border-black/10 font-semibold">
            <td className="py-2 pr-4" colSpan={2}>{t('hr.histModal.total')}</td>
            <td className="py-2 pl-4 text-right tabular-nums whitespace-nowrap">{formatUZS(total)}</td>
          </tr>
        </tfoot>
      </table>
    );
  }

  // remaining (qoldiq): gross − advance = net breakdown.
  // Yig'ma hisob (summary) ustuvor — fiksatsiyalangan oylik uchun ham to'g'ri bo'ladi.
  const gross = summary
    ? (parseFloat(summary.gross) || 0)
    : (salaryType === 'fixed' ? 0 : attendance.reduce((s, d) => s + (parseFloat(d.daily_pay) || 0), 0));
  const advTotal = summary
    ? (parseFloat(summary.advance) || 0)
    : advances.reduce((s, a) => s + (a.status === 'void' ? 0 : (parseFloat(a.amount) || 0)), 0);
  const net = summary ? (parseFloat(summary.net) || 0) : gross - advTotal;
  return (
    <div className="text-sm">
      <p className="text-xs text-ink-soft mb-3">{t('hr.histModal.remainingHint')}</p>
      <div className="space-y-1">
        <Line label={t('hr.histModal.lineGross')} value={formatUZS(gross)} />
        <Line label={t('hr.histModal.lineAdvance')} value={'− ' + formatUZS(advTotal)} negative />
        <div className="border-t border-black/10 mt-1 pt-2">
          <Line label={t('hr.histModal.lineRemaining')} value={formatUZS(net)} bold />
        </div>
      </div>
    </div>
  );
}

function Line({ label, value, bold, negative }: { label: string; value: string; bold?: boolean; negative?: boolean }) {
  return (
    <div className="flex items-center justify-between py-1">
      <span className={bold ? 'font-semibold' : 'text-ink-soft'}>{label}</span>
      <span className={
        'tabular-nums whitespace-nowrap ' +
        (bold ? 'font-bold text-base ' : '') +
        (negative ? 'text-warning' : '')
      }>{value}</span>
    </div>
  );
}
