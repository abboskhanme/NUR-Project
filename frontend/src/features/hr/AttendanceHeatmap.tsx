import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ChevronLeft, ChevronRight } from 'lucide-react';

import { api } from '@/api/client';

interface AttRow {
  work_date: string;
  hours_worked: string;
  daily_pay: string;
}

// GitHub-style colors (less -> more hours)
const LEVELS = ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39'];

function level(hours: number): number {
  if (hours <= 0) return 0;
  if (hours < 6) return 1;
  if (hours < 9) return 2;
  if (hours < 10) return 3;
  return 4;
}

function isoKey(d: Date): string {
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(d.getUTCDate()).padStart(2, '0')}`;
}

export default function AttendanceHeatmap({ employeeId }: { employeeId: string }) {
  const { t } = useTranslation();
  const [year, setYear] = useState(new Date().getFullYear());

  const { data } = useQuery<AttRow[]>({
    queryKey: ['hr', 'heatmap', employeeId, year],
    queryFn: () =>
      api
        .get('/hr/attendance', {
          params: {
            employee_id: employeeId,
            date_from: `${year}-01-01`,
            date_to: `${year}-12-31`,
          },
        })
        .then((r) => r.data),
  });

  const hoursMap = useMemo(() => {
    const m = new Map<string, number>();
    (data ?? []).forEach((a) => m.set(a.work_date, parseFloat(a.hours_worked) || 0));
    return m;
  }, [data]);

  const { weeks, monthLabels, totalHours, presentDays } = useMemo(() => {
    const start = new Date(Date.UTC(year, 0, 1));
    const startWeekday = (start.getUTCDay() + 6) % 7; // 0 = Monday
    const cur = new Date(start);
    cur.setUTCDate(cur.getUTCDate() - startWeekday);

    const wks: { date: Date; inYear: boolean; hours: number }[][] = [];
    let total = 0;
    let present = 0;
    while (true) {
      const week: { date: Date; inYear: boolean; hours: number }[] = [];
      for (let d = 0; d < 7; d++) {
        const inYear = cur.getUTCFullYear() === year;
        const h = inYear ? hoursMap.get(isoKey(cur)) ?? 0 : 0;
        if (inYear && h > 0) {
          total += h;
          present += 1;
        }
        week.push({ date: new Date(cur), inYear, hours: h });
        cur.setUTCDate(cur.getUTCDate() + 1);
      }
      wks.push(week);
      if (cur.getUTCFullYear() > year) break;
    }

    // Month labels per column where month changes
    const labels: { col: number; moKey: string }[] = [];
    let lastMonth = -1;
    wks.forEach((week, col) => {
      const firstInYear = week.find((c) => c.inYear);
      if (firstInYear) {
        const mo = firstInYear.date.getUTCMonth() + 1; // 1-12
        if (mo !== lastMonth) {
          labels.push({ col, moKey: String(mo) });
          lastMonth = mo;
        }
      }
    });

    return { weeks: wks, monthLabels: labels, totalHours: total, presentDays: present };
  }, [year, hoursMap]);

  // Weekday labels in Mon-Tue-...-Sun order (getDay: 0=Sun,1=Mon,...,6=Sat -> reorder)
  const weekdayKeys = [1, 2, 3, 4, 5, 6, 0]; // Mon..Sun

  const CELL = 13;
  const GAP = 3;

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <div className="text-sm text-ink-soft">
          <span className="font-semibold text-ink">{presentDays}</span>
          {' '}{t('hr.heatmapSummary', { days: presentDays, hours: totalHours.toFixed(1), year })}
        </div>
        <div className="flex items-center gap-1">
          <button onClick={() => setYear((y) => y - 1)} className="p-1 rounded hover:bg-black/5">
            <ChevronLeft size={16} />
          </button>
          <span className="text-sm font-medium w-12 text-center">{year}</span>
          <button onClick={() => setYear((y) => y + 1)} className="p-1 rounded hover:bg-black/5">
            <ChevronRight size={16} />
          </button>
        </div>
      </div>

      <div className="overflow-x-auto">
        <div className="inline-flex flex-col gap-1">
          {/* Month labels row */}
          <div className="flex" style={{ marginLeft: 26 }}>
            {weeks.map((_, col) => {
              const label = (monthLabels as { col: number; moKey: string }[]).find((l) => l.col === col);
              return (
                <div
                  key={col}
                  style={{ width: CELL + GAP }}
                  className="text-[10px] text-ink-soft"
                >
                  {label ? t(`hr.monthsShort.${label.moKey}`) : ''}
                </div>
              );
            })}
          </div>

          <div className="flex gap-[3px]">
            {/* Weekday label column */}
            <div className="flex flex-col gap-[3px] mr-1" style={{ width: 22 }}>
              {weekdayKeys.map((dayNum, i) => (
                <div key={i} style={{ height: CELL }} className="text-[10px] text-ink-soft leading-none flex items-center">
                  {t(`hr.weekdaysShort.${dayNum}`)}
                </div>
              ))}
            </div>

            {weeks.map((week, col) => (
              <div key={col} className="flex flex-col gap-[3px]">
                {week.map((cell, row) => (
                  <div
                    key={row}
                    title={
                      cell.inYear
                        ? cell.hours
                          ? t('hr.heatmapTooltipWorked', { date: isoKey(cell.date), hours: cell.hours.toFixed(1) })
                          : t('hr.heatmapTooltipOff', { date: isoKey(cell.date) })
                        : ''
                    }
                    style={{
                      width: CELL,
                      height: CELL,
                      borderRadius: 3,
                      backgroundColor: cell.inYear ? LEVELS[level(cell.hours)] : 'transparent',
                    }}
                  />
                ))}
              </div>
            ))}
          </div>

          {/* Legend */}
          <div className="flex items-center gap-1 justify-end mt-1 text-[10px] text-ink-soft">
            <span>{t('hr.heatmapLess')}</span>
            {LEVELS.map((c) => (
              <div key={c} style={{ width: 11, height: 11, borderRadius: 2, backgroundColor: c }} />
            ))}
            <span>{t('hr.heatmapMore')}</span>
          </div>
        </div>
      </div>
    </div>
  );
}
