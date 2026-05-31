import { useEffect } from 'react';
import { AlertTriangle, X } from 'lucide-react';

export interface ConfirmModalProps {
  open: boolean;
  title: string;
  message: string | React.ReactNode;
  confirmText?: string;
  cancelText?: string;
  /** "danger" — qizil tugma (o'chirish), "primary" — asosiy rang */
  variant?: 'danger' | 'primary';
  loading?: boolean;
  onConfirm: () => void | Promise<void>;
  onCancel: () => void;
}

/**
 * Brauzer confirm() o'rniga maxsus modal. Boshqa modallar uchungina ishlatiladi —
 * masalan o'chirish yoki kritik o'zgarishni tasdiqlash.
 */
export default function ConfirmModal({
  open,
  title,
  message,
  confirmText = 'Tasdiqlash',
  cancelText = 'Bekor qilish',
  variant = 'danger',
  loading = false,
  onConfirm,
  onCancel,
}: ConfirmModalProps) {
  useEffect(() => {
    if (!open) return;
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && !loading && onCancel();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [open, loading, onCancel]);

  if (!open) return null;

  const btn =
    variant === 'danger'
      ? 'bg-danger text-white hover:bg-danger/90'
      : 'bg-primary text-white hover:bg-primary/90';

  return (
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4"
      onClick={() => !loading && onCancel()}
    >
      <div
        className="bg-card rounded-lg shadow-xl w-full max-w-md"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between px-5 py-4 border-b border-black/5">
          <div className="flex items-start gap-3">
            <div
              className={
                'w-9 h-9 rounded-full flex items-center justify-center shrink-0 ' +
                (variant === 'danger' ? 'bg-danger/10 text-danger' : 'bg-primary/10 text-primary')
              }
            >
              <AlertTriangle size={18} />
            </div>
            <div>
              <h3 className="font-semibold text-base">{title}</h3>
            </div>
          </div>
          <button
            onClick={onCancel}
            disabled={loading}
            className="p-1 rounded hover:bg-black/5 text-ink/50 disabled:opacity-30"
          >
            <X size={18} />
          </button>
        </div>

        <div className="px-5 py-4 text-sm text-ink/80">{message}</div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button
            onClick={onCancel}
            disabled={loading}
            className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-50"
          >
            {cancelText}
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className={`px-4 py-1.5 text-sm rounded-button font-medium disabled:opacity-50 ${btn}`}
          >
            {loading ? 'Bajarilmoqda…' : confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}
