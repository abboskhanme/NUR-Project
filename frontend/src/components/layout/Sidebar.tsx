import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  LayoutDashboard, ShoppingCart, Users, Package, Wrench, Wallet,
  UserSquare2, Truck, BarChart3, Settings, ChevronLeft, ChevronRight,
  ShieldCheck, ListOrdered,
} from 'lucide-react';

import { useUIStore } from '@/stores/ui';
import { useAuthStore } from '@/stores/auth';
import { cn } from '@/lib/cn';

export default function Sidebar() {
  const { t } = useTranslation();
  const collapsed = useUIStore((s) => s.sidebarCollapsed);
  const toggle = useUIStore((s) => s.toggleSidebar);
  const user = useAuthStore((s) => s.user);
  const isAdmin = !!user?.is_superadmin || (user?.roles ?? []).some((r) => r.name === 'super_admin');

  const items = [
    { to: '/', label: t('nav.dashboard'), icon: LayoutDashboard, exact: true },
    { to: '/orders', label: t('nav.sales'), icon: ShoppingCart },
    { to: '/queue', label: t('nav.queue', { defaultValue: 'Navbat' }), icon: ListOrdered },
    { to: '/customers', label: t('nav.customers'), icon: Users },
    { to: '/products', label: t('nav.products'), icon: Package },
    { to: '/service', label: t('nav.service'), icon: Wrench },
    { to: '/finance', label: t('nav.finance'), icon: Wallet },
    { to: '/hr', label: t('nav.hr'), icon: UserSquare2 },
    { to: '/supply', label: t('nav.supply'), icon: Truck },
    { to: '/reports', label: t('nav.reports'), icon: BarChart3 },
    ...(isAdmin
      ? [{ to: '/users', label: t('nav.users', { defaultValue: 'Foydalanuvchilar' }), icon: ShieldCheck }]
      : []),
    { to: '/settings', label: t('nav.settings'), icon: Settings },
  ];

  return (
    <aside className="h-screen sticky top-0 bg-card border-r border-black/5 flex flex-col">
      <div className="flex items-center gap-3 px-4 h-16 border-b border-black/5">
        <div className="w-9 h-9 rounded-button bg-primary text-white flex items-center justify-center font-bold">N</div>
        {!collapsed && <div className="font-semibold text-sm">NurBunker ERP</div>}
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
