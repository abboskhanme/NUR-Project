import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronDown, ChevronRight, History, Search } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDateTime, formatUZS } from '@/lib/format';

interface EmpSummary {
  employee_id: string;
  full_name: string;
  department_type: string;
  status: string;
  hire_date?: string | null;
  salary_type: string;
  salary_amount: string;
  months_count: number;
  total_gross: string;
  total_paid: string;
  balance: string;
  last_payment_date?: string | null;
}
interface Payment {
  id: string;
  advance_date: string;
  amount: string;
  currency: string;
  note?: string | null;
  status: string;
  kind: string;          // salary | advance
  method?: string | null;
  in_finance: boolean;
  counted: boolean;
  created_at: string;
  created_by_name?: string | null;
  voided_at?: string | null;
}
interface Adjustment {
  id: string;
  kind: string;          // bonus | penalty
  amount: string;
  note?: string | null;
  status: string;
  created_at: string;
  created_by_name?: string | null;
  voided_at?: string | null;
}
interface Override {
  id: string;
  amount: string;
  note?: string | null;
  status: string;
  created_at: string;
  created_by_name?: string | null;
  voided_at?: string | null;
}
interface Month {
  year: number;
  month: number;
  salary_type: string;
  rate_amount: string;
  present_days: number;
  total_hours: string;
  attendance_pay: string;
  override?: string | null;
  bonus: string;
  penalty: string;
  gross: string;
  paid: string;
  balance: string;
  before_hire: boolean;
  payments: Payment[];
  adjustments: Adjustment[];
  overrides: Override[];
}
interface Rate {
  effective_from: string;
  salary_type: string;
  amount: string;
  note?: string | null;
  created_at: string;
  created_by_name?: string | null;
}
interface EmpDetail extends EmpSummary {
  rates: Rate[];
  months: Month[];
}

const HR_MONTHS = [
  'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
];
const DEPT_DOT: Record<string, string> = {
  office: 'bg-red-500',
  assembly: 'bg-blue-500',
  production: 'bg-green-600',
};
const RATE_LABEL: Record<string, string> = {
  fixed: 'Oylik',
  hourly: 'Soatbay',
  daily: 'Kunbay',
};
const RATE_UNIT: Record<string, string> = { hourly: '/soat', daily: '/kun' };

const fmtDay = (d?: string | null) => (d ? d.split('-').reverse().join('.') : '—');
const num = (v: string | number | null | undefined) => parseFloat(String(v ?? 0)) || 0;
const rateText = (type: string, amount: string | number) =>
  `${RATE_LABEL[type] ?? type}: ${formatUZS(amount)}${RATE_UNIT[type] ?? ''}`;

function balanceCls(v: number) {
  return v > 0 ? 'text-danger' : v < 0 ? 'text-amber-600' : 'text-ink-soft';
}

/**
 * Oylik tarixi — barcha xodimlar (ishlamayotganlari ham), har oy uchun hisoblangan
 * oylik, berilgan to'lovlar (qachon kiritilgani, kim kiritgani, naqd/karta, bekor
 * qilinganlari ham), bonus/jarima va stavka tarixi. Faqat ko'rish uchun.
 */
