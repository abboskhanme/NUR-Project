import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChevronDown, ChevronRight, History, Pencil, Search, Trash2 } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import { formatDateTime, formatUZS } from '@/lib/format';

interface HistPayment {
  id: string;
  amount: string;
  pay_date: string;
  note?: string | null;
  created_at: string;
  created_by_name?: string | null;
  deleted_at?: string | null;
  deleted_by_name?: string | null;
}
interface HistEdit {
  at: string;
  by_name?: string | null;
  changes: Record<string, [string | null, string | null]>;
}
interface HistLoan {
  id: string;
  amount: string;
  currency: string;
  source: string;
  loan_date: string;
  note?: string | null;
  status: string;        // active | closed | deleted
  created_at: string;
  created_by_name?: string | null;
  deleted_at?: string | null;
  deleted_by_name?: string | null;
  paid: string;
  balance: string;
  payments: HistPayment[];
  edits: HistEdit[];
}
interface HistGroup {
  employee_id: string;
  full_name: string;
  department_type: string;
  total_taken: string;
  total_paid: string;
  balance: string;
  items: HistLoan[];
}

const DEPT_DOT: Record<string, string> = {
  office: 'bg-red-500',
  assembly: 'bg-blue-500',
  production: 'bg-green-600',
};
const SOURCE_LABELS: Record<string, string> = {
  director: 'Direktordan',
  firma: 'Firmadan',
  other: 'Boshqa',
};
const STATUS: Record<string, { label: string; cls: string }> = {
  active: { label: 'Faol', cls: 'bg-danger/10 text-danger' },
  closed: { label: "To'liq so'ndirilgan", cls: 'bg-success/10 text-success' },
  deleted: { label: "O'chirilgan", cls: 'bg-black/10 text-ink-soft' },
};
const FIELD_LABELS: Record<string, string> = {
  amount: 'Summa',
  source: 'Manba',
  loan_date: 'Sana',
  note: 'Izoh',
  status: 'Holat',
};

/** "2026-07-03" -> "03.07.2026" (vaqt mintaqasiga bog'liq emas) */
const fmtDay = (d: string) => d.split('-').reverse().join('.');
const num = (v: string | number | null | undefined) => parseFloat(String(v ?? 0)) || 0;

function fmtEditValue(field: string, v: string | null): string {
  if (v === null || v === '') return '—';
  if (field === 'amount') return formatUZS(v);
  if (field === 'loan_date') return fmtDay(v);
  if (field === 'source') return SOURCE_LABELS[v] ?? v;
  if (field === 'status') return STATUS[v]?.label ?? v;
  return v;
}

/**
 * Xodim qarzlarining to'liq tarixi — barcha xodimlar, faol, to'liq so'ndirilgan va
 * o'chirilgan qarzlar; har bir so'ndirish (o'chirilganlari ham), tahrirlar, kim kiritgani.
 * Faqat ko'rish uchun — amallar "Faol qarzlar" ko'rinishida.
 */
