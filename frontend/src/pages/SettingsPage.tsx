import { useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import PhoneInput from '@/components/ui/PhoneInput';
import { useAuthStore } from '@/stores/auth';
import AvatarUploader from '@/features/users/AvatarUploader';
import PinSettingsCard from '@/features/security/PinSettingsCard';

export default function SettingsPage() {
  const user = useAuthStore((s) => s.user);
  const setUser = useAuthStore((s) => s.setUser);
  const setTokens = useAuthStore((s) => s.setTokens);

  const origFullName = user?.full_name ?? '';
  const origPhone = user?.phone ?? '';

  const [fullName, setFullName] = useState(origFullName);
  const [phone, setPhone] = useState(origPhone);
  const [oldPwd, setOldPwd] = useState('');
  const [newPwd, setNewPwd] = useState('');

  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPwd, setSavingPwd] = useState(false);

  const profileChanged = useMemo(
    () =>
      fullName.trim() !== origFullName.trim() ||
      (phone ?? '').trim() !== (origPhone ?? '').trim(),
    [fullName, phone, origFullName, origPhone],
  );

  const passwordReady = oldPwd.length > 0 && newPwd.length >= 8;

  async function saveProfile() {
    if (!profileChanged) return;
    if (!phone.trim()) {
      toast.error("Login telefon raqami bo'sh bo'lishi mumkin emas");
      return;
    }
    setSavingProfile(true);
    try {
      const { data } = await api.patch('/auth/me', { full_name: fullName, phone });
      setUser(data);
      toast.success('Profil yangilandi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSavingProfile(false);
    }
  }

  async function changePassword() {
    if (!passwordReady) return;
    setSavingPwd(true);
    try {
      const { data } = await api.patch('/auth/me/password', {
        old_password: oldPwd,
        new_password: newPwd,
      });
      if (data?.access_token && data?.refresh_token) {
        setTokens(data.access_token, data.refresh_token);
      }
      toast.success('Parol yangilandi');
      setOldPwd('');
      setNewPwd('');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setSavingPwd(false);
    }
  }

  return (
    <div className="space-y-4 max-w-3xl">
      <h1 className="text-2xl font-bold">Sozlamalar</h1>

      <Card title="Profil rasmi">
        {user && (
          <AvatarUploader
            user={user}
            size={96}
            endpoint="/auth/me/avatar"
            onChanged={(updated) => {
              if (updated && updated.id) setUser(updated);
              else setUser({ ...user, avatar_url: null });
            }}
          />
        )}
      </Card>

      <Card title="Profil">
        <div className="space-y-3">
          <div>
            <label className="label">Telefon raqam (login)</label>
            <PhoneInput value={phone} onChange={setPhone} defaultCountry="UZ" />
            <p className="mt-1 text-xs text-ink-soft">
              Bu raqam tizimga kirish uchun ishlatiladi.
            </p>
          </div>
          <div>
            <label className="label">To'liq ism</label>
            <input
              className="input"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
            />
          </div>
          <button
            className="btn-primary disabled:opacity-40 disabled:cursor-not-allowed"
            onClick={saveProfile}
            disabled={!profileChanged || savingProfile}
          >
            {savingProfile ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
        </div>
      </Card>

      <Card title="Parolni o'zgartirish">
        <div className="space-y-3">
          <div>
            <label className="label">Eski parol</label>
            <input
              type="password"
              className="input"
              value={oldPwd}
              onChange={(e) => setOldPwd(e.target.value)}
              autoComplete="current-password"
            />
          </div>
          <div>
            <label className="label">Yangi parol</label>
            <input
              type="password"
              className="input"
              value={newPwd}
              onChange={(e) => setNewPwd(e.target.value)}
              placeholder="kamida 8 ta belgi"
              autoComplete="new-password"
            />
          </div>
          <button
            className="btn-primary disabled:opacity-40 disabled:cursor-not-allowed"
            onClick={changePassword}
            disabled={!passwordReady || savingPwd}
          >
            {savingPwd ? 'Yangilanmoqda...' : "O'zgartirish"}
          </button>
        </div>
      </Card>

      <PinSettingsCard />
    </div>
  );
}
