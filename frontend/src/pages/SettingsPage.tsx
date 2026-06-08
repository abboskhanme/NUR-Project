import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import PhoneInput from '@/components/ui/PhoneInput';
import { useAuthStore } from '@/stores/auth';
import AvatarUploader from '@/features/users/AvatarUploader';

export default function SettingsPage() {
  const { t } = useTranslation();
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
      toast.error(t('settings.phoneRequired'));
      return;
    }
    setSavingProfile(true);
    try {
      const { data } = await api.patch('/auth/me', { full_name: fullName, phone });
      setUser(data);
      toast.success(t('settings.profileSaved'));
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
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
      toast.success(t('settings.passwordSaved'));
      setOldPwd('');
      setNewPwd('');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSavingPwd(false);
    }
  }

  return (
    <div className="space-y-4 max-w-3xl">
      <h1 className="text-2xl font-bold">{t('settings.title')}</h1>

      <Card title={t('settings.avatarCard')}>
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

      <Card title={t('settings.profileCard')}>
        <div className="space-y-3">
          <div>
            <label className="label">{t('settings.phoneLabel')}</label>
            <PhoneInput value={phone} onChange={setPhone} defaultCountry="UZ" />
            <p className="mt-1 text-xs text-ink-soft">
              {t('settings.phoneHint')}
            </p>
          </div>
          <div>
            <label className="label">{t('settings.fullNameLabel')}</label>
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
            {savingProfile ? t('settings.savingBtn') : t('settings.saveBtn')}
          </button>
        </div>
      </Card>

      <Card title={t('settings.changePasswordCard')}>
        <div className="space-y-3">
          <div>
            <label className="label">{t('settings.oldPasswordLabel')}</label>
            <input
              type="password"
              className="input"
              value={oldPwd}
              onChange={(e) => setOldPwd(e.target.value)}
              autoComplete="current-password"
            />
          </div>
          <div>
            <label className="label">{t('settings.newPasswordLabel')}</label>
            <input
              type="password"
              className="input"
              value={newPwd}
              onChange={(e) => setNewPwd(e.target.value)}
              placeholder={t('settings.newPasswordPlaceholder')}
              autoComplete="new-password"
            />
          </div>
          <button
            className="btn-primary disabled:opacity-40 disabled:cursor-not-allowed"
            onClick={changePassword}
            disabled={!passwordReady || savingPwd}
          >
            {savingPwd ? t('settings.changingBtn') : t('settings.changeBtn')}
          </button>
        </div>
      </Card>
    </div>
  );
}
