// Buyurtma statuslari uchun yagona manba: o'zbekcha nomlar va grafik ranglari.

const ORDER_STATUS_LABELS: Record<string, string> = {
  new: 'Navbatda',
  confirmed: 'Tasdiqlangan',
  in_production: 'Ishlab chiqarishda',
  ready: 'Tayyor',
  delivered: 'Yetkazilgan',
  paid: "To'langan",
  rejected: 'Rad etilgan',
  cancelled: 'Bekor qilingan',
};

const SERVICE_STATUS_LABELS: Record<string, string> = {
  new: 'Yangi',
  scheduled: 'Rejalashtirilgan',
  completed: 'Bajarildi',
  cancelled: 'Bekor qilingan',
};

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
  return ORDER_STATUS_LABELS[status] ?? status;
}

export function orderStatusColor(status: string): string {
  return ORDER_STATUS_COLORS[status] ?? '#95A5A6';
}

export function serviceStatusLabel(status: string): string {
  return SERVICE_STATUS_LABELS[status] ?? status;
}
