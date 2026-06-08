import { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Camera, Trash2 } from 'lucide-react';
import { api } from '@/api/client';
import ConfirmModal from '@/components/ui/ConfirmModal';
import UserAvatar from './UserAvatar';

export default function AvatarUploader({
  user,
  size = 96,
  endpoint,
  onChanged,
}: {
  user: { id: string; full_name?: string | null; phone?: string | null; avatar_url?: string | null };
  size?: number;
  endpoint: string;
  onChanged?: (u: any) => void;
}) {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [bust, setBust] = useState<number>(Date.now());
  const [askDelete, setAskDelete] = useState(false);

  async function onFile(file: File) {
    if (!file.type.startsWith('image/')) {
      toast.error(t('ui.avatar.onlyImage'));
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      toast.error(t('ui.avatar.tooLarge'));
      return;
    }
    setBusy(true);
    try {
      const form = new FormData();
      form.append('file', file);
      const { data } = await api.post(endpoint, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      toast.success(t('ui.avatar.uploaded'));
      setBust(Date.now());
      onChanged?.(data);
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('ui.avatar.uploadError'));
    } finally {
      setBusy(false);
    }
  }

  async function doDelete() {
    setBusy(true);
    try {
      await api.delete(endpoint);
      toast.success(t('ui.avatar.deleted'));
      setBust(Date.now());
      onChanged?.({ ...user, avatar_url: null });
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setBusy(false);
      setAskDelete(false);
    }
  }

  return (
    <>
      <div className="flex items-center gap-4">
        <div className="relative">
          <UserAvatar user={user} size={size} cacheBust={bust} />
          {busy && (
            <div className="absolute inset-0 bg-black/30 rounded-full flex items-center justify-center text-white text-xs">
              ...
            </div>
          )}
        </div>
        <div className="flex flex-col gap-2">
          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            disabled={busy}
            className="flex items-center gap-2 px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5 disabled:opacity-50"
          >
            <Camera size={14} /> {t('ui.avatar.upload')}
          </button>
          {user.avatar_url && (
            <button
              type="button"
              onClick={() => setAskDelete(true)}
              disabled={busy}
              className="flex items-center gap-2 px-3 py-1.5 text-sm rounded-button text-danger hover:bg-danger/5 disabled:opacity-50"
            >
              <Trash2 size={14} /> {t('ui.avatar.delete')}
            </button>
          )}
          <p className="text-xs text-ink-soft">{t('ui.avatar.hint')}</p>
        </div>
        <input
          ref={inputRef}
          type="file"
          accept="image/png,image/jpeg,image/jpg,image/webp,image/gif"
          className="hidden"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) onFile(f);
            e.target.value = '';
          }}
        />
      </div>

      <ConfirmModal
        open={askDelete}
        title={t('ui.avatar.deleteTitle')}
        message={t('ui.avatar.deleteMessage')}
        confirmText={t('ui.avatar.deleteConfirm')}
        variant="danger"
        loading={busy}
        onConfirm={doDelete}
        onCancel={() => !busy && setAskDelete(false)}
      />
    </>
  );
}
