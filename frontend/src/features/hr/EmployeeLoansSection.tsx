import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Pencil, Trash2, Coins, X, ChevronDown, ChevronRight, HandCoins, History,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import Select from '@/components/ui/Select';
import MoneyInput from '@/components/ui/MoneyInput';
import DateInput from '@/components/ui/DateInput';
import { formatUZS } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';

interface Payment {
  id: string;
  loan_id: string;
  amount: string;
  pay_date: string;
  note?: string | null;
}
interface Loan {
  id: string;
  employee_id: string;
  amount: string;        // asosiy qarz (principal)
  currency: string;
  source: string;        // "director" | "firma" | "other"
  loan_date: string;
  note?: string | null;
  status: string;
  paid: string;          // so'ndirilgan
  balance: string;       // qoldiq
  payments: Payment[];
}
interface LoanGroup {
  employee_id: string;
  full_name: string;
  department_type: string;
  total: string;         // jami qoldiq
  items: Loan[];
}
interface EmpOpt { id: string; full_name: string }

const DEPT_DOT: Record<string, string> = {
  office: 'bg-red-500',
  assembly: 'bg-blue-500',
  production: 'bg-green-600',
};
const SOURCES = ['director', 'firma', 'other'] as const;

const SOURCE_LABELS: Record<string, string> = {
  director: 'Direktordan',
  firma: 'Firmadan',
  other: 'Boshqa',
};
const sourceLabel = (s: string) =>
  SOURCE_LABELS[s] ?? (s === 'director' ? 'Direktordan' : s === 'firma' ? 'Firmadan' : 'Boshqa');

/**
 * Bizdan qarzdor xodimlar — director/firmadan olingan alohida qarzlar (oylikdan tashqari).
 * Har bir qarzni so'ndirish (qaytarish) mumkin; so'ndirish ichki tarixda saqlanadi.
 * Qoldiq = asosiy summa − so'ndirilganlar. Qoldiq 0 bo'lsa qarz ro'yxatdan tushadi (tarix qoladi).
 */
export default function EmployeeLoansSection() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('hr:write');
  const canDelete = can('hr:delete');

  const [editing, setEditing] = useState<Loan | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [repayLoan, setRepayLoan] = useState<Loan | null>(null);
  const [confirm, setConfirm] = useState<
    { kind: 'loan'; loan: Loan } | { kind: 'payment'; loanId: string; payment: Payment } | null
  >(null);
  const [busy, setBusy] = useState(false);

  const { data, isLoading } = useQuery<LoanGroup[]>({
    queryKey: ['hr', 'employee-loans'],
    queryFn: () => api.get('/hr/employee-loans').then((r) => r.data),
  });
  const groups = data ?? [];
  const grandTotal = groups.reduce((s, g) => s + (parseFloat(g.total) || 0), 0);

  function refresh() {
    qc.invalidateQueries({ queryKey: ['hr', 'employee-loans'] });
  }

  async function doConfirm() {
    if (!confirm) return;
    setBusy(true);
    try {
      if (confirm.kind === 'loan') {
        await api.delete(`/hr/employee-loans/${confirm.loan.id}`);
      } else {
        await api.delete(`/hr/employee-loans/${confirm.loanId}/payments/${confirm.payment.id}`);
      }
      toast.success("O'chirildi");
      refresh();
      setConfirm(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      {/* Jami qoldiq + qo'shish */}
      <div className="rounded-card border border-danger/20 bg-danger/5 p-4">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <div className="flex items-center gap-2 font-semibold text-danger">
            <Coins size={18} /> Bizdan qarzdor xodimlar — jami
          </div>
          {canWrite && (
            <button onClick={() => { setEditing(null); setShowForm(true); }} className="btn-primary">
              <Plus size={16} /> Qarz qo'shish
            </button>
          )}
        </div>
        <div className="mt-2 text-2xl font-bold tabular-nums text-danger">{formatUZS(grandTotal)}</div>
        <p className="text-xs text-ink-soft mt-1">
          Director/firmadan olingan alohida qarzlar yig'indisi (oylikdan tashqari).
        </p>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-16 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : groups.length === 0 ? (
        <EmptyState title="Qarzdor xodimlar yo'q" />
      ) : (
        groups.map((g) => (
          <EmpBlock
            key={g.employee_id}
            g={g}
            canWrite={canWrite}
            canDelete={canDelete}
            onRepay={setRepayLoan}
            onEdit={(l) => { setEditing(l); setShowForm(true); }}
            onDeleteLoan={(loan) => setConfirm({ kind: 'loan', loan })}
            onDeletePayment={(loanId, payment) => setConfirm({ kind: 'payment', loanId, payment })}
          />
        ))
      )}

      {showForm && (
        <LoanForm
          loan={editing}
          onClose={() => { setShowForm(false); setEditing(null); }}
          onSaved={refresh}
        />
      )}

      {repayLoan && (
        <RepayForm loan={repayLoan} onClose={() => setRepayLoan(null)} onSaved={refresh} />
      )}

      <ConfirmModal
        open={!!confirm}
        title={
          confirm?.kind === 'payment'
            ? "So'ndirishni bekor qilish"
            : "Qarzni o'chirish"
        }
        message={
          confirm?.kind === 'payment'
            ? 'Bu so\'ndirish yozuvi o\'chiriladi, qoldiq qaytadi.'
            : "Qarz va uning butun so'ndirish tarixi o'chiriladi."
        }
        confirmText="O'chirish"
        variant="danger"
        loading={busy}
        onConfirm={doConfirm}
        onCancel={() => !busy && setConfirm(null)}
      />
    </div>
  );
}

