import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { Search, Undo2, Trash2, Archive as ArchiveIcon } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import UserAvatar from './UserAvatar';
import { UserRow } from './UserModal';

export default function ArchiveSection() {
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [restoreUser, setRestoreUser] = useState<UserRow | null>(null);
  const [purgeUser, setPurgeUser] = useState<UserRow | null>(null);
  const [busy, setBusy] = useState(false);

  const archivedQ = useQuery({
    queryKey: ['users', 'archive', search],
    queryFn: () =>
      api
        .get('/users', { params: { q: search || undefined, is_active: false, page_size: 100 } })
        .then((r) => r.data),
  });

  const items: UserRow[] = archivedQ.data?.items ?? [];

  async function doRestore() {
    if (!restoreUser) return;
    setBusy(true);
    try {
      await api.post(`/users/${restoreUser.id}/restore`);
      toast.success("Foydalanuvchi tiklandi");
      qc.invalidateQueries({ queryKey: ['users'] });
      setRestoreUser(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setBusy(false);
    }
  }

  async function doPurge() {
    if (!purgeUser) return;
    setBusy(true);
    try {
      await api.delete(`/users/${purgeUser.id}/permanent`);
      toast.success("Butunlay o'chirildi");
      qc.invalidateQueries({ queryKey: ['users'] });
      setPurgeUser(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setBusy(false);
    }
  }

  return (
    <Card>
      <div className="flex items-center justify-between mb-4 gap-2 flex-wrap">
        <div className="flex items-center gap-2 text-sm text-ink-soft">
          <ArchiveIcon size={16} />
          <span>Nofaol qilingan foydalanuvchilar. Tiklash yoki butunlay o'chirish mumkin.</span>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-4 bg-white border border-black/10 rounded-button px-3 py-1.5">
        <Search size={16} className="text-ink/40" />
        <input
          placeholder="Telefon yoki ism bo'yicha qidirish..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="bg-transparent outline-none flex-1 text-sm"
        />
      </div>

      {archivedQ.isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <EmptyState
          title="Arxiv bo'sh"
          description="Bu yerda nofaol qilingan foydalanuvchilar ko'rinadi."
        />
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-ink-soft border-b border-black/5">
              <tr>
                <th className="py-2 pr-3">Foydalanuvchi</th>
                <th className="py-2 pr-3">Telefon (login)</th>
                <th className="py-2 pr-3">Lavozim</th>
                <th className="py-2 pr-3">Rollar</th>
                <th className="py-2 pr-3 text-right">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {items.map((u) => (
                <tr key={u.id} className="border-b border-black/5 hover:bg-black/5 opacity-80">
                  <td className="py-2 pr-3">
                    <div className="flex items-center gap-3">
                      <UserAvatar user={u} size={36} />
                      <div className="font-medium truncate max-w-[160px]">{u.full_name}</div>
                    </div>
                  </td>
                  <td className="py-2 pr-3 truncate max-w-[200px]">{u.phone || '—'}</td>
                  <td className="py-2 pr-3">{u.position || '—'}</td>
                  <td className="py-2 pr-3">
                    <div className="flex flex-wrap gap-1">
                      {u.roles?.map((r) => (
                        <span key={r.id} className="text-xs px-2 py-0.5 rounded-full bg-black/5 text-ink/60">
                          {r.name}
                        </span>
                      ))}
                    </div>
                  </td>
                  <td className="py-2 pr-3">
                    <div className="flex items-center justify-end gap-1">
                      <button
                        title="Tiklash"
                        onClick={() => setRestoreUser(u)}
                        className="p-1.5 rounded hover:bg-success/10 text-success"
                      >
                        <Undo2 size={16} />
                      </button>
                      <button
                        title="Butunlay o'chirish"
                        onClick={() => setPurgeUser(u)}
                        className="p-1.5 rounded hover:bg-danger/10 text-danger"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <ConfirmModal
        open={!!restoreUser}
        title="Foydalanuvchini tiklash"
        message={
          <>
            <span className="font-medium">{restoreUser?.full_name}</span> ({restoreUser?.phone})
            ni qayta aktivlashtirishni tasdiqlaysizmi? Foydalanuvchi yana tizimga kira oladi.
          </>
        }
        confirmText="Ha, tiklash"
        variant="primary"
        loading={busy}
        onConfirm={doRestore}
        onCancel={() => !busy && setRestoreUser(null)}
      />

      <ConfirmModal
        open={!!purgeUser}
        title="Butunlay o'chirish"
        message={
          <>
            <span className="font-medium">{purgeUser?.full_name}</span> ({purgeUser?.phone})
            ni butunlay o'chirib tashlashni tasdiqlaysizmi?<br />
            <span className="text-danger font-medium">Bu amalni qaytarib bo'lmaydi!</span> Avatar, rol biriktirmalari ham o'chiriladi.
          </>
        }
        confirmText="Ha, butunlay o'chirish"
        variant="danger"
        loading={busy}
        onConfirm={doPurge}
        onCancel={() => !busy && setPurgeUser(null)}
      />
    </Card>
  );
}
