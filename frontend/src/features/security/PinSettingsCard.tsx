import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import { useAuthStore } from '@/stores/auth';

const TIMEOUT_OPTIONS = [1, 2, 5, 10, 15, 30];

/** Sozlamalar > Harakatsizlik PIN-qulfi boshqaruvi. */
export default function PinSettingsCard() {
  const user = useAuthStore((s) => s.user);
  const setUser = useAuthStore((s) => s.setUser);

  const enabled = !!user?.pin_enabled;

  const [password, setPassword] = useState('');
  const [pin, setPin] = useState('');
  const [pin2, setPin2] = useState('');
  const [timeout, setTimeoutMin] = useState<number>(user?.pin_timeout_minutes ?? 5);
  const [busy, setBusy] = useState(false);
  const [mode, setMode] = useState<'idle' | 'change' | 'disable'>('idle');

  useEffect(() => {
    setTimeoutMin(user?.pin_timeout_minutes ?? 5);
  }, [user?.pin_timeout_minutes]);

  const onlyDigits = (v: string) => v.replace(/\D/g, '').slice(0, 4);

  function reset() {
    setPassword('');
    setPin('');
    setPin2('');
    setMode('idle');
  }

  async function savePin() {
    if (pin.length !== 4) {
      toast.error('PIN aniq 4 ta raqamdan iborat bo\'lishi kerak');
      return;
    }
    if (pin !== pin2) {
      toast.error('PIN-kodlar mos kelmadi');
      return;
    }
    if (!password) {
      toast.error('Parolni kiriting');
      return;
    }
    setBusy(true);
    try {
      const { data } = await api.post('/auth/me/pin', {
        password,
        pin,
        timeout_minutes: timeout,
      });
      setUser(data);
      toast.success('PIN-qulf yoqildi');
      reset();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  async function saveTimeout(minutes: number) {
    setTimeoutMin(minutes);
    if (!enabled) return;
    try {
      const { data } = await api.patch('/auth/me/pin', { timeout_minutes: minutes });
      setUser(data);
      toast.success('Vaqt saqlandi');
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    }
  }

  async function disablePin() {
    if (!password) {
      toast.error('Parolni kiriting');
      return;
    }
    setBusy(true);
    try {
      const { data } = await api.post('/auth/me/pin/disable', { password });
      setUser(data);
      toast.success("PIN-qulf o'chirildi");
      reset();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
    } finally {
      setBusy(false);
    }
  }

  const timeoutSelect = (
    <div>
      <label className="label">Harakatsizlik vaqti</label>
      <select
        className="input"
        value={timeout}
        onChange={(e) => saveTimeout(Number(e.target.value))}
      >
        {TIMEOUT_OPTIONS.map((m) => (
          <option key={m} value={m}>
            {`${m} daqiqa`}
          </option>
        ))}
      </select>
    </div>
  );

  return (
    <Card title="PIN-qulf (harakatsizlik)">
      <p className="text-xs text-ink-soft mb-3">Belgilangan vaqt davomida harakatsiz bo'lsangiz, sayt qulflanadi va PIN-kod so'raydi. Bu siz kompyuter yonida bo'lmagan paytda boshqalar sizning nomingizdan ish qilishining oldini oladi.</p>

      {/* O'CHIQ holat — yoqish formasi */}
      {!enabled && (
        <div className="space-y-3">
          <div>
            <label className="label">4 xonali PIN</label>
            <input
              type="password"
              inputMode="numeric"
              className="input tracking-[0.5em] text-center"
              value={pin}
              onChange={(e) => setPin(onlyDigits(e.target.value))}
              placeholder="••••"
              autoComplete="off"
            />
          </div>
          <div>
            <label className="label">PIN-ni takrorlang</label>
            <input
              type="password"
              inputMode="numeric"
              className="input tracking-[0.5em] text-center"
              value={pin2}
              onChange={(e) => setPin2(onlyDigits(e.target.value))}
              placeholder="••••"
              autoComplete="off"
            />
          </div>
          {timeoutSelect}
          <div>
            <label className="label">Joriy parolingiz</label>
            <input
              type="password"
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
            />
          </div>
          <button className="btn-primary" onClick={savePin} disabled={busy}>
            {busy ? 'Saqlanmoqda...' : 'PIN-qulfni yoqish'}
          </button>
        </div>
      )}

      {/* YOQILGAN holat */}
      {enabled && (
        <div className="space-y-3">
          <div className="flex items-center gap-2 text-sm text-success">
            <span className="inline-block h-2 w-2 rounded-full bg-success" />
            PIN-qulf yoqilgan
          </div>

          {timeoutSelect}

          {mode === 'idle' && (
            <div className="flex gap-2">
              <button className="btn-ghost" onClick={() => setMode('change')}>
                PIN-ni o'zgartirish
              </button>
              <button className="btn-danger" onClick={() => setMode('disable')}>
                O'chirish
              </button>
            </div>
          )}

          {mode === 'change' && (
            <div className="space-y-3 rounded-button border border-black/10 p-3">
              <div>
                <label className="label">4 xonali PIN</label>
                <input
                  type="password"
                  inputMode="numeric"
                  className="input tracking-[0.5em] text-center"
                  value={pin}
                  onChange={(e) => setPin(onlyDigits(e.target.value))}
                  placeholder="••••"
                  autoComplete="off"
                />
              </div>
              <div>
                <label className="label">PIN-ni takrorlang</label>
                <input
                  type="password"
                  inputMode="numeric"
                  className="input tracking-[0.5em] text-center"
                  value={pin2}
                  onChange={(e) => setPin2(onlyDigits(e.target.value))}
                  placeholder="••••"
                  autoComplete="off"
                />
              </div>
              <div>
                <label className="label">Joriy parolingiz</label>
                <input
                  type="password"
                  className="input"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                />
              </div>
              <div className="flex gap-2">
                <button className="btn-primary" onClick={savePin} disabled={busy}>
                  Saqlash
                </button>
                <button className="btn-ghost" onClick={reset} disabled={busy}>
                  Bekor qilish
                </button>
              </div>
            </div>
          )}

          {mode === 'disable' && (
            <div className="space-y-3 rounded-button border border-danger/30 p-3">
              <p className="text-sm text-ink-soft">PIN-qulfni o'chirish uchun parolingizni tasdiqlang.</p>
              <div>
                <label className="label">Joriy parolingiz</label>
                <input
                  type="password"
                  className="input"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                />
              </div>
              <div className="flex gap-2">
                <button className="btn-danger" onClick={disablePin} disabled={busy}>
                  O'chirish
                </button>
                <button className="btn-ghost" onClick={reset} disabled={busy}>
                  Bekor qilish
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </Card>
  );
}
