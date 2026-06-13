import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  LayoutDashboard, ShoppingCart, Users, Package, Wrench, Wallet,
  UserSquare2, Truck, BarChart3, Settings, ChevronLeft, ChevronRight,
  ShieldCheck, ListOrdered, Warehouse,
} from 'lucide-react';

import { useUIStore } from '@/stores/ui';
import { usePermissions } from '@/lib/permissions';
import { cn } from '@/lib/cn';

export default function Sidebar() {
  const { t } = useTranslation();
  const collapsed = useUIStore((s) => s.sidebarCollapsed);
  const toggle = useUIStore((s) => s.toggleSidebar);
  const { canModule } = usePermissions();

  // module: ruxsat tekshiriladigan modul (yo'q bo'lsa — hammaga ko'rinadi)
  const items = [
    { to: '/', label: t('nav.dashboard'), icon: LayoutDashboard, exact: true },
    { to: '/orders', label: t('nav.sales'), icon: ShoppingCart, module: 'orders' },
    { to: '/queue', label: t('nav.queue', { defaultValue: 'Navbat' }), icon: ListOrdered, module: 'orders' },
    { to: '/customers', label: t('nav.customers'), icon: Users, module: 'customers' },
    { to: '/products', label: t('nav.products'), icon: Package, module: 'products' },
    { to: '/warehouse', label: t('nav.warehouse', { defaultValue: 'Ombor' }), icon: Warehouse, module: 'inventory' },
    { to: '/service', label: t('nav.service'), icon: Wrench, module: 'service' },
    { to: '/finance', label: t('nav.finance'), icon: Wallet, module: 'finance' },
    { to: '/hr', label: t('nav.hr'), icon: UserSquare2, module: 'hr' },
    { to: '/supply', label: t('nav.supply'), icon: Truck, module: 'supply' },
    { to: '/reports', label: t('nav.reports'), icon: BarChart3, module: 'reports' },
    { to: '/users', label: t('nav.users', { defaultValue: 'Foydalanuvchilar' }), icon: ShieldCheck, module: 'users' },
    { to: '/settings', label: t('nav.settings'), icon: Settings },
  ].filter((it) => !it.module || canModule(it.module));

  return (
    <aside className="h-screen sticky top-0 bg-card border-r border-black/5 flex flex-col">
      <div className="flex items-center gap-3 px-4 h-16 border-b border-black/5">
        <div className="w-9 h-9 rounded-button bg-primary text-white flex items-center justify-center font-bold">N</div>
        {!collapsed && <div className="font-semibold text-sm">NUR Project</div>}
      </div>

      <nav className="flex-1 overflow-y-auto py-2">
        {items.map(({ to, label, icon: Icon, exact }) => (
          <NavLink
            key={to}
            to={to}
            end={exact}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 px-4 py-2.5 mx-2 my-0.5 rounded-button text-sm font-medium transition-colors',
                isActive ? 'bg-primary/10 text-primary' : 'text-ink/70 hover:bg-black/5',
              )
            }
          >
            <Icon size={18} />
            {!collapsed && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>

      <button onClick={toggle}
              className="m-3 p-2 rounded-button hover:bg-black/5 text-ink/60 self-end">
        {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
      </button>
    </aside>
  );
}
