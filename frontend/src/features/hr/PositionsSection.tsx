import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Trash2, Briefcase, Pencil, Check, X } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';

interface Position {
  id: string;
  name: string;
}

export default function PositionsSection() {
  const qc = useQueryClient();
  const [name, setName] = useState('');
  const [adding, setAdding] = useState(false);
  const [toDelete, setToDelete] = useState<Position | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [editName, setEditName] = useState('');
  const [savingEdit, setSavingEdit] = useState(false);

  const { data, isLoading } = useQuery<Position[]>({
    queryKey: ['hr', 'positions'],
    queryFn: () => api.get('/hr/positions').then((r) => r.data),
  });
  const positions = data ?? [];

  async function handleAdd() {
    if (!name.trim()) return;
    setAdding(true);
    try {
      await api.post('/hr/positions', { name: name.trim() });
      toast.success("Lavozim qo'shildi");
      setName('');
      qc.invalidateQueries({ queryKey: ['hr', 'positions'] });
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setAdding(false);
    }
  }

  function startEdit(p: Position) {
    setEditId(p.id);
    setEditName(p.name);
  }

  function cancelEdit() {
    setEditId(null);
    setEditName('');
  }

  async function handleEditSave() {
    if (!editId || !editName.trim()) return;
    setSavingEdit(true);
    try {
      await api.patch(`/hr/positions/${editId}`, { name: editName.trim() });
      toast.success('Lavozim yangilandi');
      qc.invalidateQueries({ queryKey: ['hr', 'positions'] });
      qc.invalidateQueries({ queryKey: ['employees'] });
      cancelEdit();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSavingEdit(false);
    }
  }

  async function handleDelete() {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/hr/positions/${toDelete.id}`);
      toast.success("Lavozim o'chirildi");
      qc.invalidateQueries({ queryKey: ['hr', 'positions'] });
      setToDelete(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setDeleting(false);
    }
  }

  return (
    <Card>
      <div className="flex items-end gap-2 mb-4">
        <div className="flex-1">
          <label className="label">Yangi lavozim nomi</label>
          <input
            className="input"
            value={name}
            placeholder="Masalan: Sotuv menejeri"
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
          />
        </div>
        <button onClick={handleAdd} disabled={adding || !name.trim()} className="btn-primary disabled:opacity-50">
          <Plus size={16} /> Qo'shish
        </button>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-11 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : positions.length === 0 ? (
        <EmptyState title="Lavozimlar yo'q" description="Birinchi lavozimni yuqorida qo'shing." />
      ) : (
        <div className="border border-black/10 rounded-button divide-y divide-black/5">
          {positions.map((p) => (
            <div key={p.id} className="flex items-center justify-between px-3 py-2.5 gap-2">
              {editId === p.id ? (
                <>
                  <input
                    className="input flex-1"
                    autoFocus
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') handleEditSave();
                      if (e.key === 'Escape') cancelEdit();
                    }}
                  />
                  <div className="flex items-center gap-1 shrink-0">
                    <button
                      onClick={handleEditSave}
                      disabled={savingEdit || !editName.trim()}
                      className="p-1.5 rounded hover:bg-success/10 text-success disabled:opacity-40"
                      title="Saqlash"
                    >
                      <Check size={16} />
                    </button>
                    <button
                      onClick={cancelEdit}
                      className="p-1.5 rounded hover:bg-black/5 text-ink/60"
                      title="Bekor qilish"
                    >
                      <X size={16} />
                    </button>
                  </div>
                </>
              ) : (
                <>
                  <div className="flex items-center gap-2 text-sm">
                    <Briefcase size={15} className="text-ink/40" />
                    {p.name}
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <button
                      onClick={() => startEdit(p)}
                      className="p-1.5 rounded hover:bg-black/5 text-ink/60"
                      title="Tahrirlash"
                    >
                      <Pencil size={15} />
                    </button>
                    <button
                      onClick={() => setToDelete(p)}
                      className="p-1.5 rounded hover:bg-danger/10 text-danger"
                      title="O'chirish"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </>
              )}
            </div>
          ))}
        </div>
      )}

      <ConfirmModal
        open={!!toDelete}
        title="Lavozimni o'chirish"
        message={`${toDelete?.name ?? ''} lavozimini o'chirasizmi? Bu lavozimga biriktirilgan xodimlarda lavozim bo'sh qoladi.`}
        confirmText="Ha, o'chirish"
        variant="danger"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => !deleting && setToDelete(null)}
      />
    </Card>
  );
}