export default function EmployeeLoansHistory() {
  const [search, setSearch] = useState('');

  const { data, isLoading } = useQuery<HistGroup[]>({
    queryKey: ['hr', 'employee-loans', 'history'],
    queryFn: () => api.get('/hr/employee-loans/history').then((r) => r.data),
  });
  const groups = useMemo(() => {
    const q = search.trim().toLowerCase();
    const all = data ?? [];
    return q ? all.filter((g) => g.full_name.toLowerCase().includes(q)) : all;
  }, [data, search]);

  const totals = groups.reduce(
    (s, g) => ({
      taken: s.taken + num(g.total_taken),
      paid: s.paid + num(g.total_paid),
      balance: s.balance + num(g.balance),
    }),
    { taken: 0, paid: 0, balance: 0 },
  );

  return (
    <div className="space-y-4">
      <div className="rounded-card border border-black/10 bg-black/[0.02] p-4">
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <div className="flex items-center gap-2 font-semibold">
            <History size={18} /> Barcha xodimlar — to'liq qarz tarixi
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
          <Stat label="Olingan" value={totals.taken} />
          <Stat label="So'ndirilgan" value={totals.paid} cls="text-success" />
          <Stat label="Qoldiq" value={totals.balance} cls="text-danger" />
        </div>
        <p className="text-xs text-ink-soft mt-2">
          O'chirilgan qarz va so'ndirishlar ham ko'rsatiladi (ustidan chizilgan), lekin jamilarga kirmaydi.
        </p>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-16 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : groups.length === 0 ? (
        <EmptyState title={search ? 'Topilmadi' : "Qarz tarixi yo'q"} />
      ) : (
        groups.map((g) => <EmpHistory key={g.employee_id} g={g} />)
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

function EmpHistory({ g }: { g: HistGroup }) {
  const [open, setOpen] = useState(true);

  return (
    <Card className="!p-0 overflow-hidden">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between gap-3 px-4 py-3 hover:bg-black/[0.02] flex-wrap"
      >
        <div className="flex items-center gap-2 font-semibold">
          {open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
          <span className={`inline-block w-2 h-2 rounded-full ${DEPT_DOT[g.department_type] ?? 'bg-gray-400'}`} />
          {g.full_name}
          <span className="text-xs px-2 py-0.5 rounded-full bg-black/5 text-ink-soft">
            {g.items.length} ta qarz
          </span>
        </div>
        <div className="flex items-center gap-4 text-sm tabular-nums">
          <span className="text-ink-soft">Olingan: <b className="text-ink">{formatUZS(g.total_taken)}</b></span>
          <span className="text-ink-soft">To'langan: <b className="text-success">{formatUZS(g.total_paid)}</b></span>
          <span className="text-ink-soft">Qoldiq: <b className="text-danger">{formatUZS(g.balance)}</b></span>
        </div>
      </button>

      {open && (
        <div className="border-t border-black/5 divide-y divide-black/5">
          {g.items.map((loan) => <LoanHistory key={loan.id} loan={loan} />)}
        </div>
      )}
    </Card>
  );
}

function LoanHistory({ loan }: { loan: HistLoan }) {
  const deleted = loan.status === 'deleted';
  const st = STATUS[loan.status] ?? { label: loan.status, cls: 'bg-black/5' };

  // Har bir so'ndirishdan keyingi qoldiq — o'chirilganlar hisobga kirmaydi
  let running = num(loan.amount);
  const rows = loan.payments.map((p) => {
    if (!p.deleted_at) running -= num(p.amount);
    return { p, after: p.deleted_at ? null : running };
  });

  return (
    <div className={`px-4 py-3 ${deleted ? 'bg-black/[0.02]' : ''}`}>
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${st.cls}`}>{st.label}</span>
            <span className="text-xs px-2 py-0.5 rounded-full bg-black/5">
              {SOURCE_LABELS[loan.source] ?? loan.source}
            </span>
            <span className="text-xs text-ink-soft tabular-nums">{fmtDay(loan.loan_date)}</span>
            {loan.note && <span className="text-sm text-ink/70">· {loan.note}</span>}
          </div>
          <div className="mt-1 text-xs text-ink-soft">
            Kiritdi: {loan.created_by_name || '—'} · {formatDateTime(loan.created_at)}
          </div>
          {deleted && (
            <div className="mt-0.5 text-xs text-danger inline-flex items-center gap-1">
              <Trash2 size={12} /> O'chirildi: {loan.deleted_by_name || '—'} · {formatDateTime(loan.deleted_at)}
            </div>
          )}
        </div>
        <div className="flex items-center gap-4 text-right tabular-nums">
          <div>
            <div className="text-[11px] text-ink-soft">Asosiy</div>
            <div className={`font-semibold ${deleted ? 'line-through text-ink-soft' : ''}`}>{formatUZS(loan.amount)}</div>
          </div>
          <div>
            <div className="text-[11px] text-ink-soft">So'ndirilgan</div>
            <div className="font-semibold text-success">{formatUZS(loan.paid)}</div>
          </div>
          <div>
            <div className="text-[11px] text-ink-soft">Qoldiq</div>
            <div className={`font-bold ${deleted ? 'text-ink-soft' : 'text-danger'}`}>{formatUZS(loan.balance)}</div>
          </div>
        </div>
      </div>

      {loan.edits.length > 0 && (
        <div className="mt-2 space-y-0.5">
          {loan.edits.map((e, i) => (
            <div key={i} className="text-xs text-ink-soft flex items-start gap-1">
              <Pencil size={12} className="mt-0.5 shrink-0" />
              <span>
                Tahrirlandi {formatDateTime(e.at)} — {e.by_name || '—'}:{' '}
                {Object.entries(e.changes).map(([f, [from, to]], j) => (
                  <span key={f}>
                    {j > 0 && '; '}
                    {FIELD_LABELS[f] ?? f}: {fmtEditValue(f, from)} → <b className="text-ink">{fmtEditValue(f, to)}</b>
                  </span>
                ))}
              </span>
            </div>
          ))}
        </div>
      )}

      <div className="mt-2 rounded-lg border border-black/[0.06] overflow-x-auto">
        {rows.length === 0 ? (
          <div className="px-3 py-2 text-xs text-ink-soft">So'ndirish yo'q</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="text-[11px] text-ink-soft bg-black/[0.02]">
                <th className="py-1.5 pl-3 pr-2 text-left font-medium w-[100px]">Sana</th>
                <th className="py-1.5 px-2 text-left font-medium">Izoh</th>
                <th className="py-1.5 px-2 text-right font-medium">To'landi</th>
                <th className="py-1.5 px-2 text-right font-medium">Qoldiq</th>
                <th className="py-1.5 pr-3 pl-2 text-left font-medium">Kiritdi</th>
              </tr>
            </thead>
            <tbody>
              {rows.map(({ p, after }) => {
                const pDeleted = !!p.deleted_at;
                return (
                  <tr key={p.id} className={`border-t border-black/5 ${pDeleted ? 'text-ink-soft' : ''}`}>
                    <td className={`py-1.5 pl-3 pr-2 tabular-nums ${pDeleted ? 'line-through' : ''}`}>{fmtDay(p.pay_date)}</td>
                    <td className="py-1.5 px-2">
                      <span className={pDeleted ? 'line-through' : 'text-ink/70'}>{p.note || '—'}</span>
                      {pDeleted && (
                        <div className="text-[11px] text-danger inline-flex items-center gap-1">
                          <Trash2 size={11} /> O'chirildi: {p.deleted_by_name || '—'} · {formatDateTime(p.deleted_at)}
                        </div>
                      )}
                    </td>
                    <td className={`py-1.5 px-2 text-right tabular-nums font-medium ${pDeleted ? 'line-through' : 'text-success'}`}>
                      {formatUZS(p.amount)}
                    </td>
                    <td className="py-1.5 px-2 text-right tabular-nums">
                      {after === null ? '—' : formatUZS(after)}
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
