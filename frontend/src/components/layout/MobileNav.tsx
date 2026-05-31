import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { ShoppingCart, ListOrdered, Wrench, Wallet, UserSquare2 } from 'lucide-react';
import { cn } from '@/lib/cn';

export default function MobileNav() {
  const { t } = useTranslation();
  const items = [
    { to: '/orders', label: t('nav.sales'), icon: ShoppingCart },
    { to: '/queue', label: t('nav.queue'), icon: ListOrdered },
    { to: '/service', label: t('nav.service'), icon: Wrench },
    { to: '/finance', label: t('nav.finance'), icon: Wallet },
    { to: '/hr', label: t('nav.hr'), icon: UserSquare2 },
  ];

  return (
    <nav className="md:hidden fixed bottom-0 inset-x-0 z-20 bg-card border-t border-black/5 h-16 flex items-center justify-around">
      {items.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={to}
          to={to}
          className={({ isActive }) =>
            cn(
              'flex flex-col items-center justify-center gap-0.5 text-[10px] font-medium px-3 py-1 transition-colors',
              isActive ? 'text-primary' : 'text-ink/60',
            )
          }
        >
          <Icon size={20} />
          <span>{label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
