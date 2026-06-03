import { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Plus, Trash2, Tag } from 'lucide-react';

import { api } from '@/api/client';

interface Category { id: string; name: string }

export default function ServiceCategoryModal({ onClose }: { onClose: () => void }) {
  const qc = useQueryClient();
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);

  const catsQ = useQuery<Category[]>({
    queryKey: ['service-categories'],
    queryFn: () => api.get('/service/categories').then((r) => r.data),
  });
  const cats = catsQ.data ?? [];

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function add() {
    const n = name.trim();
    if (!n) return;
    setBusy(true);
    try {
      await api.post('/service/categories', { name: n });
      setName('');
      await qc.invalidateQueries({ queryKey: ['service-categories'] });
      toast.success('Toifa qo\'shildi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setBusy(false);
    }
  }

  async function remove(id: string) {
    setBusy(true);
    try {
      await api.delete(`/service/categories/${id}`);
      await qc.invalidateQueries({ queryKey: ['service-categories'] });
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold flex items-center gap-2"><Tag size={16} /> Servis toifalari</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          <p className="text-sm text-ink-soft">
            Bu yerga tez-tez uchraydigan muammo / xizmat turlarini qo'shing — ariza yaratishda ro'yxatdan tanlanadi.
          </p>

          <div className="flex gap-2">
            <input className="input flex-1" placeholder="Yangi toifa nomi…" value={name}
                   onChange={(e) => setName(e.target.value)}
                   onKeyDown={(e) => e.key === 'Enter' && add()} />
            <button disabled={busy} onClick={add} className="btn-primary px-3 disabled:opacity-50">
              <Plus size={16} /> Qo'shish
            </button>
          </div>

          <div className="space-y-1.5">
            {catsQ.isLoading ? (
              Array.from({ length: 4 }).map((_, i) => <div key={i} className="h-9 rounded-button bg-black/5 animate-pulse" />)
            ) : cats.length === 0 ? (
              <div className="text-sm text-ink-soft text-center py-4">Hozircha toifa yo'q.</div>
            ) : (
              cats.map((c) => (
                <div key={c.id} className="flex items-center justify-between px-3 py-2 rounded-button bg-black/[0.03]">
                  <span className="text-sm">{c.name}</span>
                  <button disabled={busy} onClick={() => remove(c.id)}
                    className="p-1 rounded hover:bg-danger/10 text-danger disabled:opacity-50" title="O'chirish">
                    <Trash2 size={15} />
                  </button>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end">
          <button onClick={onClose} className="btn-primary">Tayyor</button>
        </div>
      </div>
    </div>
  );
}
