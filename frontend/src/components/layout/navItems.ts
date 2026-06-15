import {
  LayoutDashboard, ShoppingCart, Users, Package, Wrench, Wallet,
  UserSquare2, Truck, BarChart3, Settings, ShieldCheck, ListOrdered, Warehouse,
  Coins, PackageOpen,
  type LucideIcon,
} from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { usePermissions } from '@/lib/permissions';

export interface NavItem {
  to: string;
  label: string;
  icon: LucideIcon;
  module?: string;   // ruxsat tekshiriladigan modul (yo'q bo'lsa — hammaga ko'rinadi)
  exact?: boolean;
}

/**
 * Barcha bo'limlar uchun YAGONA navigatsiya ro'yxati.
 * Desktop sidebar (Sidebar.tsx) va mobil pastki panel (MobileNav.tsx) shu
 * ro'yxatdan foydalanadi — shunda menyular hech qachon bir-biridan farq qilmaydi.
 * Foydalanuvchining ruxsati bo'yicha avtomatik filtrlanadi.
 */
export function useNavItems(): NavItem[] {
  const { t } = useTranslation();
  const { canModule } = usePermissions();
  const items: NavItem[] = [
    { to: '/', label: t('nav.dashboard'), icon: LayoutDashboard, exact: true },
    { to: '/orders', label: t('nav.sales'), icon: ShoppingCart, module: 'orders' },
    { to: '/queue', label: t('nav.queue', { defaultValue: 'Navbat' }), icon: ListOrdered, module: 'orders' },
    { to: '/shipping', label: t('nav.shipping', { defaultValue: 'Yuk chiqarish' }), icon: PackageOpen, module: 'shipping' },
    { to: '/customers', label: t('nav.customers'), icon: Users, module: 'customers' },
    { to: '/products', label: t('nav.products'), icon: Package, module: 'products' },
    { to: '/warehouse', label: t('nav.warehouse', { defaultValue: 'Ombor' }), icon: Warehouse, module: 'inventory' },
    { to: '/service', label: t('nav.service'), icon: Wrench, module: 'service' },
    { to: '/finance', label: t('nav.finance'), icon: Wallet, module: 'finance' },
    { to: '/debts', label: t('nav.debts', { defaultValue: 'Bizning qarzlar' }), icon: Coins, module: 'debts' },
    { to: '/hr', label: t('nav.hr'), icon: UserSquare2, module: 'hr' },
    { to: '/supply', label: t('nav.supply'), icon: Truck, module: 'supply' },
    { to: '/reports', label: t('nav.reports'), icon: BarChart3, module: 'reports' },
    { to: '/users', label: t('nav.users', { defaultValue: 'Foydalanuvchilar' }), icon: ShieldCheck, module: 'users' },
    { to: '/settings', label: t('nav.settings'), icon: Settings },
  ];
  return items.filter((it) => !it.module || canModule(it.module));
}
