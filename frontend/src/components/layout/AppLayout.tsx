import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import TopBar from './TopBar';
import MobileNav from './MobileNav';
import { useUIStore } from '@/stores/ui';
import { cn } from '@/lib/cn';

export default function AppLayout() {
  const collapsed = useUIStore((s) => s.sidebarCollapsed);
  return (
    <div className="min-h-screen flex bg-bg">
      {/* Desktop sidebar */}
      <div className={cn('hidden md:block transition-all', collapsed ? 'w-16' : 'w-60')}>
        <Sidebar />
      </div>
      <div className="flex-1 flex flex-col min-w-0">
        <TopBar />
        <main className="flex-1 p-4 md:p-6 pb-24 md:pb-6">
          <Outlet />
        </main>
        <MobileNav />
      </div>
    </div>
  );
}
