import { Bell, LogOut } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/auth';
import UserAvatar from '@/features/users/UserAvatar';
import LanguageSwitcher from '@/components/ui/LanguageSwitcher';

export default function TopBar() {
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);

  const onLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header className="sticky top-0 z-10 h-16 bg-card border-b border-black/5 flex items-center justify-between px-4 md:px-6">
      <div className="font-medium text-ink text-sm md:text-base truncate">NUR TECHNO GROUP</div>

      <div className="flex items-center gap-2">
        <LanguageSwitcher />

        <button className="p-2 rounded-button hover:bg-black/5 text-ink/70 relative" title="Bildirishnomalar">
          <Bell size={18} />
        </button>

        <div className="flex items-center gap-2 ml-2 pl-2 border-l border-black/5">
          {user ? (
            <UserAvatar user={user} size={32} />
          ) : (
            <div className="w-8 h-8 rounded-full bg-primary/40" />
          )}
          <div className="hidden md:block text-xs">
            <div className="font-medium text-ink">{user?.full_name}</div>
            <div className="text-ink-soft truncate max-w-[140px]">{user?.phone}</div>
          </div>
          <button onClick={onLogout} className="p-2 rounded-button hover:bg-black/5 text-ink/60" title="Chiqish">
            <LogOut size={18} />
          </button>
        </div>
      </div>
    </header>
  );
}
