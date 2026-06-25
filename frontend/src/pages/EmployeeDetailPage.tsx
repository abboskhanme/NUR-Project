import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Phone, MapPin, CalendarDays, Briefcase, BadgeCheck, Cake } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { formatPhone, formatDate, formatUZS } from '@/lib/format';
import AttendanceHeatmap from '@/features/hr/AttendanceHeatmap';
import MonthlyAttendance from '@/features/hr/MonthlyAttendance';
import SalaryHistory from '@/features/hr/SalaryHistory';
import SalaryRatesCard from '@/features/hr/SalaryRatesCard';
import AdvancesCard from '@/features/hr/AdvancesCard';
import { EmployeeRow } from '@/features/hr/EmployeeModal';

const HR_MONTHS: Record<string, string> = {
  '1': 'Yanvar',
  '2': 'Fevral',
  '3': 'Mart',
  '4': 'Aprel',
  '5': 'May',
  '6': 'Iyun',
  '7': 'Iyul',
  '8': 'Avgust',
  '9': 'Sentyabr',
  '10': 'Oktyabr',
  '11': 'Noyabr',
  '12': 'Dekabr',
};

const HR_SALARY_TYPE: Record<string, string> = {
  hourly: 'Soatbay',
  daily: 'Kunbay',
  fixed: 'Belgilangan',
  fixedFull: 'Belgilangan (oylik)',
  kpi: 'KPI',
};

interface Summary {
  year: number;
  month: number;
  present_days: number;
  total_hours: string;
  gross: string;
  advance: string;
  net: string;
  salary_type: string;
  hourly_rate: string;
}

export default function EmployeeDetailPage() {
  const { employeeId } = useParams<{ employeeId: string }>();
  const navigate = useNavigate();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);

  const empQ = useQuery<EmployeeRow>({
    queryKey: ['hr', 'employee', employeeId],
    queryFn: () => api.get(`/hr/employees/${employeeId}`).then((r) => r.data),
    enabled: !!employeeId,
  });

  const sumQ = useQuery<Summary>({
    queryKey: ['hr', 'summary', employeeId, year, month],
    queryFn: () =>
      api.get(`/hr/employees/${employeeId}/summary`, { params: { year, month } }).then((r) => r.data),
    enabled: !!employeeId,
  });

  const e = empQ.data;

  function shiftMonth(delta: number) {
    let m = month + delta;
    let y = year;
    if (m < 1) { m = 12; y -= 1; }
    if (m > 12) { m = 1; y += 1; }
    setMonth(m);
    setYear(y);
  }

  if (empQ.isLoading || !e) {
    return (
      <div className="space-y-4">
        <div className="h-8 w-40 rounded bg-black/5 animate-pulse" />
        <div className="h-40 rounded-lg bg-black/5 animate-pulse" />
      </div>
    );
  }

  const initial = e.full_name?.[0]?.toUpperCase() ?? '?';
  const s = sumQ.data;
  const currentMonthName = HR_MONTHS[String(month)];

  return (
    <div className="space-y-4">
      <button
        onClick={() => navigate('/hr')}
        className="flex items-center gap-1.5 text-sm text-ink-soft hover:text-ink"
      >
        <ArrowLeft size={16} /> Xodimlarga qaytish
      </button>

      {/* Header */}
      <Card>
        <div className="flex items-start gap-4 flex-wrap">
          <div className="w-16 h-16 rounded-full bg-primary/10 text-primary flex items-center justify-center text-2xl font-bold shrink-0">
            {initial}
          </div>
          <div className="flex-1 min-w-[200px]">
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold">{e.full_name}</h1>
              {e.has_account && <BadgeCheck size={18} className="text-primary" />}
              {e.status === 'active' ? (
                <span className="badge bg-success/10 text-success">Faol</span>
              ) : (
                <span className="badge bg-gray-100 text-gray-700">Ishdan ketgan</span>
              )}
            </div>
            <div className="mt-2 grid grid-cols-2 md:grid-cols-3 gap-x-6 gap-y-1.5 text-sm text-ink/80">
              <span className="flex items-center gap-2"><Briefcase size={14} className="text-ink/40" /> {e.position_name || '—'}</span>
              <span className="flex items-center gap-2"><Phone size={14} className="text-ink/40" /> {formatPhone(e.phone)}</span>
              {e.secondary_phone && (
                <span className="flex items-center gap-2"><Phone size={14} className="text-ink/40" /> {formatPhone(e.secondary_phone)}</span>
              )}
              <span className="flex items-center gap-2"><Cake size={14} className="text-ink/40" /> {e.birth_date ? formatDate(e.birth_date) : '—'}</span>
              <span className="flex items-center gap-2"><CalendarDays size={14} className="text-ink/40" /> Ish boshlagan: {e.hire_date ? formatDate(e.hire_date) : '—'}</span>
              <span className="flex items-center gap-2"><MapPin size={14} className="text-ink/40" /> {e.address || '—'}</span>
            </div>
            <div className="mt-2 text-sm text-ink-soft">
              {(HR_SALARY_TYPE[String(e.salary_type)] ?? e.salary_type)}:{' '}
              <span className="font-medium text-ink">{formatUZS(e.salary_amount)}</span>
              {e.salary_type === 'hourly' && '/ soat'}
            </div>
          </div>
        </div>
      </Card>

      {/* Heatmap */}
      <Card title="Davomat faolligi">
        <AttendanceHeatmap employeeId={employeeId!} />
      </Card>

      {/* Monthly summary stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <StatCard label={`Ish kuni (${currentMonthName})`} value={s ? String(s.present_days) : '—'} />
        <StatCard label="Jami soat" value={s ? parseFloat(s.total_hours).toFixed(1) : '—'} />
        <StatCard label="Hisoblangan" value={s ? formatUZS(s.gross) : '—'} accent="text-ink" />
        <StatCard label="Qoldiq (avans chegirilgan)" value={s ? formatUZS(s.net) : '—'} accent="text-success" />
      </div>

      <MonthlyAttendance
        employeeId={employeeId!}
        salaryType={s?.salary_type ?? e.salary_type}
        hourlyRate={parseFloat(s?.hourly_rate ?? e.salary_amount) || 0}
        hireDate={e.hire_date ?? null}
        year={year}
        month={month}
        onShiftMonth={shiftMonth}
      />

      <SalaryRatesCard employeeId={employeeId!} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <SalaryHistory employeeId={employeeId!} />
        <AdvancesCard employeeId={employeeId!} />
      </div>
    </div>
  );
}

function StatCard({ label, value, accent }: { label: string; value: string; accent?: string }) {
  return (
    <div className="card !p-4">
      <div className="text-xs text-ink-soft">{label}</div>
      <div className={'text-xl font-bold mt-1 ' + (accent ?? 'text-ink')}>{value}</div>
    </div>
  );
}
