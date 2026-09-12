import {
  LayoutDashboard, ShoppingCart, Users, Package, Wrench, Wallet,
  UserSquare2, Truck, BarChart3, Settings, ShieldCheck, ListOrdered, Warehouse,
  Coins, PackageOpen, Factory, Building2, Globe, Target, Sparkles, ServerCog, Calculator,
  Send,
  type LucideIcon,
} from 'lucide-react';
import { usePermissions } from '@/lib/permissions';

export interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
  module?: string;   // ruxsat tekshiriladigan modul (yo'q bo'lsa — hammaga ko'rinadi)
  superadmin?: boolean;  // faqat super-admin ko'radi
  exact?: boolean;
  children?: NavItem[];  // quyi-menyu (masalan: Ta'minot → Ichki / Tashqi)
  // true — shu bo'limdan OLDIN ajratuvchi chiziq chiziladi (pastdagi alohida guruh)
  divider?: boolean;
}

/**
 * Barcha bo'limlar uchun YAGONA navigatsiya ro'yxati.
 * Desktop sidebar (Sidebar.tsx) va mobil pastki panel (MobileNav.tsx) shu
 * ro'yxatdan foydalanadi — shunda menyular hech qachon bir-biridan farq qilmaydi.
 * Foydalanuvchining ruxsati bo'yicha avtomatik filtrlanadi.
 */
export function useNavItems(): NavItem[] {
  const { canModule, isSuperadmin } = usePermissions();
  const items: NavItem[] = [
    { to: '/', label: 'Bosh sahifa', icon: LayoutDashboard, exact: true, module: 'reports' },
    { to: '/targets', label: 'Maqsadlar', icon: Target, module: 'targets' },
    { to: '/orders', label: 'Sotuv', icon: ShoppingCart, module: 'orders' },
    { to: '/queue', label: 'Navbat', icon: ListOrdered, module: 'orders' },
    { to: '/shipping', label: 'Yuk chiqarish', icon: PackageOpen, module: 'shipping' },
    { to: '/customers', label: 'Mijozlar', icon: Users, module: 'customers' },
    { to: '/products', label: 'Mahsulotlar', icon: Package, module: 'products' },
    { to: '/costing', label: 'Tannarx', icon: Calculator, module: 'costing' },
    { to: '/warehouse', label: 'Ombor', icon: Warehouse, module: 'inventory' },
    { to: '/production', label: 'Ishlab chiqarish', icon: Factory, module: 'production' },
    { to: '/service', label: 'Servis', icon: Wrench, module: 'service' },
    { to: '/finance', label: 'Moliya', icon: Wallet, module: 'finance' },
    { to: '/debts', label: 'Bizning qarzlar', icon: Coins, module: 'debts' },
    { to: '/hr', label: 'Xodimlar', icon: UserSquare2, module: 'hr' },
    { to: '/supply', label: "Ta'minot", icon: Truck, children: [
      { to: '/supply/ichki', label: 'Ichki taʼminot', icon: Building2, module: 'supply_ichki' },
      { to: '/supply/tashqi', label: 'Tashqi taʼminot', icon: Globe, module: 'supply_tashqi' },
    ] },
    { to: '/reports', label: 'Hisobotlar', icon: BarChart3, module: 'reports' },
    { to: '/users', label: 'Foydalanuvchilar', icon: ShieldCheck, module: 'users' },
    { to: '/settings', label: 'Sozlamalar', icon: Settings },
    { to: '/system-settings', label: 'Tizim sozlamalari', icon: ServerCog, superadmin: true },
  ];

  // Eng pastdagi ALOHIDA guruh — AI kanallari. Kundalik ish oqimiga kirmaydi,
  // shuning uchun ro'yxat oxirida, ajratuvchi chiziqdan keyin turadi.
  const bottom: NavItem[] = [
    { to: '/leads', label: 'Leadlar', icon: Sparkles, module: 'leads' },
    { to: '/wa-bridge', label: 'WhatsApp navbati', icon: Send, module: 'telegram' },
  ];

  const visible = (it: NavItem) =>
    (!it.module || canModule(it.module)) && (!it.superadmin || isSuperadmin);
  const keep = (list: NavItem[]) => list
    .map((it) => (it.children ? { ...it, children: it.children.filter(visible) } : it))
    // Quyi-menyu: kamida bitta ko'rinadigan bola bo'lsa otani ko'rsatamiz
    .filter((it) => (it.children ? it.children.length > 0 : visible(it)));

  const tail = keep(bottom);
  // Chiziq faqat guruhning BIRINCHI ko'rinadigan bo'limi oldiga chiziladi
  // (ruxsat yo'qligi sababli biri yashirilsa ham chiziq joyida qoladi).
  if (tail.length) tail[0] = { ...tail[0], divider: true };
  return [...keep(items), ...tail];
}
