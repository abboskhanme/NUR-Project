import { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { ChevronLeft, ChevronRight, ChevronDown, type LucideIcon } from 'lucide-react';

import { useUIStore } from '@/stores/ui';
import { cn } from '@/lib/cn';
import { useNavItems, type NavItem } from './navItems';

export default function Sidebar() {
  const collapsed = useUIStore((s) => s.sidebarCollapsed);
  const toggle = useUIStore((s) => s.toggleSidebar);
  const items = useNavItems();
  const { pathname } = useLocation();
  const [open, setOpen] = useState<Record<string, boolean>>({});

  const linkClass = ({ isActive }: { isActive: boolean }) =>
    cn(
      'flex items-center gap-3 px-4 py-2.5 mx-2 my-0.5 rounded-button text-sm font-medium transition-colors',
      isActive ? 'bg-primary/10 text-primary' : 'text-ink/70 hover:bg-black/5',
    );

  const renderLink = (it: NavItem) => {
    const Icon: LucideIcon = it.icon;
    return (
      <NavLink key={it.to} to={it.to} end={it.exact} className={linkClass}>
        <Icon size={18} />
        {!collapsed && <span>{it.label}</span>}
      </NavLink>
    );
  };

  return (
    <aside className="h-screen sticky top-0 bg-card border-r border-black/5 flex flex-col">
      <div className="flex items-center gap-3 px-4 h-16 border-b border-black/5">
        <div className="w-9 h-9 rounded-button bg-primary text-white flex items-center justify-center font-bold">N</div>
        {!collapsed && <div className="font-semibold text-sm">NUR Project</div>}
      </div>

      <nav className="flex-1 overflow-y-auto py-2">
        {items.map((item) => {
          const kids = item.children ?? [];
          if (!kids.length) return renderLink(item);

          // Quyi-menyu: yig'iladigan guruh
          const groupActive = kids.some(
            (c) => pathname === c.to || pathname.startsWith(c.to + '/'),
          );
          // Sidebar yig'ilgan bo'lsa — bolalar to'g'ridan-to'g'ri ikonka sifatida
          if (collapsed) return kids.map(renderLink);

          const Icon = item.icon;
          const expanded = open[item.to] ?? groupActive;
          return (
            <div key={item.to}>
              <button
                onClick={() => setOpen((s) => ({ ...s, [item.to]: !expanded }))}
                className={cn(
                  'w-full flex items-center gap-3 px-4 py-2.5 mx-2 my-0.5 rounded-button text-sm font-medium transition-colors',
                  groupActive ? 'text-primary' : 'text-ink/70 hover:bg-black/5',
                )}
              >
                <Icon size={18} />
                <span className="flex-1 text-left">{item.label}</span>
                <ChevronDown size={15} className={cn('transition-transform', expanded && 'rotate-180')} />
              </button>
              {expanded && (
                <div className="ml-5 border-l border-black/5">
                  {kids.map(renderLink)}
                </div>
              )}
            </div>
          );
        })}
      </nav>

      <button onClick={toggle}
              className="m-3 p-2 rounded-button hover:bg-black/5 text-ink/60 self-end">
        {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
      </button>
    </aside>
  );
}
