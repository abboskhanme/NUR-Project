import { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';

import { api } from '@/api/client';
import { useAuthStore } from '@/stores/auth';

export default function LoginPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);

  const [email, setEmail] = useState('admin@nurtechno.uz');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      const { data } = await api.post('/auth/login', { email, password });
      setAuth(data.user, data.access_token, data.refresh_token);
      toast.success(`Xush kelibsiz, ${data.user.full_name}!`);
      navigate('/');
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || t('auth.wrong'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-6">
          <div className="inline-flex w-14 h-14 rounded-2xl bg-primary text-white text-xl font-bold items-center justify-center shadow-cozy">N</div>
          <h1 className="mt-3 text-2xl font-bold">NurBunker ERP</h1>
          <p className="text-sm text-ink-soft mt-1">NUR TECHNO GROUP — ichki tizim</p>
        </div>

        <form onSubmit={onSubmit} className="card space-y-4">
          <h2 className="text-lg font-semibold">{t('auth.login')}</h2>

          <div>
            <label className="label">{t('auth.email')}</label>
            <input
              type="email"
              autoComplete="email"
              required
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div>
            <label className="label">{t('auth.password')}</label>
            <input
              type="password"
              autoComplete="current-password"
              required
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button type="submit" className="btn-primary w-full" disabled={loading}>
            {loading ? '...' : t('auth.submit')}
          </button>

          <div className="text-xs text-ink-soft text-center">
            Default: admin@nurtechno.uz / Admin@12345
          </div>
        </form>
      </div>
    </div>
  );
}
