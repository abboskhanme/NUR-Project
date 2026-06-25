import {
  LayoutDashboard, ShoppingCart, Users, Package, Wrench, Wallet,
  UserSquare2, Truck, BarChart3, Settings, ShieldCheck, ListOrdered, Warehouse,
  Coins, PackageOpen, Factory,
  type LucideIcon,
} from 'lucide-react';
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
  const { canModule } = usePermissions();
  const items: NavItem[] = [
    { to: '/', label: 'Bosh sahifa', icon: LayoutDashboard, exact: true, module: 'reports' },
    { to: '/orders', label: 'Sotuv', icon: ShoppingCart, module: 'orders' },
    { to: '/queue', label: 'Navbat', icon: ListOrdered, module: 'orders' },
    { to: '/shipping', label: 'Yuk chiqarish', icon: PackageOpen, module: 'shipping' },
    { to: '/customers', label: 'Mijozlar', icon: Users, module: 'customers' },
    { to: '/products', label: 'Mahsulotlar', icon: Package, module: 'products' },
    { to: '/warehouse', label: 'Ombor', icon: Warehouse, module: 'inventory' },
    { to: '/production', label: 'Ishlab chiqarish', icon: Factory, module: 'production' },
    { to: '/service', label: 'Servis', icon: Wrench, module: 'service' },
    { to: '/finance', label: 'Moliya', icon: Wallet, module: 'finance' },
    { to: '/debts', label: 'Bizning qarzlar', icon: Coins, module: 'debts' },
    { to: '/hr', label: 'Xodimlar', icon: UserSquare2, module: 'hr' },
    { to: '/supply', label: "Ta'minot", icon: Truck, module: 'supply' },
    { to: '/reports', label: 'Hisobotlar', icon: BarChart3, module: 'reports' },
    { to: '/users', label: 'Foydalanuvchilar', icon: ShieldCheck, module: 'users' },
    { to: '/settings', label: 'Sozlamalar', icon: Settings },
  ];
  return items.filter((it) => !it.module || canModule(it.module));
}
