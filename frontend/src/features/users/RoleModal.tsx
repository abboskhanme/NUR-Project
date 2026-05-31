import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';
import { api } from '@/api/client';

export interface RoleRow {
  id: string;
  name: string;
  description?: string | null;
  permissions?: Record<string, any>;
}

export default function RoleModal({
  role, onClose, onSaved,
}: {
  role: RoleRow | null; // null => create
  onClose: () => void;
  onSaved: () => void;
}) {
  const isCreate = role === null;
  const [name, setName] = useState(role?.name ?? '');
  const [description, setDescription] = useState(role?.description ?? '');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function save() {
    if (name.trim().length < 2) {
      toast.error("Nom kamida 2 ta belgi bo'lishi kerak");
      return;
    }
    setSaving(true);
    try {
      if (isCreate) {
        await api.post('/users/roles', {
          name: name.trim(),
          description: description.trim() || null,
        });
        toast.success('Rol yaratildi');
      } else {
        await api.patch(`/users/roles/${role!.id}`, {
          name: name.trim(),
          description: description.trim() || null,
        });
        toast.success('Yangilandi');
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-md"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5">
          <h3 className="font-semibold">{isCreate ? 'Yangi rol' : 'Rolni tahrirlash'}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5">
            <X size={18} />
          </button>
        </div>

        <div className="p-5 space-y-3">
          <div>
            <label className="label">Nomi *</label>
            <input
              className="input"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="masalan: warehouse_manager"
              disabled={!isCreate && role?.name === 'super_admin'}
            />
            <p className="text-xs text-ink-soft mt-1">
              Lotin harflari, raqam va pastki chiziq (snake_case) tavsiya etiladi.
            </p>
          </div>
          <div>
            <label className="label">Tavsif</label>
            <input
              className="input"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Foydalanuvchilarga ko'rinadigan tushuntirish"
            />
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
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
