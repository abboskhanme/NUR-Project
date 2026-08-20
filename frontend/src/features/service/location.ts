// Servis lokatsiyasi — navigator havolalari va kichik yordamchilar.
// Havolalar API kaliti yoki to'lov talab qilmaydi.
//
// DIQQAT — tartib: Google `lat,lon`, Yandex va 2GIS esa `lon,lat` kutadi.

export interface LatLon {
  lat: number;
  lon: number;
}

export interface TicketLocationFields {
  lat?: number | null;
  lon?: number | null;
  location_url?: string | null;
  location_note?: string | null;
  location_source?: string | null;
  location_added_at?: string | null;
}

const six = (n: number) => n.toFixed(6);

export function hasLocation(tk: TicketLocationFields | null | undefined): boolean {
  return !!tk && tk.lat != null && tk.lon != null;
}

export function formatCoords(lat: number, lon: number): string {
  return `${six(lat)}, ${six(lon)}`;
}

export function mapLinks(lat: number, lon: number) {
  return {
    // Yandex xarita — nuqta (mobil qurilmada Navigator ilovasiga o'tadi)
    yandex: `https://yandex.uz/maps/?pt=${six(lon)},${six(lat)}&z=17&l=map`,
    // Yandex marshrut — "mening joyimdan" shu nuqtagacha
    yandexRoute: `https://yandex.uz/maps/?rtext=~${six(lat)},${six(lon)}&rtt=auto`,
    google: `https://www.google.com/maps/search/?api=1&query=${six(lat)},${six(lon)}`,
    twogis: `https://2gis.uz/geo/${six(lon)},${six(lat)}`,
  };
}

/** Bir nechta nuqta bo'yicha marshrut (servis safari) — Yandex xaritada. */
export function routeLink(points: LatLon[]): string | null {
  if (points.length === 0) return null;
  const rtext = ['', ...points.map((p) => `${six(p.lat)},${six(p.lon)}`)].join('~');
  return `https://yandex.uz/maps/?rtext=${rtext}&rtt=auto`;
}

/** Lokatsiya manbai — kartochkada kichik izoh sifatida ko'rsatiladi. */
export function sourceLabel(source?: string | null): string {
  return source === 'telegram' ? 'Telegram pin'
    : source === 'link' ? 'Xarita havolasi'
    : source === 'manual' ? "Qo'lda kiritilgan"
    : '';
}

export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    return false;
  }
}
