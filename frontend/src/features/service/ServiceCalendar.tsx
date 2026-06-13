import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import {
  startOfMonth, endOfMonth, startOfWeek, endOfWeek, eachDayOfInterval,
  isSameMonth, isSameDay, addMonths, subMonths, parseISO, format,
} from 'date-fns';
import { ChevronLeft, ChevronRight } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';

interface Ticket {
  id: string; code: string; status: string; scheduled_at?: string | null;
  customer?: { full_name: string } | null;
}

const STATUS_DOT: Record<string, string> = {
  new: 'bg-primary', scheduled: 'bg-warning',
  completed: 'bg-success', cancelled: 'bg-ink-soft',
};

const WEEKDAY_KEYS = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'] as const;

/**
 * Rejalashtirilgan servis tashriflarining oylik kalendar ko'rinishi.
 * Sahifa joylashuvini o'zgartirmaydi — ro'yxat/kalendar almashtirgich orqali ochiladi.
 */
export default function ServiceCalendar({ onSelect }: { onSelect: (id: string) => void }) {
  const { t } = useTranslation();
  const [cursor, setCursor] = useState(() => {
    const n = new Date();
    return new Date(n.getFullYear(), n.getMonth(), 1);
  });

  // Rejalashtirilgan chiptalarni olamiz (sana bo'yicha joylash uchun)
  const { data } = useQuery<{ items: Ticket[] }>({
    queryKey: ['service-calendar'],
    queryFn: () => api.get('/service/tickets', {
      params: { status: 'scheduled', page_size: 100 },
    }).then((r) => r.data),
  });

  const days = useMemo(() => {
    const start = startOfWeek(startOfMonth(cursor), { weekStartsOn: 1 });
    const end = endOfWeek(endOfMonth(cursor), { weekStartsOn: 1 });
    return eachDayOfInterval({ start, end });
  }, [cursor]);

  // Kun -> chiptalar xaritasi
  const byDay = useMemo(() => {
    const map = new Map<string, Ticket[]>();
    for (const tk of data?.items ?? []) {
      if (!tk.scheduled_at) continue;
      const key = format(parseISO(tk.scheduled_at), 'yyyy-MM-dd');
      const arr = map.get(key) ?? [];
      arr.push(tk);
      map.set(key, arr);
    }
    return map;
  }, [data]);

  const today = new Date();
  const monthLabel = t(`sales.months.${cursor.getMonth() + 1}`) + ' ' + cursor.getFullYear();

  return (
    <Card
      title={monthLabel}
      action={
        <div className="flex items-center gap-1">
          <button onClick={() => setCursor((c) => subMonths(c, 1))} className="p-1.5 rounded hover:bg-black/5 text-ink/60">
            <ChevronLeft size={16} />
          </button>
          <button onClick={() => setCursor(new Date(today.getFullYear(), today.getMonth(), 1))}
                  className="px-2.5 py-1 rounded-button text-xs border border-black/10 hover:bg-black/5">
            {t('service.calendar.today')}
          </button>
          <button onClick={() => setCursor((c) => addMonths(c, 1))} className="p-1.5 rounded hover:bg-black/5 text-ink/60">
            <ChevronRight size={16} />
          </button>
        </div>
      }
    >
      <div className="grid grid-cols-7 gap-px text-center text-xs text-ink-soft mb-1">
        {WEEKDAY_KEYS.map((d) => (
          <div key={d} className="py-1 font-medium">{t(`service.calendar.weekdays.${d}`)}</div>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-px bg-black/5 rounded-lg overflow-hidden">
        {days.map((day) => {
          const key = format(day, 'yyyy-MM-dd');
          const dayTickets = byDay.get(key) ?? [];
          const muted = !isSameMonth(day, cursor);
          const isToday = isSameDay(day, today);
          return (
            <div key={key}
                 className={`min-h-[84px] bg-card p-1.5 text-left ${muted ? 'opacity-40' : ''}`}>
              <div className={`text-xs mb-1 inline-flex items-center justify-center w-5 h-5 rounded-full ${
                isToday ? 'bg-primary text-white font-semibold' : 'text-ink-soft'}`}>
                {day.getDate()}
              </div>
              <div className="space-y-1">
                {dayTickets.slice(0, 3).map((tk) => (
                  <button key={tk.id} onClick={() => onSelect(tk.id)}
                          title={`${tk.code} · ${tk.customer?.full_name ?? ''}`}
                          className="w-full flex items-center gap-1 text-left px-1 py-0.5 rounded bg-black/5 hover:bg-primary/10">
                    <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${STATUS_DOT[tk.status] ?? 'bg-ink-soft'}`} />
                    <span className="text-[11px] truncate">{tk.customer?.full_name ?? tk.code}</span>
                  </button>
                ))}
                {dayTickets.length > 3 && (
                  <div className="text-[10px] text-ink-soft px-1">+{dayTickets.length - 3}</div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}
