// PDF yuklab olish yordamchisi — himoyalangan (JWT) endpointdan blob sifatida
// oladi va brauzerda yuklab olishni boshlaydi.
import { api } from '@/api/client';

/**
 * PDF hujjatni serverdan olib, foydalanuvchi qurilmasiga yuklab oladi.
 * @param url      api klientiga nisbiy yo'l, masalan `/orders/<id>/invoice.pdf`
 * @param filename saqlanadigan fayl nomi
 */
export async function downloadPdf(url: string, filename: string): Promise<void> {
  const res = await api.get(url, { responseType: 'blob' });
  const blob = new Blob([res.data], { type: 'application/pdf' });
  const objUrl = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = objUrl;
  a.download = filename.endsWith('.pdf') ? filename : `${filename}.pdf`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(objUrl);
}
