import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Search, Pencil, Trash2, Archive, PackageSearch } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatMoney } from '@/lib/format';
import { cn } from '@/lib/cn';
import MaterialModal from '@/features/costing/MaterialModal';
import type { MaterialOption } from '@/features/costing/types';
import { UNIT_LABEL } from '@/features/costing/types';

/**
 * Tannarx modulining O'Z material ro'yxati — ta'minotdan mustaqil.
 * Bu yerda material nomi, birligi, narxi va kiritish usuli (miqdor/summa)
 * belgilanadi; kalkulyatsiyalar shu ro'yxatdan foydalanadi.
 */
export default function MaterialsTab({ canWrite, canDelete }: {
  canWrite: boolean;
  canDelete: boolean;
}) {
  const [search, setSearch] = useState('');
  const [showArchived, setShowArchived] = useState(false);
  const [edit, setEdit] = useState<MaterialOption | null | undefined>(undefined);
  const [del, setDel] = useState<MaterialOption | null>(null);
  const [deleting, setDeleting] = useState(false);

  const q = useQuery<MaterialOption[]>({
    queryKey: ['costing-materials', search, showArchived],
    queryFn: () => api.get('/costing/materials', {
      params: {
        search: search.trim() || undefined,
        include_inactive: showArchived || undefined,
      },
    }).then((r) => r.data),
  });
  const materials = q.data ?? [];

  async function confirmDelete() {
    if (!del) return;
    setDeleting(true);
    try {
      await api.delete(`/costing/materials/${del.id}`);
      toast.success("O'chirildi");
      setDel(null);
      q.refetch();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <label className="flex items-center gap-1.5 text-xs sm:text-sm text-ink-soft cursor-pointer select-none">
          <input type="checkbox" checked={showArchived}
                 onChange={(e) => setShowArchived(e.target.checked)} />
          Arxivlanganlar ham
        </label>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <div className="relative flex-1 sm:flex-none">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 w-full sm:w-56" placeholder="Qidirish..."
                   value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
          {canWrite && (
            <button className="btn-primary shrink-0" onClick={() => setEdit(null)}>
              <Plus size={16} /> Material
            </button>
          )}
        </div>
      </div>

      <Card>
        {q.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : materials.length === 0 ? (
          <EmptyState
            title="Material yo'q"
            description={canWrite
              ? "«Material» tugmasi orqali birinchisini qo'shing — nom, birlik va narx yetarli"
              : 'Hozircha bo\'sh'}
          />
        ) : (
          <div className="divide-y divide-black/5">
            {materials.map((m) => (
              <div key={m.id}
                   className={cn('flex flex-wrap items-center gap-x-3 gap-y-2 py-3 -mx-2 px-2 rounded-button transition',
                     m.is_active ? 'hover:bg-black/[0.02]' : 'opacity-60 bg-black/[0.02]')}>
                <div className="min-w-0 basis-full sm:basis-0 sm:flex-1">
                  <div className="font-medium flex items-center gap-1.5 truncate">
                    <span className="truncate">{m.name}</span>
                    {!m.is_active && (
                      <span className="badge bg-black/5 text-ink-soft shrink-0">arxiv</span>
                    )}
                  </div>
                  <div className="text-xs text-ink-soft truncate">
                    {formatMoney(m.unit_price, m.currency)
                      + (m.unit ? ` / ${UNIT_LABEL[m.unit] ?? m.unit}` : '')}
                  </div>
                </div>
                <div className="text-right shrink-0 ml-auto sm:ml-0 sm:w-[120px]">
                  <div className={cn('font-semibold', m.used_in > 0 ? 'text-ink' : 'text-ink-soft')}>
                    {m.used_in > 0 ? `${m.used_in} mahsulot` : '—'}
                  </div>
                  <div className="text-[11px] text-ink-soft">ishlatilgan</div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  {canWrite && (
                    <button onClick={() => setEdit(m)} title="Tahrirlash"
                            className="p-2 rounded-button text-ink-soft hover:bg-black/5 hover:text-primary transition">
                      <Pencil size={15} />
                    </button>
                  )}
                  {canDelete && (
                    <button onClick={() => setDel(m)}
                            title={m.used_in > 0 ? 'Ishlatilgan — arxivlash tavsiya etiladi' : "O'chirish"}
                            className="p-2 rounded-button text-ink-soft hover:bg-danger/10 hover:text-danger transition">
                      {m.used_in > 0 ? <Archive size={15} /> : <Trash2 size={15} />}
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
        {!q.isLoading && materials.length > 0 && (
          <p className="text-[11px] text-ink-soft mt-3 flex items-start gap-1.5">
            <PackageSearch size={13} className="shrink-0 mt-0.5" />
            Bu ro'yxat faqat tannarx uchun — Ta'minot bo'limi bilan bog'liq emas. Narxni
            o'zgartirsangiz, shu materialni ishlatgan barcha mahsulotlar tannarxi o'zi yangilanadi.
          </p>
        )}
      </Card>

      {edit !== undefined && (
        <MaterialModal material={edit} onClose={() => setEdit(undefined)}
                       onSaved={() => q.refetch()} />
      )}
      <ConfirmModal
        open={!!del}
        title={del?.name ?? ''}
        message={del && del.used_in > 0
          ? `Bu material ${del.used_in} ta mahsulot kalkulyatsiyasida ishlatilgan — o'chirib bo'lmaydi. Tahrirlash orqali «faol emas» qilib arxivlang.`
          : "Material o'chiriladi. Davom etamizmi?"}
        confirmText="O'chirish"
        loading={deleting}
        onConfirm={confirmDelete}
        onCancel={() => setDel(null)}
      />
    </div>
  );
}