export default function SalaryHistorySection() {
  const [search, setSearch] = useState('');

  const { data, isLoading } = useQuery<EmpSummary[]>({
    queryKey: ['hr', 'salary-history'],
    queryFn: () => api.get('/hr/salary-history').then((r) => r.data),
  });
  const rows = useMemo(() => {
    const q = search.trim().toLowerCase();
    const all = data ?? [];
    return q ? all.filter((r) => r.full_name.toLowerCase().includes(q)) : all;
  }, [data, search]);

  const totals = rows.reduce(
    (s, r) => ({
      gross: s.gross + num(r.total_gross),
      paid: s.paid + num(r.total_paid),
      balance: s.balance + num(r.balance),
    }),
    { gross: 0, paid: 0, balance: 0 },
  );

  return (
    <div className="space-y-4">
      <div className="rounded-card border border-black/10 bg-black/[0.02] p-4">
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <div className="flex items-center gap-2 font-semibold">
            <History size={18} /> Oylik tarixi — barcha xodimlar, barcha oylar
          </div>
          <div className="flex items-center gap-2 min-w-[200px] bg-white border border-black/10 rounded-button px-3 py-1.5">
            <Search size={15} className="text-ink-soft" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Xodim ismi"
              className="flex-1 bg-transparent outline-none text-sm"
            />
          </div>
        </div>
        <div className="mt-3 grid grid-cols-3 gap-3">
          <Stat label="Hisoblangan" value={totals.gross} />
          <Stat label="Berilgan" value={totals.paid} cls="text-success" />
          <Stat label="Qoldiq" value={totals.balance} cls={balanceCls(totals.balance)} />
        </div>
        <p className="text-xs text-ink-soft mt-2">
          Qoldiq: musbat — xodimga to'lanmagan oylik, manfiy — ortiqcha berilgan.
          To'lov qaysi oy uchun ekani — uning hisob sanasi bo'yicha; "Kiritildi" — tizimga yozilgan vaqt.
        </p>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="h-14 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : rows.length === 0 ? (
        <EmptyState title={search ? 'Topilmadi' : "Oylik tarixi yo'q"} />
      ) : (
        rows.map((r) => <EmployeeBlock key={r.employee_id} row={r} />)
      )}
    </div>
  );
}

function Stat({ label, value, cls = '' }: { label: string; value: number; cls?: string }) {
  return (
    <div>
      <div className="text-[11px] text-ink-soft">{label}</div>
      <div className={`tabular-nums font-bold ${cls}`}>{formatUZS(value)}</div>
    </div>
  );
}

