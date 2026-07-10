import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Trash2, PiggyBank } from 'lucide-react';

import { api } from '@/api/client';
import { formatMoney, formatDateTime } from '@/lib/format';
import ConfirmModal from '@/components/ui/ConfirmModal';
import type { Target } from '@/features/targets/TargetModal';
import TargetProgress, { targetTone } from '@/features/targets/TargetProgress';

interface Contribution {
  id: string;
  amount: number;
  currency: string;
  note?: string | null;
  created_at: string;
}

/** Bitta maqsadga qo'shilgan summalar tarixi. */
export default function TargetHistoryModal({
  target, onClose, onChanged, canDelete,
}: { target: Target; onClose: () => void; onChanged: () => void; canDelete: boolean }) {
  const [delId, setDelId] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const listQ = useQuery<Contribution[]>({
    queryKey: ['target-contributions', target.id],
    queryFn: () => api.get(`/targets/${target.id}/contributions`).then((r) => r.data),
  });
  const items = listQ.data ?? [];
  const tone = targetTone(target);

  async function confirmDelete() {
    if (!delId) return;
    setDeleting(true);
    try {
      await api.delete(`/targets/contributions/${delId}`);
      toast.success("O'chirildi");
      setDelId(null);
      listQ.refetch();
      onChanged();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card z-10">
          <div>
            <h3 className="font-semibold">{target.name}</h3>
            <p className="text-xs text-ink-soft">Qo'shilgan summalar</p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {/* Maqsad holati */}
        <div className="px-5 pt-4">
          <TargetProgress progress={target.progress} tone={tone} />
          <div className="flex justify-between text-xs text-ink-soft mt-1.5">
            <span>{Math.round(target.progress)}%</span>
            <span>{formatMoney(target.target_amount, target.currency)}</span>
          </div>
          <div className="grid grid-cols-2 gap-3 mt-3 text-sm">
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">Yig'ilgan</span>
              <span className="font-medium text-success">
                {formatMoney(target.saved_amount, target.currency)}
              </span>
            </div>
            <div className="rounded-button bg-black/[0.03] px-3 py-2 flex justify-between">
              <span className="text-ink-soft">Qolgan</span>
              <span className="font-medium">{formatMoney(target.remaining, target.currency)}</span>
            </div>
          </div>
        </div>

        <div className="p-5">
          {listQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : items.length === 0 ? (
            <div className="text-sm text-ink-soft text-center py-8">Hali summa qo'shilmagan</div>
          ) : (
            <div className="divide-y divide-black/5 border border-black/10 rounded-button overflow-hidden">
              {items.map((c) => (
                <div key={c.id} className="flex items-center gap-3 px-3 py-2.5 group">
                  <div className="w-8 h-8 rounded-button flex items-center justify-center shrink-0 bg-success/10 text-success">
                    <PiggyBank size={15} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-medium">Summa qo'shildi</div>
                    <div className="text-xs text-ink-soft">
                      {formatDateTime(c.created_at)}{c.note ? ` · ${c.note}` : ''}
                    </div>
                  </div>
                  <div className="text-sm font-bold shrink-0 text-success">
                    +{formatMoney(c.amount, c.currency)}
                  </div>
                  {canDelete && (
                    <button onClick={() => setDelId(c.id)}
                            className="p-1.5 rounded hover:bg-danger/10 text-ink-soft hover:text-danger opacity-0 group-hover:opacity-100 transition">
                      <Trash2 size={15} />
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <ConfirmModal
        open={!!delId}
        title="Qo'shilgan summa"
        message="Ushbu yozuvni o'chirasizmi? Maqsadga yig'ilgan summa shu miqdorga kamayadi."
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setDelId(null)}
      />
    </div>
  );
}
