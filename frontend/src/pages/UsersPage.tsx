import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import {
  Plus, Search, Pencil, Trash2, ShieldCheck, Users as UsersIcon, Archive,
} from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { usePermissions } from '@/lib/permissions';

import UserAvatar from '@/features/users/UserAvatar';
import UserModal, { UserRow } from '@/features/users/UserModal';
import RolesSection from '@/features/users/RolesSection';
import ArchiveSection from '@/features/users/ArchiveSection';

interface Role {
  id: string;
  name: string;
  description?: string | null;
}

type Tab = 'users' | 'roles' | 'archive';

export default function UsersPage() {
  const { user: me, canModule } = usePermissions();
  const isAdmin = canModule('users');
  const qc = useQueryClient();

  const [tab, setTab] = useState<Tab>('users');
  const [search, setSearch] = useState('');
  const [editUser, setEditUser] = useState<UserRow | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [deleteUser, setDeleteUser] = useState<UserRow | null>(null);
  const [deleting, setDeleting] = useState(false);

  // Faqat aktiv foydalanuvchilar
  const usersQ = useQuery({
    queryKey: ['users', 'active', search],
    queryFn: () =>
      api
        .get('/users', { params: { q: search || undefined, is_active: true, page_size: 100 } })
        .then((r) => r.data),
    enabled: isAdmin && tab === 'users',
  });

  const rolesQ = useQuery<Role[]>({
    queryKey: ['roles', 'all'],
    queryFn: () => api.get('/users/roles/all').then((r) => r.data),
    enabled: isAdmin,
  });

  const items: UserRow[] = usersQ.data?.items ?? [];
  const roles: Role[] = rolesQ.data ?? [];

  async function handleArchive() {
    if (!deleteUser) return;
    setDeleting(true);
    try {
      await api.delete(`/users/${deleteUser.id}`);
      toast.success("Foydalanuvchi arxivga ko'chirildi");
      qc.invalidateQueries({ queryKey: ['users'] });
      setDeleteUser(null);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setDeleting(false);
    }
  }

  if (!isAdmin) {
    return (
      <div className="p-8">
        <EmptyState title="Ruxsat yo'q" description="Bu sahifani ko'rish uchun ruxsatingiz yetarli emas." />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <ShieldCheck size={22} className="text-primary" />
            Foydalanuvchilar
          </h1>
          <p className="text-sm text-ink-soft">
            Akkountlar, rollar va arxivni boshqarish
          </p>
        </div>
        {tab === 'users' && (
          <button onClick={() => setShowCreate(true)} className="btn-primary">
            <Plus size={16} /> Yangi foydalanuvchi
          </button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5 overflow-x-auto">
        <TabButton active={tab === 'users'} onClick={() => setTab('users')} icon={<UsersIcon size={16} />}>
          Foydalanuvchilar
        </TabButton>
        <TabButton active={tab === 'roles'} onClick={() => setTab('roles')} icon={<ShieldCheck size={16} />}>
          Rollar
        </TabButton>
        <TabButton active={tab === 'archive'} onClick={() => setTab('archive')} icon={<Archive size={16} />}>
          Arxiv
        </TabButton>
      </div>

      {tab === 'users' && (
        <Card>
          <div className="flex items-center gap-2 mb-4 bg-white border border-black/10 rounded-button px-3 py-1.5">
            <Search size={16} className="text-ink/40" />
            <input
              placeholder="Telefon yoki ism bo'yicha qidirish..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-transparent outline-none flex-1 text-sm"
            />
          </div>

          {usersQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-14 rounded-button bg-black/5 animate-pulse" />
              ))}
            </div>
          ) : items.length === 0 ? (
            <EmptyState title="Foydalanuvchilar yo'q" />
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
                    <tr key={u.id} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3">
                        <div className="flex items-center gap-3">
                          <UserAvatar user={u} size={36} />
                          <div className="font-medium truncate max-w-[160px]">{u.full_name}</div>
                        </div>
                      </td>
                      <td className="py-2 pr-3">{u.phone || '—'}</td>
                      <td className="py-2 pr-3">{u.position || '—'}</td>
                      <td className="py-2 pr-3">
                        <div className="flex flex-wrap gap-1">
                          {u.is_superadmin && (
                            <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary">
                              super-admin
                            </span>
                          )}
                          {u.roles?.filter((r) => r.name !== 'super_admin').map((r) => (
                            <span
                              key={r.id}
                              className="text-xs px-2 py-0.5 rounded-full bg-black/5 text-ink/70"
                            >
                              {r.name}
                            </span>
                          ))}
                        </div>
                      </td>
                      <td className="py-2 pr-3">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            title="Tahrirlash"
                            onClick={() => setEditUser(u)}
                            className="p-1.5 rounded hover:bg-black/5 text-ink/60"
                          >
                            <Pencil size={16} />
                          </button>
                          <button
                            title={u.id === me?.id ? "O'zingizni arxivga ko'chira olmaysiz" : "Arxivga ko'chirish"}
                            onClick={() => u.id !== me?.id && setDeleteUser(u)}
                            disabled={u.id === me?.id}
                            className="p-1.5 rounded hover:bg-danger/10 text-danger disabled:opacity-30 disabled:cursor-not-allowed"
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
        </Card>
      )}

      {tab === 'roles' && <RolesSection />}
      {tab === 'archive' && <ArchiveSection />}

      {(showCreate || editUser) && (
        <UserModal
          user={editUser}
          roles={roles}
          onClose={() => {
            setShowCreate(false);
            setEditUser(null);
          }}
          onSaved={() => qc.invalidateQueries({ queryKey: ['users'] })}
        />
      )}

      <ConfirmModal
        open={!!deleteUser}
        title="Arxivga ko'chirish"
        message={
          <>
            <span className="font-medium">{deleteUser?.full_name}</span> ({deleteUser?.phone})
            ni arxivga ko'chirishni tasdiqlaysizmi? Foydalanuvchi nofaol qilinadi, ma'lumotlari saqlanadi. Arxivdan tiklash mumkin.
          </>
        }
        confirmText="Ha, arxivga ko'chirish"
        variant="danger"
        loading={deleting}
        onConfirm={handleArchive}
        onCancel={() => !deleting && setDeleteUser(null)}
      />
    </div>
  );
}

function TabButton({
  active, onClick, icon, children,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={
        'flex items-center gap-2 px-4 py-2 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ' +
        (active
          ? 'border-primary text-primary'
          : 'border-transparent text-ink/60 hover:text-ink')
      }
    >
      {icon}
      {children}
    </button>
  );
}
