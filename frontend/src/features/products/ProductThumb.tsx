import { useEffect, useState } from 'react';
import { Image as ImageIcon } from 'lucide-react';

import { api } from '@/api/client';

/**
 * Mahsulot rasmini ko'rsatadi.
 * Rasm endpointi auth (token) talab qiladi, shuning uchun <img src> emas —
 * api client orqali blob sifatida yuklab, object URL qilamiz.
 */
export default function ProductThumb({
  id,
  hasImage,
  size = 40,
  bust,
}: {
  id: string;
  hasImage?: boolean;
  size?: number;
  bust?: number;
}) {
  const [url, setUrl] = useState<string | null>(null);

  useEffect(() => {
    if (!hasImage) { setUrl(null); return; }
    let obj: string | null = null;
    let alive = true;
    api
      .get(`/products/${id}/image`, { responseType: 'blob' })
      .then((r) => {
        if (!alive) return;
        obj = URL.createObjectURL(r.data);
        setUrl(obj);
      })
      .catch(() => {});
    return () => {
      alive = false;
      if (obj) URL.revokeObjectURL(obj);
    };
  }, [id, hasImage, bust]);

  if (url) {
    return (
      <img
        src={url}
        alt=""
        className="rounded object-cover border border-black/5 bg-card shrink-0"
        style={{ width: size, height: size }}
        loading="lazy"
      />
    );
  }
  return (
    <div
      className="rounded bg-black/5 flex items-center justify-center text-ink-soft shrink-0"
      style={{ width: size, height: size }}
    >
      <ImageIcon size={Math.round(size * 0.5)} />
    </div>
  );
}
