import { NavLink } from 'react-router-dom';
import { ChevronLeft, ChevronRight } from 'lucide-react';

import { useUIStore } from '@/stores/ui';
import { cn } from '@/lib/cn';
import { useNavItems } from './navItems';

export default function Sidebar() {
  const collapsed = useUIStore((s) => s.sidebarCollapsed);
  const toggle = useUIStore((s) => s.toggleSidebar);
  const items = useNavItems();

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
