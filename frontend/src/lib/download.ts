// Himoyalangan (JWT) endpointdan faylni blob sifatida olib yuklab olish.
// PDF, Excel va boshqa fayllar uchun umumiy yordamchi.
import { api } from '@/api/client';

export async function downloadFile(
  url: string,
  filename: string,
  params?: Record<string, unknown>,
): Promise<void> {
  const res = await api.get(url, { responseType: 'blob', params });
  const blob = new Blob([res.data], {
    type: (res.headers?.['content-type'] as string) || 'application/octet-stream',
  });
  const objUrl = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = objUrl;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(objUrl);
}
