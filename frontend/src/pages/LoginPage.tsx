import { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

import { api } from '@/api/client';
import { useAuthStore } from '@/stores/auth';
import PhoneInput from '@/components/ui/PhoneInput';

export default function LoginPage() {
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);

  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!phone.trim()) {
      toast.error('Telefon raqam');
      return;
    }
    setLoading(true);
    try {
      const { data } = await api.post('/auth/login', { phone, password });
      setAuth(data.user, data.access_token, data.refresh_token);
      toast.success(`Xush kelibsiz, ${data.user.full_name}!`);
      navigate('/');
    } catch (err: any) {
      toast.error(err?.response?.data?.detail || "Telefon raqam yoki parol noto'g'ri");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-6">
          <div className="inline-flex w-14 h-14 rounded-2xl bg-primary text-white text-xl font-bold items-center justify-center shadow-cozy">N</div>
          <h1 className="mt-3 text-2xl font-bold">NUR Project</h1>
          <p className="text-sm text-ink-soft mt-1">NUR TECHNO GROUP — ichki tizim</p>
        </div>

        <form onSubmit={onSubmit} className="card space-y-4">
          <h2 className="text-lg font-semibold">Tizimga kirish</h2>

          <div>
            <label className="label">Telefon raqam</label>
            <PhoneInput value={phone} onChange={setPhone} />
          </div>

          <div>
            <label className="label">Parol</label>
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
            {loading ? '...' : 'Kirish'}
          </button>
        </form>
      </div>
    </div>
  );
}