function EmployeeBlock({ row }: { row: EmpSummary }) {
  const [open, setOpen] = useState(false);
  const bal = num(row.balance);

  return (
    <Card className="!p-0 overflow-hidden">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between gap-3 px-4 py-3 hover:bg-black/[0.02] flex-wrap text-left"
      >
        <div className="min-w-0">
          <div className="flex items-center gap-2 font-semibold flex-wrap">
            {open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
            <span className={`inline-block w-2 h-2 rounded-full ${DEPT_DOT[row.department_type] ?? 'bg-gray-400'}`} />
            {row.full_name}
            {row.status !== 'active' && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-black/10 text-ink-soft font-normal">Ishlamaydi</span>
            )}
          </div>
          <div className="text-xs text-ink-soft mt-0.5 pl-6">
            {rateText(row.salary_type, row.salary_amount)}
            {' · '}{row.months_count} oy
            {row.hire_date && <> · ishga kirgan: {fmtDay(row.hire_date)}</>}
            {row.last_payment_date && <> · oxirgi to'lov: {fmtDay(row.last_payment_date)}</>}
          </div>
        </div>
        <div className="flex items-center gap-4 text-sm tabular-nums">
          <span className="text-ink-soft">Hisoblangan: <b className="text-ink">{formatUZS(row.total_gross)}</b></span>
          <span className="text-ink-soft">Berilgan: <b className="text-success">{formatUZS(row.total_paid)}</b></span>
          <span className="text-ink-soft">Qoldiq: <b className={balanceCls(bal)}>{formatUZS(bal)}</b></span>
        </div>
      </button>

      {open && <EmployeeDetail employeeId={row.employee_id} />}
    </Card>
  );
}

function EmployeeDetail({ employeeId }: { employeeId: string }) {
  const [openAll, setOpenAll] = useState<boolean | null>(null);
  const { data, isLoading } = useQuery<EmpDetail>({
    queryKey: ['hr', 'salary-history', employeeId],
    queryFn: () => api.get(`/hr/salary-history/${employeeId}`).then((r) => r.data),
  });

  if (isLoading || !data) {
    return <div className="border-t border-black/5 px-4 py-3"><div className="h-10 rounded bg-black/5 animate-pulse" /></div>;
  }

  return (
    <div className="border-t border-black/5">
      <div className="px-4 py-2 flex items-start justify-between gap-3 flex-wrap bg-black/[0.015]">
        <div className="text-xs text-ink-soft space-y-0.5">
          <div className="font-medium text-ink">Stavka tarixi</div>
          {data.rates.length === 0 ? (
            <div>{rateText(data.salary_type, data.salary_amount)} (tarix yozilmagan)</div>
          ) : (
            data.rates.map((r, i) => (
              <div key={i}>
                {fmtDay(r.effective_from)} dan — {rateText(r.salary_type, r.amount)}
                {r.note && <> · {r.note}</>}
                {' · '}kiritdi: {r.created_by_name || '—'}, {formatDateTime(r.created_at)}
              </div>
            ))
          )}
        </div>
        <button
          onClick={() => setOpenAll(openAll ? false : true)}
          className="text-xs px-2.5 py-1 rounded-button border border-black/10 hover:bg-black/5"
        >
          {openAll ? 'Barchasini yopish' : 'Barcha oylarni ochish'}
        </button>
      </div>

      <div className="divide-y divide-black/5">
        {data.months.map((mo) => (
          <MonthBlock key={`${mo.year}-${mo.month}-${openAll}`} mo={mo} defaultOpen={!!openAll} />
        ))}
      </div>
    </div>
  );
}

function MonthBlock({ mo, defaultOpen }: { mo: Month; defaultOpen: boolean }) {
  const [open, setOpen] = useState(defaultOpen);
  const now = new Date();
  const isCurrent = mo.year === now.getFullYear() && mo.month === now.getMonth() + 1;
  const bal = num(mo.balance);
  const voided = mo.payments.filter((p) => p.status === 'void').length;

  return (
    <div>
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between gap-3 px-4 py-2 hover:bg-black/[0.02] flex-wrap text-left"
      >
        <div className="flex items-center gap-2 text-sm font-medium">
          {open ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
          {HR_MONTHS[mo.month - 1]} {mo.year}
          {isCurrent && <span className="text-[11px] px-1.5 py-0.5 rounded-full bg-primary/10 text-primary font-normal">joriy oy</span>}
          {mo.before_hire && <span className="text-[11px] px-1.5 py-0.5 rounded-full bg-black/10 text-ink-soft font-normal">ishga kirishdan oldin</span>}
          <span className="text-xs text-ink-soft font-normal">
            {mo.payments.length - voided} ta to'lov{voided > 0 && `, ${voided} ta bekor qilingan`}
          </span>
        </div>
        <div className="flex items-center gap-4 text-sm tabular-nums">
          <span className="text-ink-soft">Hisoblangan: <b className="text-ink">{formatUZS(mo.gross)}</b></span>
          <span className="text-ink-soft">Berilgan: <b className="text-success">{formatUZS(mo.paid)}</b></span>
          <span className="text-ink-soft">Qoldiq: <b className={balanceCls(bal)}>{formatUZS(bal)}</b></span>
        </div>
      </button>

      {open && <MonthDetail mo={mo} />}
    </div>
  );
}

function MonthDetail({ mo }: { mo: Month }) {
  const hasOverride = mo.override !== null && mo.override !== undefined;
  const base = hasOverride ? num(mo.override) : mo.salary_type === 'fixed' ? num(mo.rate_amount) : num(mo.attendance_pay);

  return (
    <div className="px-4 pb-3 pl-10 space-y-2">
      {/* Oylik qanday hisoblangani */}
      <div className="rounded-lg bg-black/[0.02] border border-black/[0.05] px-3 py-2 text-xs text-ink-soft space-y-0.5 tabular-nums">
        <div>
          {rateText(mo.salary_type, mo.rate_amount)}
          {mo.salary_type !== 'fixed' && (
            <> · {mo.present_days} kun · {num(mo.total_hours)} soat · davomat haqi {formatUZS(mo.attendance_pay)}</>
          )}
          {mo.salary_type === 'fixed' && mo.present_days > 0 && <> · {mo.present_days} kun kelgan</>}
        </div>
        {hasOverride && <div>Shu oy oyligi qo'lda belgilangan: <b className="text-ink">{formatUZS(mo.override)}</b></div>}
        <div>
          Asosiy: {formatUZS(base)}
          {num(mo.bonus) > 0 && <> + bonus {formatUZS(mo.bonus)}</>}
          {num(mo.penalty) > 0 && <> − jarima {formatUZS(mo.penalty)}</>}
          {' = '}<b className="text-ink">{formatUZS(mo.gross)}</b>
          {' · '}berilgan {formatUZS(mo.paid)}
          {' · '}qoldiq <b className={balanceCls(num(mo.balance))}>{formatUZS(mo.balance)}</b>
        </div>
      </div>

      {mo.overrides.map((o) => (
        <EventLine key={o.id} voidedAt={o.voided_at}
          label="Oy oyligi belgilandi" amount={o.amount} note={o.note}
          by={o.created_by_name} at={o.created_at} />
      ))}
      {mo.adjustments.map((a) => (
        <EventLine key={a.id} voidedAt={a.voided_at}
          label={a.kind === 'bonus' ? 'Bonus' : 'Jarima'}
          sign={a.kind === 'bonus' ? '+' : '−'}
          amount={a.amount} note={a.note} by={a.created_by_name} at={a.created_at} />
      ))}

      <div className="rounded-lg border border-black/[0.06] overflow-x-auto">
        {mo.payments.length === 0 ? (
          <div className="px-3 py-2 text-xs text-ink-soft">Bu oy uchun to'lov yo'q</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="text-[11px] text-ink-soft bg-black/[0.02]">
                <th className="py-1.5 pl-3 pr-2 text-left font-medium">Hisob sanasi</th>
                <th className="py-1.5 px-2 text-left font-medium">Turi</th>
                <th className="py-1.5 px-2 text-left font-medium">Usul</th>
                <th className="py-1.5 px-2 text-right font-medium">Summa</th>
                <th className="py-1.5 px-2 text-left font-medium">Izoh</th>
                <th className="py-1.5 pr-3 pl-2 text-left font-medium">Kiritildi</th>
              </tr>
            </thead>
            <tbody>
              {mo.payments.map((p) => {
                const isVoid = p.status === 'void';
                const strike = isVoid ? 'line-through' : '';
                return (
                  <tr key={p.id} className={`border-t border-black/5 ${isVoid ? 'text-ink-soft' : ''}`}>
                    <td className={`py-1.5 pl-3 pr-2 tabular-nums whitespace-nowrap ${strike}`}>{fmtDay(p.advance_date)}</td>
                    <td className={`py-1.5 px-2 whitespace-nowrap ${strike}`}>
                      {p.kind === 'salary' ? "Oylik to'lovi" : 'Avans'}
                    </td>
                    <td className="py-1.5 px-2 whitespace-nowrap text-xs">
                      {isVoid ? '—' : p.method === 'karta' ? 'Karta' : p.method === 'naqd' ? 'Naqd' : (
                        <span className="text-ink-soft">Moliyasiz</span>
                      )}
                    </td>
                    <td className={`py-1.5 px-2 text-right tabular-nums font-medium whitespace-nowrap ${isVoid ? 'line-through' : 'text-success'}`}>
                      {formatUZS(p.amount)}
                    </td>
                    <td className="py-1.5 px-2">
                      <span className={isVoid ? 'line-through' : 'text-ink/70'}>{p.note || '—'}</span>
                      {isVoid && (
                        <div className="text-[11px] text-danger">Bekor qilingan · {formatDateTime(p.voided_at)}</div>
                      )}
                      {!isVoid && !p.counted && (
                        <div className="text-[11px] text-amber-600">Hisobga kirmagan — ishga kirish sanasidan oldin</div>
                      )}
                    </td>
                    <td className="py-1.5 pr-3 pl-2 text-xs text-ink-soft whitespace-nowrap">
                      {p.created_by_name || '—'} · {formatDateTime(p.created_at)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

function EventLine({
  label, amount, note, by, at, voidedAt, sign = '',
}: {
  label: string;
  amount: string;
  note?: string | null;
  by?: string | null;
  at: string;
  voidedAt?: string | null;
  sign?: string;
}) {
  return (
    <div className={`text-xs ${voidedAt ? 'text-ink-soft' : 'text-ink/80'}`}>
      <span className={voidedAt ? 'line-through' : ''}>
        {label}: <b>{sign}{formatUZS(amount)}</b>{note && <> · {note}</>}
      </span>
      <span className="text-ink-soft"> · {by || '—'}, {formatDateTime(at)}</span>
      {voidedAt && <span className="text-danger"> · bekor qilingan {formatDateTime(voidedAt)}</span>}
    </div>
  );
}
