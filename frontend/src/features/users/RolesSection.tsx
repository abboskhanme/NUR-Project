import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2, Shield } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import RoleModal, { RoleRow } from './RoleModal';
import { MODULES } from '@/lib/permissions';

/** Rol ruxsatlarining qisqa xulosasi */
function usePermSummary() {
  return function permSummary(r: RoleRow): string {
    if (r.name === 'super_admin') return "To'liq";
    const raw: any = r.permissions || {};
    const items: string[] = Array.isArray(raw) ? raw : raw.permissions ?? [];
    if (items.includes('*') || items.includes('*:*')) return "To'liq";
    const mods = new Set<string>();
    for (const p of items) {
      const m = String(p).split(':')[0];
      if (m === '*') return `${MODULES.length} modul`;
      if (m) mods.add(m);
    }
    return mods.size ? `${mods.size} modul` : '—';
  };
}

export default function RolesSection() {
  const qc = useQueryClient();
  const [editRole, setEditRole] = useState<RoleRow | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [deleteRole, setDeleteRole] = useState<RoleRow | null>(null);
  const [deleting, setDeleting] = useState(false);

  const rolesQ = useQuery<RoleRow[]>({
    queryKey: ['roles', 'all'],
    queryFn: () => api.get('/users/roles/all').then((r) => r.data),
  });

  const roles = rolesQ.data ?? [];
  const permSummary = usePermSummary();

  async function handleDelete() {
    if (!deleteRole) return;
    setDeleting(true);
    try {
      await api.delete(`/users/roles/${deleteRole.id}`);
      toast.success("Rol o'chirildi");
      qc.invalidateQueries({ queryKey: ['roles'] });
      qc.invalidateQueries({ queryKey: ['users'] });
      setDeleteRole(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-4">
      <Card
        title="Tizim rollari"
        action={
          <button onClick={() => setShowCreate(true)} className="btn-primary">
            <Plus size={16} /> Yangi rol
          </button>
        }
      >
        {rolesQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />
            ))}
          </div>
        ) : roles.length === 0 ? (
          <EmptyState title="Rollar yo'q" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">Nomi</th>
                  <th className="py-2 pr-3">Tavsif</th>
                  <th className="py-2 pr-3">Ruxsatlar</th>
                  <th className="py-2 pr-3 text-right">Amallar</th>
                </tr>
              </thead>
              <tbody>
                {roles.map((r) => {
                  const isCore = r.name === 'super_admin';
                  const summary = permSummary(r);
                  return (
                    <tr key={r.id} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3">
                        <div className="flex items-center gap-2">
                          <Shield size={14} className="text-primary/70" />
                          <span className="font-medium">{r.name}</span>
                          {isCore && (
                            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-primary/10 text-primary">
                              tizim
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="py-2 pr-3 text-ink/70">{r.description || '—'}</td>
                      <td className="py-2 pr-3">
                        <span
                          className={
                            'text-xs px-2 py-0.5 rounded-full ' +
                            (summary === "To'liq"
                              ? 'bg-success/10 text-success'
                              : summary === '—'
                                ? 'bg-black/5 text-ink/50'
                                : 'bg-primary/10 text-primary')
                          }
                        >
                          {summary}
                        </span>
                      </td>
                      <td className="py-2 pr-3">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            title="Tahrirlash"
                            onClick={() => setEditRole(r)}
                            className="p-1.5 rounded hover:bg-black/5 text-ink/60"
                          >
                            <Pencil size={16} />
                          </button>
                          <button
                            title={isCore ? "Tizim rolini o'chirib bo'lmaydi" : "O'chirish"}
                            onClick={() => !isCore && setDeleteRole(r)}
                            disabled={isCore}
                            className="p-1.5 rounded hover:bg-danger/10 text-danger disabled:opacity-30 disabled:cursor-not-allowed"
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {(showCreate || editRole) && (
        <RoleModal
          role={editRole}
          onClose={() => {
            setShowCreate(false);
            setEditRole(null);
          }}
          onSaved={() => qc.invalidateQueries({ queryKey: ['roles'] })}
        />
      )}

      <ConfirmModal
        open={!!deleteRole}
        title="Rolni o'chirish"
        message={
          <>
            <span className="font-medium">{deleteRole?.name}</span> rolini o'chirishni tasdiqlaysizmi? Bu rolga biriktirilgan foydalanuvchilardan rol olib tashlanadi.
          </>
        }
        confirmText="Ha, o'chirish"
        variant="danger"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => !deleting && setDeleteRole(null)}
      />
    </div>
  );
}
