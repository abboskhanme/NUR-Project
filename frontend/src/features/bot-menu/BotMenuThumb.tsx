import { useEffect, useState } from 'react';
import { Image as ImageIcon } from 'lucide-react';

import { botMenuApi } from '@/features/bot-menu/api';

/**
 * Menyu rasmi. Endpoint auth (token) talab qiladi — <img src> emas, blob
 * sifatida yuklab object URL qilamiz (ProductThumb bilan bir xil naqsh).
 */
export default function BotMenuThumb({ imageId, size = 56 }: { imageId: string; size?: number }) {
  const [url, setUrl] = useState<string | null>(null);

  useEffect(() => {
    let obj: string | null = null;
    let alive = true;
    botMenuApi
      .imageBlob(imageId)
      .then((blob) => {
        if (!alive) return;
        obj = URL.createObjectURL(blob);
        setUrl(obj);
      })
      .catch(() => {});
    return () => {
      alive = false;
      if (obj) URL.revokeObjectURL(obj);
    };
  }, [imageId]);

  if (url) {
    return (
      <img src={url} alt="" loading="lazy"
           className="rounded-button object-cover border border-black/5 bg-card shrink-0"
           style={{ width: size, height: size }} />
    );
  }
  return (
    <div className="rounded-button bg-black/5 flex items-center justify-center text-ink-soft shrink-0"
         style={{ width: size, height: size }}>
      <ImageIcon size={Math.round(size * 0.4)} />
    </div>
  );
}
