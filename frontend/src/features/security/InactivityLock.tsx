import { useCallback, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { api } from '@/api/client';
import { useAuthStore } from '@/stores/auth';
import { usePinLockStore } from '@/stores/pinLock';
import { cn } from '@/lib/cn';

const ACTIVITY_EVENTS = ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll', 'wheel'];
const MAX_ATTEMPTS = 5;

/**
 * Harakatsizlik PIN-qulfi.
 *
 * Foydalanuvchi `pin_timeout_minutes` davomida hech qanday harakat qilmasa,
 * butun sayt blur ostida qulflanadi va 4 xonali PIN so'raydi. To'g'ri PIN
 * kiritilsa ish davom etadi. Bir necha marta xato kiritilsa — to'liq logout.
 *
 * Komponent AppLayout ichida bir marta mount qilinadi.
 */
export default function InactivityLock() {
  const { t } = useTranslation();
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);
  const locked = usePinLockStore((s) => s.locked);
  const lock = usePinLockStore((s) => s.lock);
  const unlock = usePinLockStore((s) => s.unlock);

  const pinEnabled = !!user?.pin_enabled;
  const timeoutMs = Math.max(1, user?.pin_timeout_minutes ?? 5) * 60_000;

  const lastActivity = useRef(Date.now());

  // PIN yoqilmagan bo'lsa, qulf holatini ushlab turmaymiz.
  useEffect(() => {
    if (!pinEnabled && locked) unlock();
  }, [pinEnabled, locked, unlock]);

  // Harakatni kuzatamiz (qulf ochiq paytda).
  useEffect(() => {
    if (!pinEnabled) return;
    const onActivity = () => {
      if (!usePinLockStore.getState().locked) lastActivity.current = Date.now();
    };
    ACTIVITY_EVENTS.forEach((e) => window.addEventListener(e, onActivity, { passive: true }));
    return () =>
      ACTIVITY_EVENTS.forEach((e) => window.removeEventListener(e, onActivity));
  }, [pinEnabled]);

  // Har soniyada harakatsizlikni tekshiramiz.
  useEffect(() => {
    if (!pinEnabled) return;
    const id = window.setInterval(() => {
      if (usePinLockStore.getState().locked) return;
      if (Date.now() - lastActivity.current >= timeoutMs) lock();
    }, 1000);
    return () => window.clearInterval(id);
  }, [pinEnabled, timeoutMs, lock]);

  const handleUnlocked = useCallback(() => {
    lastActivity.current = Date.now();
    unlock();
  }, [unlock]);

  if (!pinEnabled || !locked) return null;

  return (
    <PinOverlay
      userName={user?.full_name ?? ''}
      onUnlocked={handleUnlocked}
      onLogout={() => {
        unlock();
        logout();
      }}
      t={t}
    />
  );
}

function PinOverlay({
  userName,
  onUnlocked,
  onLogout,
  t,
}: {
  userName: string;
  onUnlocked: () => void;
  onLogout: () => void;
  t: (k: string, o?: any) => string;
}) {
  const [digits, setDigits] = useState('');
  const [error, setError] = useState(false);
  const [attempts, setAttempts] = useState(0);
  const [checking, setChecking] = useState(false);

  const submit = useCallback(
    async (pin: string) => {
      setChecking(true);
      try {
        await api.post('/auth/verify-pin', { pin });
        onUnlocked();
      } catch {
        const next = attempts + 1;
        setAttempts(next);
        setError(true);
        setDigits('');
        if (next >= MAX_ATTEMPTS) {
          onLogout();
        } else {
          window.setTimeout(() => setError(false), 600);
        }
      } finally {
        setChecking(false);
      }
    },
    [attempts, onUnlocked, onLogout],
  );

  const press = useCallback(
    (d: string) => {
      if (checking) return;
      setError(false);
      setDigits((prev) => (prev.length >= 4 ? prev : prev + d));
    },
    [checking],
  );

  const backspace = useCallback(() => {
    if (checking) return;
    setDigits((prev) => prev.slice(0, -1));
  }, [checking]);

  // 4 ta raqam to'lganda avtomatik tekshiramiz.
  useEffect(() => {
    if (digits.length === 4 && !checking) void submit(digits);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [digits]);

  // Klaviaturadan ham kiritish mumkin.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key >= '0' && e.key <= '9') {
        e.preventDefault();
        press(e.key);
      } else if (e.key === 'Backspace') {
        e.preventDefault();
        backspace();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [press, backspace]);

  const remaining = MAX_ATTEMPTS - attempts;

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/40 backdrop-blur-xl">
      <div className="w-[20rem] max-w-[90vw] rounded-2xl bg-card p-6 shadow-2xl border border-black/5 text-center">
        <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 text-primary">
          {/* qulf belgisi */}
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="4" y="11" width="16" height="9" rx="2" />
            <path d="M8 11V7a4 4 0 1 1 8 0v4" />
          </svg>
        </div>
        <h2 className="text-lg font-bold">{t('security.lockedTitle')}</h2>
        <p className="mt-1 text-sm text-ink-soft">{userName}</p>
        <p className="mt-0.5 text-xs text-ink-soft">{t('security.enterPin')}</p>

        {/* PIN nuqtalari */}
        <div className={cn('my-5 flex justify-center gap-3', error && 'animate-shake')}>
          {[0, 1, 2, 3].map((i) => (
            <span
              key={i}
              className={cn(
                'h-3.5 w-3.5 rounded-full border-2 transition-colors',
                error
                  ? 'border-danger bg-danger'
                  : i < digits.length
                    ? 'border-primary bg-primary'
                    : 'border-border bg-transparent',
              )}
            />
          ))}
        </div>

        {error && attempts < MAX_ATTEMPTS && (
          <p className="-mt-3 mb-2 text-xs text-danger">
            {t('security.wrongPin', { count: remaining })}
          </p>
        )}

        {/* Raqamli klaviatura */}
        <div className="grid grid-cols-3 gap-2.5">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((d) => (
            <KeypadBtn key={d} onClick={() => press(d)} disabled={checking}>
              {d}
            </KeypadBtn>
          ))}
          <div />
          <KeypadBtn onClick={() => press('0')} disabled={checking}>
            0
          </KeypadBtn>
          <KeypadBtn onClick={backspace} disabled={checking} aria-label="backspace">
            ⌫
          </KeypadBtn>
        </div>

        <button
          onClick={onLogout}
          className="mt-5 text-xs text-ink-soft underline hover:text-ink"
        >
          {t('security.forgotLogout')}
        </button>
      </div>
    </div>
  );
}

function KeypadBtn({
  children,
  onClick,
  disabled,
  ...rest
}: {
  children: React.ReactNode;
  onClick: () => void;
  disabled?: boolean;
} & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="h-14 rounded-xl bg-bg text-xl font-semibold text-ink transition-colors hover:bg-primary/10 active:bg-primary/20 disabled:opacity-50"
      {...rest}
    >
      {children}
    </button>
  );
}
