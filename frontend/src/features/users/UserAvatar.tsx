import { useEffect, useMemo, useState } from 'react';

const API_BASE = import.meta.env.VITE_API_BASE_URL || '/api/v1';

/**
 * Avatar widget.
 * - user.avatar_url bo'lsa rasmni yuklashga urinadi
 * - rasm xato bersa (404, network) initiallarga qaytadi
 * - cacheBust faqat berilganda URL'ga qo'shiladi (TopBar'da har render'da yangilanmasligi uchun)
 */
export default function UserAvatar({
  user,
  size = 32,
  cacheBust,
}: {
  user: { id: string; full_name?: string | null; phone?: string | null; avatar_url?: string | null };
  size?: number;
  cacheBust?: number | string;
}) {
  const [imgError, setImgError] = useState(false);

  // user yoki cacheBust o'zgarsa — xato holatini reset qilamiz
  useEffect(() => {
    setImgError(false);
  }, [user.id, user.avatar_url, cacheBust]);

  const initials = useMemo(() => {
    const name = (user.full_name || 'U').trim();
    const parts = name.split(/\s+/).filter(Boolean);
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.slice(0, 1).toUpperCase();
  }, [user.full_name]);

  const showImage = !!user.avatar_url && !imgError;

  const baseUrl = `${API_BASE}/users/${user.id}/avatar`;
  const url = cacheBust !== undefined ? `${baseUrl}?v=${cacheBust}` : baseUrl;

  const style = { width: size, height: size, fontSize: Math.max(10, size / 2.6) };

  if (showImage) {
    return (
      <img
        src={url}
        alt={user.full_name || 'avatar'}
        className="rounded-full object-cover border border-black/5 shrink-0 bg-card"
        style={style}
        loading="lazy"
        onError={() => {
          // Console'ga log — debug uchun
          console.warn('[UserAvatar] Rasm yuklanmadi, initials ko\'rsatamiz:', url);
          setImgError(true);
        }}
      />
    );
  }

  return (
    <div
      className="rounded-full bg-primary text-white font-semibold flex items-center justify-center shrink-0 select-none"
      style={style}
      title={user.full_name || ''}
    >
      {initials}
    </div>
  );
}
