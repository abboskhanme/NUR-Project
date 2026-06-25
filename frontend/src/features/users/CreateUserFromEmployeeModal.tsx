import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, UserPlus, RefreshCw, Eye, EyeOff, Check, Search } from 'lucide-react';

import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';

interface Role {
  id: string;
  name: string;
  description?: string | null;
}

interface LinkableEmployee {
  id: string;
  full_name: string;
  phone?: string | null;
  position?: string | null;
}

/**
 * Mavjud HR xodimini sayt foydalanuvchisiga aylantirish.
 * Xodim tanlanadi → ism/telefon/lavozim oldindan to'ldiriladi → parol + rol → yaratiladi.
 * Backend yangi User yaratib MAVJUD xodimga bog'laydi (dublikat yaratmaydi).
 */
export default function CreateUserFromEmployeeModal({
  roles,
  onClose,
  onSaved,
}: {
  roles: Role[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [empId, setEmpId] = useState('');
  const [search, setSearch] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [position, setPosition] = useState('');
  const [password, setPassword] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  const { data, isLoading } = useQuery<LinkableEmployee[]>({
    queryKey: ['linkable-employees'],
    queryFn: () => api.get('/users/linkable-employees').then((r) => r.data),
  });
  const employees = useMemo(() => data ?? [], [data]);

  const filtered = useMemo(() => {
    const s = search.trim().toLowerCase();
    if (!s) return employees;
    return employees.filter(
      (e) => e.full_name.toLowerCase().includes(s) || (e.phone ?? '').toLowerCase().includes(s),
    );
  }, [employees, search]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  function pickEmployee(e: LinkableEmployee) {
    setEmpId(e.id);
    setFullName(e.full_name ?? '');
    setPhone(e.phone ?? '');
    setPosition(e.position ?? '');
  }

  function toggleRole(name: string) {
    setSelectedRoles((prev) =>
      prev.includes(name) ? prev.filter((r) => r !== name) : [...prev, name],
    );
  }

  function generatePwd() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%';
    let out = '';
    for (let i = 0; i < 12; i++) out += chars[Math.floor(Math.random() * chars.length)];
    setPassword(out);
    setShowPwd(true);
  }

  async function handleSave() {
    if (!empId) { toast.error('Avval xodimni tanlang'); return; }
    if (!phone || !fullName) { toast.error("Telefon raqam va to'liq ism majburiy"); return; }
    if (password.length < 8) { toast.error('Parol kamida 8 ta belgi bo\'lishi kerak'); return; }
    setSaving(true);
    try {
      await api.post(`/users/from-employee/${empId}`, {
        phone,
        password,
        full_name: fullName,
        position: position || null,
        role_names: selectedRoles,
      });
      toast.success("Foydalanuvchi yaratildi va xodimga bog'landi");
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-2xl max-h-[92vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold flex items-center gap-2">
            <UserPlus size={18} className="text-primary" /> Xodimdan foydalanuvchi yaratish
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* Xodim tanlash */}
          <div>
            <label className="label">Xodimni tanlang *</label>
            <div className="flex items-center gap-2 mb-2 bg-white border border-black/10 rounded-button px-3 py-1.5">
              <Search size={15} className="text-ink/40" />
              <input
                placeholder="Xodim qidirish (ism yoki telefon)..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="bg-transparent outline-none flex-1 text-sm"
              />
            </div>
            {isLoading ? (
              <div className="space-y-2">
                {Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
              </div>
            ) : employees.length === 0 ? (
              <p className="text-sm text-ink-soft py-3 text-center">Akkauntsiz xodim yo'q. Hamma xodimlarda allaqachon foydalanuvchi bor.</p>
            ) : (
              <div className="border border-black/10 rounded-button divide-y divide-black/5 max-h-44 overflow-y-auto">
                {filtered.map((e) => (
                  <button
                    type="button"
                    key={e.id}
                    onClick={() => pickEmployee(e)}
                    className={
                      'w-full flex items-center gap-3 px-3 py-2 text-left hover:bg-black/5 transition-colors ' +
                      (empId === e.id ? 'bg-primary/5' : '')
                    }
                  >
                    <div className={
                      'w-4 h-4 rounded-full border flex items-center justify-center shrink-0 ' +
                      (empId === e.id ? 'bg-primary border-primary text-white' : 'border-black/20 bg-white')
                    }>
                      {empId === e.id && <Check size={11} strokeWidth={3} />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm truncate">{e.full_name}</div>
                      <div className="text-xs text-ink-soft truncate">
                        {[e.phone, e.position].filter(Boolean).join(' · ') || '—'}
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Forma — xodim tanlangach */}
          {empId && (
            <div className="space-y-3 pt-1 border-t border-black/5">
              <div>
                <label className="label">Telefon raqam (login) *</label>
                <PhoneInput value={phone} onChange={setPhone} />
              </div>
              <div>
                <label className="label">To'liq ism *</label>
                <input className="input" value={fullName} onChange={(e) => setFullName(e.target.value)} />
              </div>
              <div>
                <label className="label">Lavozim</label>
                <input className="input" value={position} onChange={(e) => setPosition(e.target.value)} />
              </div>
              <div>
                <label className="label">Boshlang'ich parol *</label>
                <div className="flex gap-2">
                  <div className="flex-1 relative">
                    <input
                      type={showPwd ? 'text' : 'password'}
                      className="input pr-10"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
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
                {password && showPwd && (
                  <p className="mt-2 text-xs text-warn">Parolni eslab qoling yoki nusxa oling — modal yopilgach ko'rinmaydi.</p>
                )}
              </div>

              {/* Roles */}
              <div className="pt-2 border-t border-black/5">
                <div className="flex items-center justify-between mb-2">
                  <label className="label !mb-0">Rollar</label>
                  <span className="text-xs text-ink-soft">
                    {`${selectedRoles.length} ta tanlangan`}
                  </span>
                </div>
                {roles.length === 0 ? (
                  <p className="text-sm text-ink-soft py-2">Rollar mavjud emas</p>
                ) : (
                  <div className="border border-black/10 rounded-button divide-y divide-black/5 max-h-48 overflow-y-auto">
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
                          <div className={
                            'w-4 h-4 mt-0.5 rounded border flex items-center justify-center shrink-0 ' +
                            (isSel ? 'bg-primary border-primary text-white' : 'border-black/20 bg-white')
                          }>
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
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving || !empId} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda...' : "Yaratish va bog'lash"}
          </button>
        </div>
      </div>
    </div>
  );
}
