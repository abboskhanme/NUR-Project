import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Search, Target as TargetIcon, Trophy, Coins, PiggyBank, Pencil, Trash2,
  CalendarClock, CheckCircle2, History,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatMoney } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import TargetModal, { type Target } from '@/features/targets/TargetModal';
import TargetContributeModal from '@/features/targets/TargetContributeModal';
import TargetHistoryModal from '@/features/targets/TargetHistoryModal';
import TargetProgress, { daysLeft, isOverdue, targetTone } from '@/features/targets/TargetProgress';

interface CurrencyTotal {
  currency: string;
  total_target: number;
  total_saved: number;
  total_remaining: number;
  target_count: number;
  completed_count: number;
}
interface Summary {
  by_currency: CurrencyTotal[];
  target_count: number;
}

type Status = 'all' | 'active' | 'completed';

const STATUS_TABS: Record<Status, string> = {
  all: 'Barchasi',
  active: 'Faol',
  completed: 'Bajarilgan',
};
const TARGETS_CURRENCY: Record<string, string> = {
  UZS: "so'm",
  USD: 'dollar',
};

export default function TargetsPage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const canWrite = can('targets:write');
  const canDelete = can('targets:delete');

  const [status, setStatus] = useState<Status>('all');
  const [search, setSearch] = useState('');

  // Modal holatlari
  const [editTarget, setEditTarget] = useState<Target | null | undefined>(undefined);
  const [contribute, setContribute] = useState<Target | null>(null);
  const [detail, setDetail] = useState<Target | null>(null);
  const [delTarget, setDelTarget] = useState<Target | null>(null);
  const [deleting, setDeleting] = useState(false);

  const summaryQ = useQuery<Summary>({
    queryKey: ['targets-summary'],
    queryFn: () => api.get('/targets/summary').then((r) => r.data),
  });

  const targetsQ = useQuery<Target[]>({
    queryKey: ['targets', search, status],
    queryFn: () => api.get('/targets', {
      params: { search: search.trim() || undefined, status },
    }).then((r) => r.data),
  });
  const targets = targetsQ.data ?? [];
  const s = summaryQ.data;

  // Ochiq tarix modalini yangilangan ma'lumot bilan sinxronlash
  useEffect(() => {
    if (!detail) return;
    const fresh = targets.find((t) => t.id === detail.id);
    if (fresh && fresh !== detail) setDetail(fresh);
  }, [targets]); // eslint-disable-line react-hooks/exhaustive-deps

  const refetchAll = () => {
    targetsQ.refetch();
    summaryQ.refetch();
    qc.invalidateQueries({ queryKey: ['target-contributions'] });
  };

  async function confirmDelete() {
    if (!delTarget) return;
    setDeleting(true);
    try {
      await api.delete(`/targets/${delTarget.id}`);
      toast.success("O'chirildi");
      setDelTarget(null);
      refetchAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  const emptyTotals: CurrencyTotal[] = [{
    currency: 'UZS', total_target: 0, total_saved: 0, total_remaining: 0,
    target_count: 0, completed_count: 0,
  }];

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Maqsadlar</h1>
          <p className="text-sm text-ink-soft">Belgilangan summaga sekin-asta yig'ib borish</p>
        </div>
        {canWrite && (
          <button className="btn-primary" onClick={() => setEditTarget(null)}>
            <Plus size={16} /> Yangi maqsad
          </button>
        )}
      </div>

      {/* KPI Cards — har valyuta uchun: umumiy maqsad, yig'ilgan, qolgan */}
      <div className="space-y-3">
        {(s?.by_currency?.length ? s.by_currency : emptyTotals).map((c) => (
          <div key={c.currency}>
            {(s?.by_currency?.length ?? 0) > 1 && (
              <div className="text-xs font-medium text-ink-soft mb-1.5">
                {TARGETS_CURRENCY[c.currency] ?? c.currency}
              </div>
            )}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <KpiCard
                tone="primary"
                label="Umumiy maqsad"
                value={formatMoney(c.total_target, c.currency)}
                hint={`${c.target_count} ta maqsad`}
                icon={<TargetIcon size={18} />}
              />
              <KpiCard
                tone="success"
                label="Yig'ilgan"
                value={formatMoney(c.total_saved, c.currency)}
                hint={`${c.completed_count} ta bajarilgan`}
                icon={<PiggyBank size={18} />}
              />
              <KpiCard
                tone="warning"
                label="Qolgan"
                value={formatMoney(c.total_remaining, c.currency)}
                hint={c.total_target > 0
                  ? `${Math.round((c.total_saved / c.total_target) * 100)}% bajarildi`
                  : '—'}
                icon={<Coins size={18} />}
              />
            </div>
          </div>
        ))}
      </div>

      {/* Tabs + Search */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex gap-1.5">
          {(Object.keys(STATUS_TABS) as Status[]).map((key) => (
            <button key={key} onClick={() => setStatus(key)}
              className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                status === key ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
              {STATUS_TABS[key]}
            </button>
          ))}
        </div>
        <div className="relative">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
          <input className="input pl-9 w-56" placeholder="Qidirish..."
                 value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
      </div>

      {/* Content */}
      {targetsQ.isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="h-48 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : targets.length === 0 ? (
        <Card>
          <EmptyState
            title={search || status !== 'all' ? 'Maqsad topilmadi' : "Hali maqsad qo'shilmagan"}
            description={search || status !== 'all'
              ? 'Qidiruv yoki filtrni o\'zgartirib ko\'ring'
              : '"Yangi maqsad" tugmasi orqali birinchisini qo\'shing'}
          />
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {targets.map((t) => (
            <TargetCard
              key={t.id}
              target={t}
              canWrite={canWrite}
              canDelete={canDelete}
              onOpen={() => setDetail(t)}
              onContribute={() => setContribute(t)}
              onEdit={() => setEditTarget(t)}
              onDelete={() => setDelTarget(t)}
            />
          ))}
        </div>
      )}

      {/* Modals */}
      {editTarget !== undefined && (
        <TargetModal target={editTarget} onClose={() => setEditTarget(undefined)} onSaved={refetchAll} />
      )}
      {contribute && (
        <TargetContributeModal target={contribute} onClose={() => setContribute(null)} onSaved={refetchAll} />
      )}
      {detail && (
        <TargetHistoryModal target={detail} canDelete={canDelete}
                            onClose={() => setDetail(null)} onChanged={refetchAll} />
      )}
      <ConfirmModal
        open={!!delTarget}
        title={delTarget?.name ?? ''}
        message="Ushbu maqsad va unga qo'shilgan barcha summalar o'chiriladi. Davom etamizmi?"
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setDelTarget(null)}
      />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Maqsad kartasi
// ---------------------------------------------------------------------------
function TargetCard({
  target, canWrite, canDelete, onOpen, onContribute, onEdit, onDelete,
}: {
  target: Target;
  canWrite: boolean;
  canDelete: boolean;
  onOpen: () => void;
  onContribute: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const tone = targetTone(target);
  const done = target.is_completed;
  const overdue = isOverdue(target);
  const left = daysLeft(target);

  return (
    <div onClick={onOpen}
         className={`rounded-card border bg-card p-4 flex flex-col gap-3 cursor-pointer transition hover:shadow-md ${
           done ? 'border-success/30' : overdue ? 'border-danger/30' : 'border-black/5'}`}>
      {/* Sarlavha */}
      <div className="flex items-start gap-2">
        <div className={`w-9 h-9 rounded-button flex items-center justify-center shrink-0 ${
          done ? 'bg-success/15 text-success'
            : overdue ? 'bg-danger/15 text-danger' : 'bg-primary/10 text-primary'}`}>
          {done ? <Trophy size={17} /> : <TargetIcon size={17} />}
        </div>
        <div className="min-w-0 flex-1">
          <div className="font-semibold truncate">{target.name}</div>
          <div className="text-xs text-ink-soft truncate">
            {target.note || `${target.contribution_count} ta qo'shimcha`}
          </div>
        </div>
        <div className={`text-lg font-bold shrink-0 ${
          done ? 'text-success' : overdue ? 'text-danger' : 'text-primary'}`}>
          {Math.round(target.progress)}%
        </div>
      </div>

      {/* Progress */}
      <div>
        <TargetProgress progress={target.progress} tone={tone} />
        <div className="flex justify-between items-baseline mt-1.5">
          <span className="text-sm font-semibold text-success">
            {formatMoney(target.saved_amount, target.currency)}
          </span>
          <span className="text-xs text-ink-soft">
            {formatMoney(target.target_amount, target.currency)}
          </span>
        </div>
      </div>

      {/* Holat qatori: qolgan summa + muddat */}
      <div className="flex items-center justify-between gap-2 text-xs">
        {done ? (
          <span className="inline-flex items-center gap-1 badge bg-success/10 text-success font-medium">
            <CheckCircle2 size={13} /> Maqsadga erishildi
          </span>
        ) : (
          <span className="text-ink-soft">
            Qolgani: <span className="font-semibold text-ink">
              {formatMoney(target.remaining, target.currency)}
            </span>
          </span>
        )}
        {target.deadline && !done && (
          <span className={`inline-flex items-center gap-1 shrink-0 ${
            overdue ? 'text-danger font-medium' : 'text-ink-soft'}`}>
            <CalendarClock size={13} />
            {overdue
              ? `${Math.abs(left!)} kun kechikdi`
              : left === 0 ? 'Bugun oxirgi kun' : `${left} kun qoldi`}
          </span>
        )}
      </div>

      {/* Amallar */}
      <div className="flex items-center gap-1.5 pt-1" onClick={(e) => e.stopPropagation()}>
        {canWrite && !done && (
          <button onClick={onContribute}
                  className="flex-1 inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-button text-xs font-medium bg-primary/10 text-primary hover:bg-primary/20 transition">
            <PiggyBank size={14} /> Summa qo'shish
          </button>
        )}
        {canWrite && done && (
          <button onClick={onContribute}
                  className="flex-1 inline-flex items-center justify-center gap-1.5 px-3 py-2 rounded-button text-xs font-medium bg-success/10 text-success hover:bg-success/20 transition">
            <PiggyBank size={14} /> Yana qo'shish
          </button>
        )}
        <button onClick={onOpen} title="Tarix"
                className="p-2 rounded-button hover:bg-black/5 text-ink-soft hover:text-primary transition">
          <History size={15} />
        </button>
        {canWrite && (
          <button onClick={onEdit} title="Tahrirlash"
                  className="p-2 rounded-button hover:bg-black/5 text-ink-soft hover:text-primary transition">
            <Pencil size={15} />
          </button>
        )}
        {canDelete && (
          <button onClick={onDelete} title="O'chirish"
                  className="p-2 rounded-button hover:bg-danger/10 text-ink-soft hover:text-danger transition">
            <Trash2 size={15} />
          </button>
        )}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// KPI karta
// ---------------------------------------------------------------------------
const KPI_TONES = {
  primary: { card: 'border-primary/20 bg-primary/5', text: 'text-primary', icon: 'bg-primary/15 text-primary' },
  success: { card: 'border-success/25 bg-success/10', text: 'text-success', icon: 'bg-success/20 text-success' },
  warning: { card: 'border-warning/25 bg-warning/10', text: 'text-warning', icon: 'bg-warning/20 text-warning' },
} as const;

function KpiCard({ tone, label, value, hint, icon }: {
  tone: keyof typeof KPI_TONES;
  label: string;
  value: string;
  hint?: string;
  icon: React.ReactNode;
}) {
  const tn = KPI_TONES[tone];
  return (
    <div className={`rounded-card border p-4 flex items-start justify-between ${tn.card}`}>
      <div className="min-w-0">
        <div className={`text-sm font-medium ${tn.text}`}>{label}</div>
        <div className={`text-2xl font-bold mt-2 ${tn.text}`}>{value}</div>
        {hint && <div className="text-xs text-ink-soft mt-1">{hint}</div>}
      </div>
      <div className={`w-10 h-10 rounded-button flex items-center justify-center shrink-0 ${tn.icon}`}>
        {icon}
      </div>
    </div>
  );
}
