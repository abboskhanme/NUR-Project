// Buyurtma statuslari uchun yagona manba: i18n kalitlari va grafik ranglari.
// Label'lar chaqiruv paytida joriy tilda olinadi (i18n.t) — til almashganda
// komponent qayta render bo'lganda yangi til qo'llanadi.
import i18n from '@/locales/i18n';

export const ORDER_STATUS_COLORS: Record<string, string> = {
  new: '#2980B9',
  ready: '#16A085',
  delivered: '#27AE60',
  rejected: '#E74C3C',
  confirmed: '#6C5CE7',
  in_production: '#F39C12',
  paid: '#27AE60',
  cancelled: '#E74C3C',
};

export function orderStatusLabel(status: string): string {
  return i18n.t(`status.${status}`, { defaultValue: status });
}

export function orderStatusColor(status: string): string {
  return ORDER_STATUS_COLORS[status] ?? '#95A5A6';
}

export function serviceStatusLabel(status: string): string {
  return i18n.t(`service.status.${status}`, { defaultValue: status });
}
