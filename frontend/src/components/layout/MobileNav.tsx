import { useEffect, useRef } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { cn } from '@/lib/cn';
import { useNavItems } from './navItems';

/**
 * Mobil pastki navigatsiya — gorizontal suriladigan (carousel).
 * Barcha bo'limlar bitta qatorda; foydalanuvchi chap-o'ngga surib hammasiga
 * yetadi. Yon chetda keyingi menyuning yarmi ko'rinib turadi (surish mumkinligi
 * belgisi), va joriy sahifaning tugmasi avtomatik ko'rinadigan joyga suriladi.
 */
export default function MobileNav() {
  const navItems = useNavItems();
  // Quyi-menyuli bo'limlarni (Ta'minot → Ichki/Tashqi) alohida tugmalarga yoyamiz
  const items = navItems.flatMap((it) => (it.children?.length ? it.children : [it]));
  const location = useLocation();
  const scrollRef = useRef<HTMLDivElement>(null);

  const isActive = (to: string, exact?: boolean) =>
    exact ? location.pathname === to
          : (location.pathname === to || location.pathname.startsWith(to + '/'));

  // Active tugmani ko'rinadigan markazga avtomatik sirg'antiramiz
  useEffect(() => {
    const el = scrollRef.current?.querySelector<HTMLElement>('[data-active]');
    el?.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' });
  }, [location.pathname]);

  return (
    <nav
      className="md:hidden fixed bottom-0 inset-x-0 z-20 bg-card border-t border-black/5"
      // iPhone home-indikatori uchun pastdan xavfsiz bo'shliq qoldiramiz
      style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}
    >
      <div
        ref={scrollRef}
        className="overflow-x-auto overscroll-x-contain touch-pan-x
                   [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden"
        style={{ scrollSnapType: 'x proximity', WebkitOverflowScrolling: 'touch' }}
      >
        {/* w-max + mx-auto: kam menyu bo'lsa markazga, ko'p bo'lsa boshidan suriladi */}
        <div className="flex items-stretch gap-1 h-16 px-2 w-max mx-auto">
          {items.map(({ to, label, icon: Icon, exact }) => (
            <NavLink
              key={to}
              to={to}
              end={exact}
              data-active={isActive(to, exact) || undefined}
              style={{ scrollSnapAlign: 'center', WebkitTapHighlightColor: 'transparent' }}
              className={({ isActive: active }) =>
                cn(
                  'flex-shrink-0 w-[68px] flex flex-col items-center justify-center gap-0.5',
                  'text-[10px] font-medium px-1 my-1.5 rounded-button transition-colors',
                  'touch-manipulation select-none',
                  active ? 'text-primary bg-primary/10' : 'text-ink/60 active:bg-black/5',
                )
              }
            >
              <Icon size={20} />
              <span className="truncate max-w-full leading-tight">{label}</span>
            </NavLink>
          ))}
        </div>
      </div>
    </nav>
  );
}
