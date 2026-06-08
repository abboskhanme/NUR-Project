import { useEffect, useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import { ChevronLeft, ChevronRight, Wand2, Eraser, Save } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import ConfirmModal from '@/components/ui/ConfirmModal';
import TimeInput24 from '@/components/ui/TimeInput24';
import { formatUZS } from '@/lib/format';

interface AttRow {
  work_date: string;
  check_in: string | null;
  check_out: string | null;
}

interface DayRow {
  day: number;
  dateStr: string;
  weekday: number;
  checkIn: string;
  checkOut: string;
  locked: boolean;
}

function hhmm(t: string | null): string {
  if (!t) return '';
  return t.slice(0, 5);
}

function hoursBetween(inT: string, outT: string): number {
  if (!inT || !outT) return 0;
  const [ih, im] = inT.split(':').map(Number);
  const [oh, om] = outT.split(':').map(Number);
  if ([ih, im, oh, om].some((n) => Number.isNaN(n))) return 0;
  const diff = (oh * 60 + om) - (ih * 60 + im);
  return diff > 0 ? Math.round((diff / 60) * 100) / 100 : 0;
}

export default function MonthlyAttendance({
  employeeId,
  salaryType,
  hourlyRate,
  hireDate,
  year,
  month,
  onShiftMonth,
  onChanged,
}: {
  employeeId: string;
  salaryType: string;
  hourlyRate: number;
  hireDate: string | null;
  year: number;
  month: number;
  onShiftMonth: (delta: number) => void;
  onChanged?: () => void;
}) {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const [rows, setRows] = useState<DayRow[]>([]);
  const [defIn, setDefIn] = useState('08:30');
  const [defOut, setDefOut] = useState('18:00');
  const [saving, setSaving] = useState(false);
  const [confirmClear, setConfirmClear] = useState(false);

  const { data, isLoading } = useQuery<AttRow[]>({
    queryKey: ['hr', 'attendance', employeeId, year, month],
    queryFn: () => {
      const last = new Date(year, month, 0).getDate();
      return api
        .get('/hr/attendance', {
          params: {
            employee_id: employeeId,
            date_from: `${year}-${String(month).padStart(2, '0')}-01`,
            date_to: `${year}-${String(month).padStart(2, '0')}-${last}`,
          },
        })
        .then((r) => r.data);
    },
  });

  useEffect(() => {
    const daysInMonth = new Date(year, month, 0).getDate();
    const map = new Map<string, AttRow>();
    (data ?? []).forEach((a) => map.set(a.work_date, a));
    const hire = hireDate ? new Date(hireDate + 'T00:00:00') : null;
    const next: DayRow[] = [];
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const dt = new Date(year, month - 1, d);
      const rec = map.get(dateStr);
      next.push({
        day: d,
        dateStr,
        weekday: dt.getDay(),
        checkIn: hhmm(rec?.check_in ?? null),
        checkOut: hhmm(rec?.check_out ?? null),
        locked: hire ? dt < hire : false,
      });
    }
    setRows(next);
  }, [data, year, month, hireDate]);

  const totals = useMemo(() => {
    let hours = 0;
    let pay = 0;
    rows.forEach((r) => {
      const h = hoursBetween(r.checkIn, r.checkOut);
      hours += h;
      if (salaryType === 'hourly') pay += h * hourlyRate;
    });
    return { hours: Math.round(hours * 100) / 100, pay };
  }, [rows, salaryType, hourlyRate]);

  function setRow(day: number, patch: Partial<DayRow>) {
    setRows((prev) => prev.map((r) => (r.day === day ? { ...r, ...patch } : r)));
  }

  function fillAll() {
    // Sundays (weekday === 0) are not filled
    setRows((prev) =>
      prev.map((r) =>
        r.locked || r.weekday === 0 ? r : { ...r, checkIn: defIn, checkOut: defOut },
      ),
    );
  }

  function clearAll() {
    setRows((prev) => prev.map((r) => (r.locked ? r : { ...r, checkIn: '', checkOut: '' })));
    setConfirmClear(false);
  }

  async function handleSave() {
    setSaving(true);
    try {
      const entries = rows
        .filter((r) => !r.locked)
        .map((r) => ({
          employee_id: employeeId,
          work_date: r.dateStr,
          check_in: r.checkIn || null,
          check_out: r.checkOut || null,
          note: null,
        }));
      await api.post('/hr/attendance/batch', { entries });
      toast.success(t('hr.attendance.saved'));
      qc.invalidateQueries({ queryKey: ['hr', 'attendance', employeeId] });
      qc.invalidateQueries({ queryKey: ['hr', 'heatmap', employeeId] });
      qc.invalidateQueries({ queryKey: ['hr', 'summary', employeeId] });
      qc.invalidateQueries({ queryKey: ['hr', 'history', employeeId] });
      onChanged?.();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('hr.modal.errorGeneric'));
    } finally {
      setSaving(false);
    }
  }

  const monthName = t(`hr.months.${month}`);

  return (
    <Card>
      <div className="flex items-center justify-between flex-wrap gap-3 mb-4">
        <div className="flex items-center gap-2">
          <button onClick={() => onShiftMonth(-1)} className="p-1.5 rounded hover:bg-black/5">
            <ChevronLeft size={18} />
          </button>
          <h3 className="font-semibold text-base w-36 text-center">{monthName} {year}</h3>
          <button onClick={() => onShiftMonth(1)} className="p-1.5 rounded hover:bg-black/5">
            <ChevronRight size={18} />
          </button>
        </div>
        <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
          <Save size={16} /> {saving ? t('hr.modal.saving') : t('actions.save')}
        </button>
      </div>

      {/* Quick fill */}
      <div className="flex items-end gap-x-6 gap-y-3 flex-wrap mb-4 p-4 bg-black/[0.02] rounded-button">
        <div className="flex flex-col gap-1">
          <label className="label !mb-0">{t('hr.attendance.checkIn')}</label>
          <TimeInput24 value={defIn} onChange={setDefIn} className="!w-28" />
        </div>
        <div className="flex flex-col gap-1">
          <label className="label !mb-0">{t('hr.attendance.checkOut')}</label>
          <TimeInput24 value={defOut} onChange={setDefOut} className="!w-28" />
        </div>
        <div className="flex items-center gap-2">
          <button onClick={fillAll} className="btn-ghost"><Wand2 size={15} /> {t('hr.attendance.fillAll')}</button>
          <button onClick={() => setConfirmClear(true)} className="btn-ghost"><Eraser size={15} /> {t('hr.attendance.clearAll')}</button>
        </div>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="h-9 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-6">{t('hr.attendance.colDay')}</th>
                <th className="py-2 px-3">{t('hr.attendance.colCheckIn')}</th>
                <th className="py-2 px-3">{t('hr.attendance.colCheckOut')}</th>
                <th className="py-2 pl-3 text-right">{t('hr.attendance.colWorked')}</th>
                {salaryType === 'hourly' && <th className="py-2 pl-6 text-right">{t('hr.attendance.colDailyPay')}</th>}
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => {
                const h = hoursBetween(r.checkIn, r.checkOut);
                const isWeekend = r.weekday === 0;
                return (
                  <tr
                    key={r.day}
                    className={
                      'border-b border-black/5 ' +
                      (r.locked ? 'opacity-40 ' : 'hover:bg-black/[0.02] ') +
                      (isWeekend ? 'bg-danger/[0.03]' : '')
                    }
                  >
                    <td className="py-1.5 pr-6 whitespace-nowrap min-w-[160px]">
                      <span className="font-medium">{r.day} {monthName}</span>
                      <span className="text-ink-soft text-xs ml-2">{t(`hr.weekdays.${r.weekday}`)}</span>
                    </td>
                    <td className="py-1.5 px-3">
                      <TimeInput24
                        value={r.checkIn}
                        disabled={r.locked}
                        className="!py-1 !w-24"
                        onChange={(v) => setRow(r.day, { checkIn: v })}
                      />
                    </td>
                    <td className="py-1.5 px-3">
                      <TimeInput24
                        value={r.checkOut}
                        disabled={r.locked}
                        className="!py-1 !w-24"
                        onChange={(v) => setRow(r.day, { checkOut: v })}
                      />
                    </td>
                    <td className="py-1.5 pl-3 text-right tabular-nums">
                      {h > 0 ? h.toFixed(2).replace(/\.?0+$/, '') : '—'}
                    </td>
                    {salaryType === 'hourly' && (
                      <td className="py-1.5 pl-6 text-right tabular-nums">
                        {h > 0 ? formatUZS(h * hourlyRate) : '—'}
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-black/10 font-semibold">
                <td className="py-2 pr-6">{t('hr.attendance.totalRow')}</td>
                <td className="px-3"></td>
                <td className="px-3 text-right text-ink-soft text-xs">{t('hr.attendance.colHours')}</td>
                <td className="py-2 pl-3 text-right tabular-nums">{totals.hours.toFixed(1)}</td>
                {salaryType === 'hourly' && (
                  <td className="py-2 pl-6 text-right tabular-nums">{formatUZS(totals.pay)}</td>
                )}
              </tr>
            </tfoot>
          </table>
        </div>
      )}

      <ConfirmModal
        open={confirmClear}
        title={t('hr.attendance.confirmClearTitle')}
        message={t('hr.attendance.confirmClearMsg', { month: monthName, year })}
        confirmText={t('hr.attendance.confirmClearBtn')}
        variant="danger"
        onConfirm={clearAll}
        onCancel={() => setConfirmClear(false)}
      />
    </Card>
  );
}
