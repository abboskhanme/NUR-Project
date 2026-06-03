import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import {
  X, User as UserIcon, KeyRound, Eye, EyeOff, RefreshCw, Check,
} from 'lucide-react';
import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';
import AvatarUploader from './AvatarUploader';

export interface UserRow {
  id: string;
  phone: string;
  full_name: string;
  position?: string | null;
  avatar_url?: string | null;
  is_active: boolean;
  is_superadmin: boolean;
  roles: { id: string; name: string }[];
}

interface Role {
  id: string;
  name: string;
  description?: string | null;
}

type Tab = 'profile' | 'password';

export default function UserModal({
  user,
  roles,
  onClose,
  onSaved,
}: {
  user: UserRow | null;
  roles: Role[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const isCreate = user === null;
  const [tab, setTab] = useState<Tab>('profile');

  const [fullName, setFullName] = useState(user?.full_name ?? '');
  const [phone, setPhone] = useState(user?.phone ?? '');
  const [position, setPosition] = useState(user?.position ?? '');
  const [isActive, setIsActive] = useState(user?.is_active ?? true);
  const [selectedRoles, setSelectedRoles] = useState<string[]>(
    user?.roles?.map((r) => r.name) ?? [],
  );

  const [password, setPassword] = useState('');

  const [newPwd, setNewPwd] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  const [pwdLoading, setPwdLoading] = useState(false);

  const [localUser, setLocalUser] = useState<UserRow | null>(user);

  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  function toggleRole(name: string) {
    setSelectedRoles((prev) =>
      prev.includes(name) ? prev.filter((r) => r !== name) : [...prev, name],
    );
  }

  async function handleSave() {
    if (!phone || !fullName) {
      toast.error("Telefon raqam va to'liq ism majburiy");
      return;
    }
    if (isCreate && password.length < 8) {
      toast.error("Parol kamida 8 ta belgi bo'lishi kerak");
      return;
    }
    setSaving(true);
    try {
      if (isCreate) {
        await api.post('/users', {
          phone, password, full_name: fullName,
          position: position || null,
          role_names: selectedRoles,
        });
        toast.success('Foydalanuvchi yaratildi');
      } else {
        // is_superadmin endi yuborilmaydi — faqat super_admin roli orqali boshqariladi
        await api.patch(`/users/${user!.id}`, {
          phone, full_name: fullName,
          position: position || null,
          is_active: isActive,
          role_names: selectedRoles,
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

  async function resetPassword() {
    if (newPwd.length < 8) {
      toast.error("Kamida 8 ta belgi bo'lishi kerak");
      return;
    }
    setPwdLoading(true);
    try {
      await api.post(`/users/${user!.id}/password`, { new_password: newPwd });
      toast.success('Parol yangilandi. Foydalanuvchiga uzating.');
      setNewPwd('');
      setShowPwd(false);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik');
    } finally {
      setPwdLoading(false);
    }
  }

  function generatePwd() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%';
    let out = '';
    for (let i = 0; i < 12; i++) out += chars[Math.floor(Math.random() * chars.length)];
    setNewPwd(out);
    setShowPwd(true);
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-2xl max-h-[92vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">
            {isCreate ? 'Yangi foydalanuvchi' : `Foydalanuvchini tahrirlash — ${user?.full_name}`}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5">
            <X size={18} />
          </button>
        </div>

        {/* Tabs */}
        {!isCreate && (
          <div className="flex border-b border-black/5 shrink-0 bg-black/[0.02]">
            <TabBtn active={tab === 'profile'} onClick={() => setTab('profile')} icon={<UserIcon size={15} />}>
              Profil
            </TabBtn>
            <TabBtn active={tab === 'password'} onClick={() => setTab('password')} icon={<KeyRound size={15} />}>
              Parol
            </TabBtn>
          </div>
        )}

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5">
          {tab === 'profile' && (
            <div className="space-y-5">
              {!isCreate && localUser && (
                <div className="pb-4 border-b border-black/5">
                  <label className="label mb-2">Profil rasmi</label>
                  <AvatarUploader
                    user={localUser}
                    size={80}
                    endpoint={`/users/${user!.id}/avatar`}
                    onChanged={(u) => {
                      if (u && u.id) setLocalUser(u);
                      else setLocalUser({ ...localUser, avatar_url: null });
                      onSaved();
                    }}
                  />
                </div>
              )}

              <div className="space-y-3">
                <div>
                  <label className="label">Telefon raqam (login) *</label>
                  <PhoneInput value={phone} onChange={setPhone} />
                </div>
                <div>
                  <label className="label">To'liq ism *</label>
                  <input
                    className="input"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                  />
                </div>
                <div>
                  <label className="label">Lavozim</label>
                  <input
                    className="input"
                    value={position}
                    onChange={(e) => setPosition(e.target.value)}
                  />
                </div>

                {isCreate && (
                  <div>
                    <label className="label">Boshlang'ich parol *</label>
                    <input
                      type="password"
                      className="input"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="kamida 8 ta belgi"
                    />
                  </div>
                )}

                {!isCreate && (
                  <div className="pt-1">
                    <label className="flex items-center gap-2 text-sm cursor-pointer">
                      <input
                        type="checkbox"
                        className="w-4 h-4 accent-primary"
                        checked={isActive}
                        onChange={(e) => setIsActive(e.target.checked)}
                      />
                      Aktiv akkount
                    </label>
                  </div>
                )}
              </div>

              {/* Rollar */}
              <div className="pt-4 border-t border-black/5">
                <div className="flex items-center justify-between mb-2">
                  <label className="label !mb-0">Rollar</label>
                  <span className="text-xs text-ink-soft">
                    {selectedRoles.length} ta tanlangan
                  </span>
                </div>
                <p className="text-xs text-ink-soft mb-2">
                  Super-admin huquqi <span className="font-medium text-ink/70">super_admin</span> rolini berish orqali boshqariladi.
                </p>
                {roles.length === 0 ? (
                  <p className="text-sm text-ink-soft py-2">Rollar mavjud emas</p>
                ) : (
                  <div className="border border-black/10 rounded-button divide-y divide-black/5 max-h-64 overflow-y-auto">
                    {roles.map((r) => {
                      const isSel = selectedRoles.includes(r.name);
                      return (
                        <button
                          type="button"
                          key={r.id}
                          onClick={() => toggleRole(r.name)}
                          className={
                            'w-full flex items-start gap-3 px-3 py-2.5 text-left hover:bg-black/5 transition-colors ' +
                            (isSel ? 'bg-primary/5' : '')
                          }
                        >
                          <div
                            className={
                              'w-4 h-4 mt-0.5 rounded border flex items-center justify-center shrink-0 ' +
                              (isSel ? 'bg-primary border-primary text-white' : 'border-black/20 bg-white')
                            }
                          >
                            {isSel && <Check size={12} strokeWidth={3} />}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="font-medium text-sm">{r.name}</div>
                            {r.description && (
                              <div className="text-xs text-ink-soft truncate">{r.description}</div>
                            )}
                          </div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          )}

          {tab === 'password' && !isCreate && (
            <div className="space-y-3 max-w-md">
              <p className="text-sm text-ink-soft">
                Yangi parol qo'ying. Tasdiqlangach foydalanuvchiga og'zaki yoki Telegram orqali uzating.
              </p>
              <div>
                <label className="label">Yangi parol</label>
                <div className="flex gap-2">
                  <div className="flex-1 relative">
                    <input
                      type={showPwd ? 'text' : 'password'}
                      className="input pr-10"
                      value={newPwd}
                      onChange={(e) => setNewPwd(e.target.value)}
                      placeholder="kamida 8 ta belgi"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPwd((s) => !s)}
                      className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-ink/50 hover:text-ink"
                    >
                      {showPwd ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                  <button
                    type="button"
                    onClick={generatePwd}
                    className="px-3 rounded-button border border-black/10 hover:bg-black/5 text-sm flex items-center gap-1"
                    title="Tasodifiy 12-belgili parol"
                  >
                    <RefreshCw size={14} /> Generatsiya
                  </button>
                </div>
                {newPwd && showPwd && (
                  <p className="mt-2 text-xs text-warn">
                    Parolni eslab qoling yoki nusxa oling — modal yopilgach ko'rinmaydi.
                  </p>
                )}
              </div>
              <button
                onClick={resetPassword}
                disabled={pwdLoading || !newPwd}
                className="btn-primary disabled:opacity-50"
              >
                {pwdLoading ? 'Yangilanmoqda...' : "Parolni qo'yish"}
              </button>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          {tab === 'profile' && (
            <button
              onClick={handleSave}
              disabled={saving}
              className="btn-primary disabled:opacity-50"
            >
              {saving ? 'Saqlanmoqda...' : 'Saqlash'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function TabBtn({
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
        'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ' +
        (active
          ? 'border-primary text-primary bg-white'
          : 'border-transparent text-ink/60 hover:text-ink hover:bg-black/5')
      }
    >
      {icon}
      {children}
    </button>
  );
}