function EmpBlock({
  g, canWrite, canDelete, onRepay, onEdit, onDeleteLoan, onDeletePayment,
}: {
  g: LoanGroup;
  canWrite: boolean;
  canDelete: boolean;
  onRepay: (l: Loan) => void;
  onEdit: (l: Loan) => void;
  onDeleteLoan: (l: Loan) => void;
  onDeletePayment: (loanId: string, p: Payment) => void;
}) {
  const [open, setOpen] = useState(true);

  return (
    <Card className="!p-0 overflow-hidden">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between gap-3 px-4 py-3 hover:bg-black/[0.02]"
      >
        <div className="flex items-center gap-2 font-semibold">
          {open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
          <span className={`inline-block w-2 h-2 rounded-full ${DEPT_DOT[g.department_type] ?? 'bg-gray-400'}`} />
          {g.full_name}
          <span className="text-xs px-2 py-0.5 rounded-full bg-black/5 text-ink-soft">
            {g.items.length} ta qarz
          </span>
        </div>
        <span className="tabular-nums font-bold text-danger">{formatUZS(g.total)}</span>
      </button>

      {open && (
        <div className="border-t border-black/5 divide-y divide-black/5">
          {g.items.map((loan) => (
            <LoanRow
              key={loan.id}
              loan={loan}
              canWrite={canWrite}
              canDelete={canDelete}
              onRepay={onRepay}
              onEdit={onEdit}
              onDeleteLoan={onDeleteLoan}
              onDeletePayment={onDeletePayment}
            />
          ))}
        </div>
      )}
    </Card>
  );
}

function LoanRow({
  loan, canWrite, canDelete, onRepay, onEdit, onDeleteLoan, onDeletePayment,
}: {
  loan: Loan;
  canWrite: boolean;
  canDelete: boolean;
  onRepay: (l: Loan) => void;
  onEdit: (l: Loan) => void;
  onDeleteLoan: (l: Loan) => void;
  onDeletePayment: (loanId: string, p: Payment) => void;
}) {
  const [showHistory, setShowHistory] = useState(false);
  const hasPayments = loan.payments.length > 0;
  const balance = parseFloat(loan.balance) || 0;

  return (
    <div className="px-4 py-3">
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs px-2 py-0.5 rounded-full bg-black/5">{sourceLabel(loan.source)}</span>
            <span className="text-xs text-ink-soft tabular-nums">{loan.loan_date}</span>
            {loan.note && <span className="text-sm text-ink/70 truncate">· {loan.note}</span>}
          </div>
          <div className="mt-1 text-xs text-ink-soft tabular-nums">
            Asosiy: {formatUZS(loan.amount)}
            {' · '}
            So'ndirilgan: <span className="text-success">{formatUZS(loan.paid)}</span>
          </div>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <div className="text-right">
            <div className="text-[11px] text-ink-soft">Qoldiq</div>
            <div className="tabular-nums font-bold text-danger">{formatUZS(balance)}</div>
          </div>
          {canWrite && balance > 0 && (
            <button
              onClick={() => onRepay(loan)}
              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-button text-xs font-medium bg-success/10 text-success hover:bg-success/20"
            >
              <HandCoins size={14} /> So'ndirish
            </button>
          )}
          {canWrite && (
            <button title="Tahrirlash" onClick={() => onEdit(loan)}
                    className="p-1.5 rounded hover:bg-black/5 text-ink/60">
              <Pencil size={15} />
            </button>
          )}
          {canDelete && (
            <button title="O'chirish" onClick={() => onDeleteLoan(loan)}
                    className="p-1.5 rounded hover:bg-danger/10 text-danger">
              <Trash2 size={15} />
            </button>
          )}
        </div>
      </div>

      {hasPayments && (
        <div className="mt-2">
          <button
            onClick={() => setShowHistory((v) => !v)}
            className="inline-flex items-center gap-1 text-xs text-ink-soft hover:text-ink"
          >
            <History size={13} />
            So'ndirish tarixi ({loan.payments.length})
            {showHistory ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
          </button>

          {showHistory && (
            <div className="mt-2 rounded-lg border border-black/[0.06] overflow-hidden">
              <table className="w-full text-sm">
                <tbody>
                  {loan.payments.map((p) => (
                    <tr key={p.id} className="border-b border-black/5 last:border-0">
                      <td className="py-1.5 pl-3 pr-2 tabular-nums text-ink-soft w-[110px]">{p.pay_date}</td>
                      <td className="py-1.5 px-2 text-ink/70 truncate">{p.note || '—'}</td>
                      <td className="py-1.5 px-2 text-right tabular-nums font-medium text-success">{formatUZS(p.amount)}</td>
                      <td className="py-1.5 pr-3 pl-2 text-right w-[40px]">
                        {canDelete && (
                          <button title="O'chirish" onClick={() => onDeletePayment(loan.id, p)}
                                  className="p-1 rounded hover:bg-danger/10 text-danger/70">
                            <Trash2 size={13} />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function RepayForm({
  loan, onClose, onSaved,
}: {
  loan: Loan;
  onClose: () => void;
  onSaved: () => void;
}) {
  const balance = parseFloat(loan.balance) || 0;
  const [amount, setAmount] = useState(balance);
  const [payDate, setPayDate] = useState('');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function save() {
    if (!amount || amount <= 0) {
      toast.error("Summa 0 dan katta bo'lishi kerak");
      return;
    }
    if (amount > balance) {
      toast.error('Summa qoldiqdan oshib ketdi');
      return;
    }
    setSaving(true);
    try {
      await api.post(`/hr/employee-loans/${loan.id}/payments`, {
        amount,
        pay_date: payDate || null,
        note: note || null,
      });
      toast.success("So'ndirildi");
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-[2px] p-4" onClick={onClose}>
      <div className="bg-card rounded-xl shadow-2xl w-full max-w-sm flex flex-col overflow-hidden" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold">So'ndirish</h3>
          <button onClick={onClose} className="p-2 rounded-lg text-ink/40 hover:text-ink hover:bg-black/5">
            <X size={18} />
          </button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <div className="text-sm text-ink-soft">
            Qoldiq:{' '}
            <span className="font-semibold text-danger tabular-nums">{formatUZS(balance)}</span>
          </div>
          <div>
            <label className="label">So'ndirish summasi</label>
            <MoneyInput value={amount} onChange={setAmount} suffix="so'm" autoFocus />
          </div>
          <div>
            <label className="label">Sana</label>
            <DateInput value={payDate} onChange={setPayDate} />
          </div>
          <div>
            <label className="label">Izoh</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)}
                   placeholder="Ixtiyoriy izoh" />
          </div>
        </div>

        <div className="px-5 py-4 border-t border-black/5 flex justify-end gap-2 bg-black/[0.015]">
          <button onClick={onClose} className="px-4 py-2 text-sm font-medium rounded-button border border-black/10 text-ink/70 hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={save} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : "So'ndirish"}
          </button>
        </div>
      </div>
    </div>
  );
}

function LoanForm({
  loan, onClose, onSaved,
}: {
  loan: Loan | null;   // null => create
  onClose: () => void;
  onSaved: () => void;
}) {
  const isCreate = loan === null;

  const [employeeId, setEmployeeId] = useState(loan?.employee_id ?? '');
  const [amount, setAmount] = useState(loan ? parseFloat(loan.amount) || 0 : 0);
  const [source, setSource] = useState(loan?.source ?? 'firma');
  const [loanDate, setLoanDate] = useState(loan?.loan_date ?? '');
  const [note, setNote] = useState(loan?.note ?? '');
  const [saving, setSaving] = useState(false);

  const { data: empData } = useQuery<{ items: EmpOpt[] }>({
    queryKey: ['hr', 'employees', 'loan-picker'],
    queryFn: () => api.get('/hr/employees', { params: { page_size: 200, is_active: true } }).then((r) => r.data),
    enabled: isCreate,
  });
  const employees = empData?.items ?? [];

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function save() {
    if (isCreate && !employeeId) {
      toast.error('Xodimni tanlang');
      return;
    }
    if (!amount || amount <= 0) {
      toast.error("Summa 0 dan katta bo'lishi kerak");
      return;
    }
    setSaving(true);
    try {
      if (isCreate) {
        await api.post('/hr/employee-loans', {
          employee_id: employeeId, amount, source, loan_date: loanDate || null, note: note || null,
        });
        toast.success("Qo'shildi");
      } else {
        await api.patch(`/hr/employee-loans/${loan!.id}`, {
          amount, source, loan_date: loanDate || null, note: note || null,
        });
        toast.success('Yangilandi');
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  const sourceOptions = SOURCES.map((s) => ({
    value: s,
    label: sourceLabel(s),
  }));
  const empName = loan ? employees.find((e) => e.id === loan.employee_id)?.full_name : undefined;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-[2px] p-4" onClick={onClose}>
      <div className="bg-card rounded-xl shadow-2xl w-full max-w-md flex flex-col overflow-hidden" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold">
            {isCreate
              ? "Qarz qo'shish"
              : 'Qarzni tahrirlash'}
          </h3>
          <button onClick={onClose} className="p-2 rounded-lg text-ink/40 hover:text-ink hover:bg-black/5">
            <X size={18} />
          </button>
        </div>

        <div className="px-5 py-4 space-y-3">
          {isCreate ? (
            <div>
              <label className="label">Xodim</label>
              <Select
                value={employeeId}
                onChange={setEmployeeId}
                options={employees.map((e) => ({ value: e.id, label: e.full_name }))}
                placeholder="Xodimni tanlang"
              />
            </div>
          ) : empName ? (
            <div className="text-sm text-ink-soft">
              Xodim: <span className="font-medium text-ink">{empName}</span>
            </div>
          ) : null}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Asosiy</label>
              <MoneyInput value={amount} onChange={setAmount} suffix="so'm" autoFocus={!isCreate} />
            </div>
            <div>
              <label className="label">Manba</label>
              <Select value={source} onChange={setSource} options={sourceOptions} />
            </div>
          </div>

          <div>
            <label className="label">Sana</label>
            <DateInput value={loanDate} onChange={setLoanDate} />
          </div>

          <div>
            <label className="label">Izoh</label>
            <input className="input" value={note} onChange={(e) => setNote(e.target.value)}
                   placeholder="Ixtiyoriy izoh" />
          </div>
        </div>

        <div className="px-5 py-4 border-t border-black/5 flex justify-end gap-2 bg-black/[0.015]">
          <button onClick={onClose} className="px-4 py-2 text-sm font-medium rounded-button border border-black/10 text-ink/70 hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={save} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
